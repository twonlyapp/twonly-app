import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/core/bridge/webxdc.dart' as rust_webxdc;
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/webxdc/webxdc.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/pro_badge.element.dart';

/// The in-app store.
///
/// Only twonly publishes apps, so there is nothing here for a user to judge:
/// the list is the complete set of code that can run in a chat. Picking one
/// places it into the chat; the bundle is downloaded when somebody presses
/// Start, not now.
class WebxdcStoreView extends StatefulWidget {
  const WebxdcStoreView({required this.group, super.key});

  final Group group;

  @override
  State<WebxdcStoreView> createState() => _WebxdcStoreViewState();
}

class _WebxdcStoreViewState extends State<WebxdcStoreView> {
  List<rust_webxdc.WebxdcStoreApp>? _apps;
  bool _offline = false;
  String? _placing;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Loaded from here rather than `initState`: the descriptions are fetched in
    // the reader's language, and the resolved locale is only available once the
    // sheet has its dependencies.
    if (_loading) return;
    _loading = true;
    unawaited(_load(Localizations.localeOf(context).toLanguageTag()));
  }

  Future<void> _load(String language) async {
    // The cached listing is shown first so the sheet is never empty while the
    // refresh is in flight.
    final languages = [language];
    final cached = await WebxdcService.catalog(widget.group.groupId, languages);
    if (mounted) setState(() => _apps = cached);

    final refreshed = await WebxdcService.refreshCatalog();
    final apps = refreshed
        ? await WebxdcService.catalog(widget.group.groupId, languages)
        : cached;
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _offline = !refreshed && cached.isEmpty;
    });
  }

  Future<void> _place(rust_webxdc.WebxdcStoreApp app) async {
    if (app.proOnly && !isPayingUser(context.read<PurchasesProvider>().plan)) {
      await context.push(Routes.settingsSubscription);
      return;
    }
    setState(() => _placing = app.appId);
    final instanceId = await WebxdcService.createInstance(
      widget.group.groupId,
      app.appId,
      app.version,
    );
    if (!mounted) return;
    if (instanceId == null) {
      setState(() => _placing = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.lang.webxdcStoreFailed)),
      );
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      // Never the whole screen: the chat has to stay visible behind the sheet,
      // because what picking an app does is put it into that chat.
      maxChildSize: 0.7,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          color: context.color.surface,
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: Colors.grey,
              ),
              height: 3,
              width: 60,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    context.lang.webxdcStoreTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _body(controller)),
          ],
        ),
      ),
    );
  }

  Widget _body(ScrollController controller) {
    final apps = _apps;
    if (apps == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (apps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _offline
                ? context.lang.webxdcStoreOffline
                : context.lang.webxdcStoreEmpty,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final available = apps
        .where((app) => !app.oneTime || app.instanceId == null)
        .toList();
    final alreadyAdded = apps
        .where((app) => app.oneTime && app.instanceId != null)
        .toList();

    return ListView(
      controller: controller,
      children: [
        ...available.map(_appTile),
        if (alreadyAdded.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              context.lang.webxdcStoreAlreadyAdded,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.color.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...alreadyAdded.map(
            (app) =>
                Opacity(opacity: 0.45, child: _appTile(app, disabled: true)),
          ),
        ],
      ],
    );
  }

  Widget _appTile(
    rust_webxdc.WebxdcStoreApp app, {
    bool disabled = false,
  }) {
    final icon = app.icon;
    final subtitle = userService.currentUser.isDeveloper
        ? ['v${app.version}', ?app.description].join(' · ')
        : app.description;
    return ListTile(
      leading: SizedBox(
        width: 40,
        height: 40,
        child: icon == null
            ? const FaIcon(FontAwesomeIcons.puzzlePiece)
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(icon, fit: BoxFit.cover),
              ),
      ),
      title: Text(app.name),
      subtitle: subtitle == null
          ? null
          : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: _placing == app.appId
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : app.proOnly
          ? const ProBadge()
          : null,
      onTap: !disabled && _placing == null ? () => _place(app) : null,
    );
  }
}
