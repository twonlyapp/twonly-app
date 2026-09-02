import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/home_widget.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_card.element.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/views/settings/widgets/widget_detail.view.dart';
import 'package:twonly/src/visual/views/settings/widgets/widget_setup_guide.comp.dart';

/// Lists the widgets on the home screen and who may send to each of them.
///
/// Neither platform lets an app place or reconfigure a widget on the user's
/// behalf, so this screen explains the placement and then reflects the result.
/// What it *can* offer directly is the part that lives in the app: which
/// contacts are in each group.
class WidgetsSettingsView extends StatefulWidget {
  const WidgetsSettingsView({super.key});

  @override
  State<WidgetsSettingsView> createState() => _WidgetsSettingsViewState();
}

class _WidgetsSettingsViewState extends State<WidgetsSettingsView> {
  List<PlacedWidget>? _widgets;
  String? _queryError;
  Map<int, ContactGroup> _groups = const {};
  Map<String, int> _imageCounts = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    // The manifest and the placement file are rewritten by Rust and by the
    // native widgets, so this screen always re-reads rather than caching.
    HomeWidgetService.invalidate();
    await HomeWidgetService.syncPermissions();
    final result = await HomeWidgetService.placedWidgetsResult();
    final widgets = result.widgets;
    final groups = await twonlyDB.contactGroupsDao
        .watchAllContactGroups()
        .first;
    final counts = <String, int>{};
    for (final widget in widgets) {
      counts[widget.id] = (await HomeWidgetService.imagesFor(widget)).length;
    }
    if (!mounted) return;
    setState(() {
      _widgets = widgets;
      _queryError = result.error;
      _groups = {for (final group in groups) group.id: group};
      _imageCounts = counts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final widgets = _widgets;
    return Scaffold(
      appBar: AppBar(title: Text(context.lang.widgetsTitle)),
      body: widgets == null
          ? const Center(child: ThreeRotatingDots(size: 40))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Without this the list would quietly present a stale file as
                  // the state of the home screen.
                  if (_queryError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      child: Text(
                        context.lang.widgetsQueryFailed,
                        style: TextStyle(color: context.color.error),
                      ),
                    ),
                  if (widgets.isEmpty)
                    const WidgetSetupGuide(showIntro: true)
                  else ...[
                    for (final widget in widgets) _tile(widget),
                    const Divider(height: 32),
                    const WidgetSetupGuide(showIntro: false),
                  ],
                ],
              ),
            ),
    );
  }

  /// Several widgets can share one contact group, so the size is what tells
  /// two cards apart.
  String _size(PlacedWidget widget) => switch (widget.family) {
    'systemSmall' => context.lang.widgetsSizeSmall,
    'systemMedium' => context.lang.widgetsSizeMedium,
    'systemLarge' => context.lang.widgetsSizeLarge,
    _ => context.lang.widgetsSizeUnknown,
  };

  Widget _tile(PlacedWidget widget) {
    final selected = [
      for (final id in widget.contactGroupIds) ?_groups[id],
    ];
    final count = _imageCounts[widget.id] ?? 0;
    final unconfigured = selected.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: MyCard(
        icon: FontAwesomeIcons.image,
        accentColor: unconfigured ? context.color.error : null,
        titleColor: unconfigured ? context.color.error : null,
        title: unconfigured
            ? context.lang.widgetsNoGroups
            : selected
                  .map(
                    (g) => '${g.emoji == null ? '' : '${g.emoji} '}${g.name}',
                  )
                  .join(', '),
        subtitle: unconfigured
            ? context.lang.widgetsNoGroupsHint
            : '${_size(widget)} · '
                  '${count == 0 ? context.lang.widgetsNoImages : context.lang.widgetsCurrentImages}',
        trailing: count == 0
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Not a warning, just a count: the badge's default error red
                  // reads as something being wrong.
                  Badge(
                    backgroundColor: context.color.primary,
                    textColor: context.color.onPrimary,
                    label: Text('$count'),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.color.onSurfaceVariant,
                  ),
                ],
              ),
        onTap: () async {
          await context.navPush(WidgetDetailView(widget: widget));
          await _load();
        },
      ),
    );
  }
}

/// Platform wording for how the contact groups of a placed widget are changed.
String changeGroupsHint(BuildContext context) => Platform.isIOS
    ? context.lang.widgetsChangeGroupsIos
    : context.lang.widgetsChangeGroupsAndroid;
