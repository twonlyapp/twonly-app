import 'dart:async';
import 'dart:convert';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/webxdc.dart' as rust_webxdc;
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/services/webxdc/webxdc.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/shared/select_contacts.view.dart';
import 'package:url_launcher/url_launcher.dart';

/// The Flutter half of the webxdc runtime.
///
/// The webview itself is native on both platforms: one screen, one origin, one
/// bridge, and no navigation of its own. Everything it asks for comes back
/// through this channel, which is the only path from a running app into the
/// rest of twonly.
///
/// Nothing arriving from the page is trusted. The instance an app may act on is
/// the one this side opened, never the one a message claims; every limit is
/// applied in Rust; and the only values handed to the page are the ones
/// prepared here.
class WebxdcHost {
  static const MethodChannel _channel = MethodChannel('eu.twonly/webxdc');

  /// The instance currently on screen. A page may only ever act on this one:
  /// the id in a bridge message is checked against it rather than obeyed.
  static String? _openInstanceId;
  static StreamSubscription<void>? _updateSubscription;
  static int _deliveredSerial = 0;
  static VoidCallback? _closeView;

  /// Whether this device composites the webview with Hybrid Composition++.
  ///
  /// HCPP hands the webview to the system compositor through `SurfaceControl`
  /// rather than merging the raster and platform threads, which is what keeps a
  /// route transition smooth while an app is on screen -- the predictive back
  /// gesture above all, since it transforms the whole outgoing route on every
  /// frame of the drag. It needs the engine opt-in in the manifest and Vulkan
  /// on API 34 or newer, so the answer belongs to the device rather than to the
  /// app being opened and is asked once, here. Everything else falls back to
  /// the texture path, which composites the webview like any other layer.
  static bool hybridComposition = false;

  static void initialize() {
    _channel.setMethodCallHandler(_handleNativeCall);
    WebxdcWebviewStorage.clear = _clearOrigin;
    unawaited(_probeHybridComposition());
  }

  static Future<void> _probeHybridComposition() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      hybridComposition = await HybridAndroidViewController.checkIfSupported();
    } catch (error) {
      // An engine built without the opt-in does not answer this at all.
      hybridComposition = false;
    }
  }

  /// Stops the running app while its screen animates away, and starts it again
  /// if the screen turns out to be staying.
  ///
  /// An app keeps running for as long as it is loaded, and a game redraws every
  /// frame it is given: on the way out that work lands on exactly the frames the
  /// closing animation needs. This is the webview's own pause, so the page keeps
  /// its state and nothing is reloaded. Android only: WebKit offers no
  /// equivalent, and the transition there does not transform the platform view
  /// the way the predictive back gesture does.
  static Future<void> setPaused({required bool paused}) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    final instanceId = _openInstanceId;
    if (instanceId == null) return;
    try {
      await _channel.invokeMethod<void>('setPaused', {
        'instanceId': instanceId,
        'paused': paused,
      });
    } on PlatformException catch (error) {
      Log.warn('pausing the webxdc app failed: ${error.message}');
    }
  }

  /// Gets an app ready to run: makes sure the bundle is on disk and verified,
  /// and returns what the view needs to show it.
  ///
  /// Cached apps open without a network update check. Returns a failure when the bundle
  /// cannot be had at all -- a first start with no network, or an app that was
  /// taken out of the store before this device ever downloaded it.
  /// `languages` is what the reader prefers, most preferred first: the title
  /// bar names the app the way the chat card does.
  static Future<WebxdcLaunch> prepare(
    String instanceId,
    List<String> languages,
  ) async {
    final instance = await WebxdcService.instance(instanceId);
    if (instance == null) {
      return const WebxdcLaunch.failed('unavailable');
    }
    // A first launch may need a download. Existing bundles are read locally.
    final bundlePath = await WebxdcService.prepareBundle(instanceId);
    if (bundlePath == null) {
      return const WebxdcLaunch.failed('unavailable');
    }

    // Read after the bundle: an update moves the instance to another version,
    // and the name shown is the one belonging to the version that will run.
    final started = await WebxdcService.instance(instanceId) ?? instance;
    final app = await WebxdcService.appNamed(started.appId, started.version);
    return WebxdcLaunch(
      instanceId: instanceId,
      // The webview host. Unique per instance, so the browser's own origin
      // model keeps this app's stored data to itself.
      origin: instance.originToken,
      // The store's name for the app, never one the running app chose.
      title: app == null
          ? instance.appId
          : WebxdcService.localizedName(app, languages),
    );
  }

  /// Binds the runtime to the screen showing an app.
  ///
  /// Until this is called nothing may act on the instance, and once `detach`
  /// runs nothing may again: a bridge message naming any other instance is
  /// refused rather than obeyed.
  static void attach(String instanceId, {required VoidCallback close}) {
    _openInstanceId = instanceId;
    _closeView = close;
    _deliveredSerial = 0;
    unawaited(_updateSubscription?.cancel());
    _updateSubscription = WebxdcService.watchUpdates().listen(
      (_) => unawaited(_pushPendingUpdates()),
    );
  }

  static void detach(String instanceId) {
    if (_openInstanceId != instanceId) return;
    unawaited(_updateSubscription?.cancel());
    _updateSubscription = null;
    _openInstanceId = null;
    _closeView = null;
    // Closing never waits for the server; downloaded code is used next time.
    unawaited(WebxdcService.cacheUpdate(instanceId));
  }

  static Future<void> _clearOrigin(String origin) async {
    try {
      await _channel.invokeMethod<void>('clearOrigin', {'origin': origin});
    } on PlatformException catch (error) {
      Log.warn('clearing webxdc origin failed: ${error.message}');
    }
  }

  static Future<Object?> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'serve':
        return _serve(call.arguments as Map<Object?, Object?>);
      case 'bridge':
        return _bridge(call.arguments as Map<Object?, Object?>);
      case 'openLink':
        // Every link out of an app comes through here. The page is never
        // allowed to follow one itself.
        await _confirmExternalLink(call.arguments as Map<Object?, Object?>);
        return null;
      default:
        throw MissingPluginException('unknown webxdc call ${call.method}');
    }
  }

  /// Answers one request the page made. The bundle is read in Rust, straight
  /// out of the zip, and comes back with the headers that keep the page boxed
  /// in.
  static Future<Map<String, Object?>> _serve(
    Map<Object?, Object?> arguments,
  ) async {
    final instanceId = _openInstanceId;
    if (instanceId == null || instanceId != arguments['instanceId']) {
      // A request from an origin that is not the open instance's. There is no
      // legitimate way for one to arrive.
      return {'status': 403, 'mime': 'text/plain', 'body': Uint8List(0)};
    }
    final response = await rust_webxdc.serve(
      instanceId: instanceId,
      requestPath: arguments['path']! as String,
    );
    return {
      'status': response.status,
      'mime': response.mime,
      'headerNames': response.headerNames,
      'headerValues': response.headerValues,
      'body': response.body,
    };
  }

  /// One call from `webxdc.js`.
  ///
  /// The reply shape mirrors what the shim expects: `result` on success,
  /// `error` on refusal. A refusal is a rejected promise inside the app, never
  /// a crash out here.
  static Future<String> _bridge(Map<Object?, Object?> arguments) async {
    final instanceId = _openInstanceId;
    final raw = arguments['message']! as String;

    Map<String, dynamic> message;
    try {
      message = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return jsonEncode({'error': 'malformed call'});
    }
    final id = message['id'];
    if (instanceId == null || instanceId != arguments['instanceId']) {
      return jsonEncode({'id': id, 'error': 'this app is not open'});
    }

    final params = (message['params'] as Map<String, dynamic>?) ?? {};
    try {
      switch (message['method']) {
        case 'getMembers':
          final members = await rust_webxdc.members(instanceId: instanceId);
          return jsonEncode({'id': id, 'result': jsonDecode(members)});

        case 'sendUpdate':
          // `payload` is re-encoded rather than passed through, so what is
          // stored and sent is JSON this side produced.
          await WebxdcService.sendUpdate(
            instanceId: instanceId,
            payload: jsonEncode(params['payload']),
            info: params['info'] as String?,
            href: params['href'] as String?,
            summary: params['summary'] as String?,
            document: params['document'] as String?,
            notify: params['notify'] == null
                ? null
                : jsonEncode(params['notify']),
          );
          return jsonEncode({'id': id, 'result': null});

        case 'catchUp':
          final serial = (params['serial'] as num?)?.toInt() ?? 0;
          _deliveredSerial = serial;
          await _pushPendingUpdates();
          return jsonEncode({'id': id, 'result': null});

        case 'sendToChat':
          // Validated before the promise is settled, so an app learns that a
          // file twonly cannot send was refused and can fall back. Everything
          // after that -- the picker, the editor, the sending -- is the user's,
          // and the spec asks for none of it to be reported back.
          final handover = _validateHandover(params);
          if (handover.error != null) {
            return jsonEncode({'id': id, 'error': handover.error});
          }
          unawaited(_sendToChat(instanceId, handover));
          return jsonEncode({'id': id, 'result': null});

        case 'importFiles':
          // Answered by the platform, which owns the picker and the screen it
          // has to appear over. Reaching this means the page found a bridge
          // that does not implement it.
          return jsonEncode({'id': id, 'error': 'not available in twonly'});

        default:
          return jsonEncode({'id': id, 'error': 'unknown method'});
      }
    } catch (error) {
      // Rust refuses an update that is too large, too frequent, or belongs to
      // an instance that has gone away. The app sees a rejected promise.
      return jsonEncode({'id': id, 'error': '$error'});
    }
  }

  /// Text an app may hand to a chat. The user still sees it before it is sent,
  /// but an app must not be able to fill a message with megabytes of anything.
  static const int _maxChatTextChars = 4096;

  /// Shows the whole URL and says plainly that it leaves twonly, before
  /// anything opens. A page cannot reach the browser any other way.
  static Future<void> _confirmExternalLink(
    Map<Object?, Object?> arguments,
  ) async {
    final raw = arguments['url'] as String? ?? '';
    final url = Uri.tryParse(raw);
    if (url == null || raw.isEmpty) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.lang.webxdcExternalLinkTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.lang.webxdcExternalLinkBody),
            const SizedBox(height: 12),
            SelectableText(raw, style: const TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.lang.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.lang.open),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// What an app asked to hand to a chat, once it has been checked.
  ///
  /// `error` set means the call is refused and the page is told so; the app can
  /// then fall back to something twonly can carry.
  static _Handover _validateHandover(Map<String, dynamic> params) {
    // Files are refused outright. twonly has no message type for one, and no
    // app in the store sends them, so accepting one could only end in it being
    // dropped later without the app ever learning why.
    if (params['file'] != null) {
      return const _Handover(error: 'twonly can only send text');
    }
    final text = _plainText(params['text'] as String?);
    if (text == null) {
      return const _Handover(error: 'nothing to send');
    }
    return _Handover(text: text);
  }

  /// Hands what an app produced back to twonly, where the user picks the chat.
  ///
  /// Nothing is sent from here. The user chooses who receives it and may
  /// abandon the whole thing -- neither of which is reported back, which is
  /// what the spec asks for.
  static Future<void> _sendToChat(String instanceId, _Handover handover) async {
    try {
      await _handOverToChat(instanceId, handover);
    } catch (error) {
      // The page has already been told the call was accepted, so a failure
      // here can only be logged, not reported back to the app.
      Log.error('handing webxdc text to a chat failed: $error');
    }
  }

  static Future<void> _handOverToChat(
    String instanceId,
    _Handover handover,
  ) async {
    final instance = await WebxdcService.instance(instanceId);
    if (instance == null) return;

    // The app's screen goes first: the picker belongs to twonly, and leaving
    // the app behind it would blur exactly the boundary this hands over.
    _closeView?.call();

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;

    // Recorded alongside the message so both devices can say which app the text
    // came from. The instance id names the app card, which may well be in a
    // different chat than the one the user is about to pick, so the app id and
    // version travel too.
    final origin = AdditionalMessageData(
      type: AdditionalMessageData_Type.WEBXDC_SENT,
      webxdcOrigin: WebxdcOrigin(
        instanceId: instanceId,
        appId: instance.appId,
        version: Int64(instance.version),
      ),
    ).writeToBuffer();

    await _shareText(context, handover.text!, origin);
  }

  static Future<void> _shareText(
    BuildContext context,
    String text,
    Uint8List origin,
  ) async {
    final selected =
        await context.navPush(
              SelectContactsView(
                text: SelectedContactView(
                  title: context.lang.shareContactsTitle,
                  submitButton: (_, _) => context.lang.shareContactsSubmit,
                  submitIcon: FontAwesomeIcons.shareNodes,
                ),
              ),
            )
            as List<int>?;
    if (selected == null || selected.isEmpty) return;

    for (final contactId in selected) {
      final group = await twonlyDB.groupsDao.getDirectChat(contactId);
      if (group == null) continue;
      await RustApi.insertAndSendText(
        groupId: group.groupId,
        text: text,
        additionalMessageData: origin,
      );
    }
  }

  /// Bounds and flattens text an app produced. Direction overrides and control
  /// characters are stripped for the same reason they are in an update: this
  /// ends up in a chat, next to real messages.
  static final RegExp _strippedFromText = RegExp(
    r'[\p{C}\u200e\u200f\u202a-\u202e\u2066-\u2069]',
    unicode: true,
  );

  static String? _plainText(String? value) {
    if (value == null) return null;
    final cleaned = value
        .replaceAll(_strippedFromText, '')
        .characters
        .take(_maxChatTextChars)
        .join()
        .trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Hands the page everything it has not seen yet, in serial order.
  static Future<void> _pushPendingUpdates() async {
    final instanceId = _openInstanceId;
    if (instanceId == null) return;

    final pending = await WebxdcService.updatesAfter(
      instanceId,
      _deliveredSerial,
    );
    if (pending.isEmpty) return;

    final maxSerial = pending.last.serial;
    final updates = pending
        .map(
          (update) => {
            'payload': jsonDecode(update.payload),
            'serial': update.serial,
            'max_serial': maxSerial,
            if (update.info != null) 'info': update.info,
            if (update.href != null) 'href': update.href,
          },
        )
        .toList();

    try {
      await _channel.invokeMethod<void>('deliver', {
        'instanceId': instanceId,
        'message': jsonEncode({
          'method': 'update',
          'params': {'updates': updates},
        }),
      });
      _deliveredSerial = maxSerial;
    } on PlatformException catch (error) {
      Log.warn('delivering webxdc updates failed: ${error.message}');
    }
  }
}

/// One `sendToChat` call, after checking.
class _Handover {
  const _Handover({this.text, this.error});

  final String? text;
  final String? error;
}

/// A prepared app, or the reason it cannot run.
class WebxdcLaunch {
  const WebxdcLaunch({
    required this.instanceId,
    required this.origin,
    required this.title,
  }) : failure = null;

  const WebxdcLaunch.failed(this.failure)
    : instanceId = '',
      origin = '',
      title = '';

  final String instanceId;
  final String origin;
  final String title;

  /// `'unavailable'`; null when the app is ready to run.
  final String? failure;
}
