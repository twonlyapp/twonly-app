import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/services/webxdc/webxdc_host.dart';

/// A running webxdc app, inside twonly.
///
/// The app is a native webview embedded in an ordinary route, so it keeps the
/// app bar, the back gesture and the theme around it: from the user's side it
/// is a screen in twonly rather than something that took the phone over.
class WebxdcAppView extends StatefulWidget {
  const WebxdcAppView({required this.launch, super.key});

  final WebxdcLaunch launch;

  @override
  State<WebxdcAppView> createState() => _WebxdcAppViewState();
}

class _WebxdcAppViewState extends State<WebxdcAppView> {
  Animation<double>? _routeAnimation;

  @override
  void initState() {
    super.initState();
    // From here until dispose, this is the one instance a page may act on.
    WebxdcHost.attach(
      widget.launch.instanceId,
      close: () {
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (identical(animation, _routeAnimation)) return;
    _routeAnimation?.removeStatusListener(_handleRouteAnimation);
    _routeAnimation = animation;
    animation?.addStatusListener(_handleRouteAnimation);
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteAnimation);
    WebxdcHost.detach(widget.launch.instanceId);
    super.dispose();
  }

  /// Pauses the app for as long as this screen is animating away.
  ///
  /// Every way out reverses the route's animation -- the app bar's back button,
  /// the system back gesture and `window.close` from the page itself -- so this
  /// is the one place that sees all of them, and it sees them before the first
  /// animated frame is built. `dispose` is too late: it only runs once the
  /// animation is over.
  void _handleRouteAnimation(AnimationStatus status) {
    if (status == AnimationStatus.reverse) {
      unawaited(WebxdcHost.setPaused(paused: true));
    } else if (status == AnimationStatus.forward) {
      // Opening, or a pop that was called off part way through.
      unawaited(WebxdcHost.setPaused(paused: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.launch.title)),
      body: SafeArea(
        child: _WebxdcSurface(
          instanceId: widget.launch.instanceId,
          origin: widget.launch.origin,
        ),
      ),
    );
  }
}

/// The embedded webview.
///
/// Both platforms hand back a native view rather than a screen of their own, so
/// what the app draws is composited into this route like any other widget.
class _WebxdcSurface extends StatelessWidget {
  const _WebxdcSurface({required this.instanceId, required this.origin});

  static const String _viewType = 'eu.twonly/webxdc_webview';

  final String instanceId;
  final String origin;

  @override
  Widget build(BuildContext context) {
    final parameters = <String, dynamic>{
      'instanceId': instanceId,
      'origin': origin,
    };

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: _viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: parameters,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return PlatformViewLink(
      viewType: _viewType,
      surfaceFactory: (context, controller) => AndroidViewSurface(
        controller: controller as AndroidViewController,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
      ),
      onCreatePlatformView: (params) {
        // Hybrid Composition++ wherever the device runs it: the webview is
        // handed to the system compositor, so an animation over it no longer
        // drags the platform thread along. Everywhere else the texture path,
        // which composites the webview like any other layer and drops to plain
        // hybrid composition on its own when a page needs a real surface.
        // Plain hybrid composition is not asked for here: it merges the raster
        // and platform threads for as long as the app is on screen, and every
        // frame of the closing animation then pays for it.
        final controller = WebxdcHost.hybridComposition
            ? PlatformViewsService.initHybridAndroidView(
                id: params.id,
                viewType: _viewType,
                layoutDirection: TextDirection.ltr,
                creationParams: parameters,
                creationParamsCodec: const StandardMessageCodec(),
                onFocus: () => params.onFocusChanged(true),
              )
            : PlatformViewsService.initSurfaceAndroidView(
                id: params.id,
                viewType: _viewType,
                layoutDirection: TextDirection.ltr,
                creationParams: parameters,
                creationParamsCodec: const StandardMessageCodec(),
                onFocus: () => params.onFocusChanged(true),
              );
        return controller
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }
}
