import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/webxdc.dart' as rust_webxdc;
import 'package:twonly/src/services/webxdc/webxdc.service.dart';
import 'package:twonly/src/services/webxdc/webxdc_host.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';
import 'package:twonly/src/visual/views/webxdc/webxdc_app.view.dart';

/// One-time apps already attached to a chat, kept close to its profile.
class WebxdcChatAppsView extends StatefulWidget {
  const WebxdcChatAppsView({required this.groupId, super.key});

  final String groupId;

  @override
  State<WebxdcChatAppsView> createState() => _WebxdcChatAppsViewState();
}

class _WebxdcChatAppsViewState extends State<WebxdcChatAppsView> {
  List<rust_webxdc.WebxdcOneTimeInstance>? _apps;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading) return;
    _loading = true;
    _load();
  }

  Future<void> _load() async {
    final apps = await WebxdcService.oneTimeInstances(
      widget.groupId,
      readerLanguages(context),
    );
    if (mounted) {
      setState(() {
        _apps = apps;
        _loading = false;
      });
    }
  }

  Future<void> _open(rust_webxdc.WebxdcOneTimeInstance app) async {
    final messenger = ScaffoldMessenger.of(context);
    final unavailable = context.lang.webxdcUnavailable;
    final launch = await WebxdcHost.prepare(
      app.instanceId,
      readerLanguages(context),
    );
    if (launch.failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(unavailable)));
      return;
    }
    if (!mounted) return;
    await context.navPush(WebxdcAppView(launch: launch));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final apps = _apps;
    return Scaffold(
      appBar: AppBar(title: Text(context.lang.webxdcChatAppsTitle)),
      body: apps == null
          ? const Center(child: CircularProgressIndicator())
          : apps.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.lang.webxdcChatAppsEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                final subtitle = app.document ?? app.summary;
                return ListTile(
                  leading: SizedBox(
                    width: 44,
                    height: 44,
                    child: app.icon == null
                        ? const Center(
                            child: FaIcon(FontAwesomeIcons.puzzlePiece),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.memory(app.icon!, fit: BoxFit.cover),
                          ),
                  ),
                  title: Text(app.name),
                  subtitle: subtitle == null
                      ? null
                      : Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(app),
                );
              },
            ),
    );
  }
}
