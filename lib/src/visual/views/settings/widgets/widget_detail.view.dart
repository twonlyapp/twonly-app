import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/home_widget.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/views/contact/contact_group_settings.view.dart';
import 'package:twonly/src/visual/views/settings/widgets/widgets.view.dart';

/// One placed widget: who may send to it, and what it is showing right now.
class WidgetDetailView extends StatefulWidget {
  const WidgetDetailView({required this.widget, super.key});

  final PlacedWidget widget;

  @override
  State<WidgetDetailView> createState() => _WidgetDetailViewState();
}

class _WidgetDetailViewState extends State<WidgetDetailView> {
  List<WidgetImage>? _images;
  List<ContactGroup> _groups = const [];
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    // Every entry shows how much of its 24 hours is left, so the screen has to
    // keep counting down while it is open.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final images = await HomeWidgetService.imagesFor(widget.widget);
    final all = await twonlyDB.contactGroupsDao.watchAllContactGroups().first;
    final selected = widget.widget.contactGroupIds.toSet();
    if (!mounted) return;
    setState(() {
      _images = images;
      _groups = all.where((group) => selected.contains(group.id)).toList();
    });
  }

  Future<void> _delete(WidgetImage image) async {
    final confirmed = await showAlertDialog(
      context,
      context.lang.widgetsDeleteImage,
      context.lang.widgetsDeleteImageConfirm,
      customOk: context.lang.widgetsDeleteImage,
    );
    if (!confirmed) return;
    await HomeWidgetService.deleteImage(image.mediaId);
    await _load();
  }

  /// Coarse on purpose: the exact second an image disappears is noise, and the
  /// user only needs to know whether it is here for a while or nearly gone.
  String _remaining(WidgetImage image) {
    final remaining = image.remaining;
    if (remaining.inHours >= 1) {
      return context.lang.widgetsDurationHours(remaining.inHours);
    }
    return context.lang.widgetsDurationMinutes(
      remaining.inMinutes.clamp(1, 59),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
    return Scaffold(
      appBar: AppBar(title: Text(context.lang.widgetsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          if (_groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                context.lang.widgetsNoGroupsHint,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          else
            for (final group in _groups)
              ListTile(
                leading: group.emoji == null
                    ? const Icon(Icons.group_outlined)
                    : Text(
                        group.emoji!,
                        style: const TextStyle(fontSize: 20),
                      ),
                title: Text(group.name),
                subtitle: Text(context.lang.widgetsEditGroup),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await context.navPush(
                    ContactGroupSettingsView(contactGroup: group),
                  );
                  await _load();
                },
              ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(
              changeGroupsHint(context),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Divider(height: 32),
          _sectionTitle(context.lang.widgetsCurrentImages),
          if (images == null)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (images.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                context.lang.widgetsNoImagesHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            for (final image in images) _imageTile(image),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _imageTile(WidgetImage image) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          image.file,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          // The file is deleted the moment the user confirms, and Flutter keeps
          // decoded frames in a cache keyed by path, so a stale entry would
          // outlive the file it came from.
          cacheWidth: 168,
          errorBuilder: (_, _, _) => const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
      title: Text(context.lang.widgetsFrom(image.sender)),
      subtitle: Text(context.lang.widgetsExpiresIn(_remaining(image))),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: context.lang.widgetsDeleteImage,
        onPressed: () => _delete(image),
      ),
    );
  }
}
