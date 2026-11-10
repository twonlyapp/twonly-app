import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:twonly/core/bridge/memory_importer.dart';
import 'package:twonly/src/services/memories/memory_importer.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_card.element.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings → Backup → Memories: how to import, the importer pages that are
/// still connected, past imports on this device and imported items that could
/// not be read.
class MemoryImportersSection extends StatefulWidget {
  const MemoryImportersSection({super.key});

  @override
  State<MemoryImportersSection> createState() => _MemoryImportersSectionState();
}

class _MemoryImportersSectionState extends State<MemoryImportersSection> {
  List<ImporterInfo> _importers = const [];
  List<PastImportInfo> _past = const [];
  List<UnreadableImportInfo> _unreadable = const [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final results = await Future.wait<List<Object>>([
      RustMemoryImporter.list().catchError((Object e) {
        Log.warn('listing importers failed: $e');
        return <ImporterInfo>[];
      }),
      RustMemoryImporter.pastImports().catchError((Object e) {
        Log.warn('listing past imports failed: $e');
        return <PastImportInfo>[];
      }),
      RustMemoryImporter.unreadable().catchError((Object e) {
        Log.warn('listing unreadable imports failed: $e');
        return <UnreadableImportInfo>[];
      }),
    ]);
    if (!mounted) return;
    setState(() {
      // The server also lists importers that ended (revoked, expired or
      // idle) until it purges them. They can no longer upload and their
      // memories show up under the past imports, so only the active ones
      // count as connected; otherwise "Remove" would seem to do nothing.
      _importers = results[0]
          .cast<ImporterInfo>()
          .where((importer) => importer.active)
          .toList();
      _past = results[1].cast<PastImportInfo>();
      _unreadable = results[2].cast<UnreadableImportInfo>();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      Log.warn('importer action failed: $e');
      if (mounted) {
        showSnackbar(context, context.lang.memoryImporterActionFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _load();
    }
  }

  String _date(int seconds) => DateFormat.yMMMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(DateTime.fromMillisecondsSinceEpoch(seconds * 1000));

  Future<void> _remove(ImporterInfo importer) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                context.lang.memoryImporterRemoveTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(context.lang.memoryImporterRemoveBody),
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.linkSlash, size: 20),
              title: Text(context.lang.memoryImporterRemoveKeep),
              onTap: () => Navigator.pop(context, 'keep'),
            ),
            ListTile(
              leading: FaIcon(
                FontAwesomeIcons.trashCan,
                size: 20,
                color: context.color.error,
              ),
              title: Text(
                context.lang.memoryImporterRemoveDelete,
                style: TextStyle(color: context.color.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              title: Text(context.lang.cancel),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (choice == 'keep') {
      await _run(() async {
        await RustMemoryImporter.revoke(importerId: importer.id);
        // Picks up whatever it uploaded last, so it shows under the past
        // imports.
        unawaited(MemoryImporterService.reconcile(force: true));
      });
    } else if (choice == 'delete') {
      await _run(
        () => RustMemoryImporter.deleteImport(importerId: importer.id),
      );
    }
  }

  Future<void> _deleteImport(PastImportInfo past) async {
    final ok = await showAlertDialog(
      context,
      context.lang.memoryImporterDeleteImport,
      context.lang.memoryImporterDeleteImportConfirm(past.count),
      customOk: context.lang.memoryImporterDelete,
    );
    if (ok) {
      await _run(
        () => RustMemoryImporter.deleteImport(importerId: past.importerId),
      );
    }
  }

  Future<void> _deleteUnreadable() async {
    final ok = await showAlertDialog(
      context,
      context.lang.memoryImporterUnreadable(_unreadable.length),
      context.lang.memoryImporterUnreadableBody,
      customOk: context.lang.memoryImporterDelete,
    );
    if (!ok) return;
    await _run(() async {
      for (final item in _unreadable) {
        await RustMemoryImporter.deleteUnreadable(mediaId: item.mediaId);
      }
    });
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: context.color.onSurfaceVariant,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.lang.memoryImporterTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          context.lang.memoryImporterHowTo(
            MemoryImporterService.importerOrigin,
          ),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.color.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: MyButton(
            variant: MyButtonVariant.primaryMiddle,
            onPressed: () => launchUrl(
              Uri.https(MemoryImporterService.importerOrigin),
              mode: LaunchMode.externalApplication,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.open_in_new, size: 18),
                const SizedBox(width: 8),
                Text(
                  context.lang.memoryImporterOpenPage(
                    MemoryImporterService.importerOrigin,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_importers.isNotEmpty) ...[
          _label(context.lang.memoryImporterSectionConnected),
          for (final importer in _importers)
            MyCard(
              icon: FontAwesomeIcons.laptop,
              title: importer.uploadedCount == 0
                  ? context.lang.memoryImporterNothingYet
                  : context.lang.memoryImporterUploaded(
                      importer.uploadedCount,
                      formatBytes(importer.uploadedBytes),
                    ),
              subtitle: context.lang.memoryImporterActiveUntil(
                _date(
                  importer.idleExpiresAt < importer.expiresAt
                      ? importer.idleExpiresAt
                      : importer.expiresAt,
                ),
              ),
              trailing: TextButton(
                onPressed: _busy ? null : () => _remove(importer),
                child: Text(context.lang.memoryImporterRemove),
              ),
            ),
        ],
        if (_past.isNotEmpty) ...[
          _label(context.lang.memoryImporterSectionPast),
          for (final past in _past)
            MyCard(
              icon: FontAwesomeIcons.images,
              title: past.sourceName,
              subtitle: context.lang.memoryImporterPastSummary(
                past.count,
                past.firstCreatedAt == past.lastCreatedAt
                    ? _date(past.firstCreatedAt)
                    : '${_date(past.firstCreatedAt)} – ${_date(past.lastCreatedAt)}',
              ),
              trailing: IconButton(
                tooltip: context.lang.memoryImporterDeleteImport,
                icon: FaIcon(
                  FontAwesomeIcons.trashCan,
                  size: 18,
                  color: context.color.onSurfaceVariant,
                ),
                onPressed: _busy ? null : () => _deleteImport(past),
              ),
            ),
        ],
        if (_unreadable.isNotEmpty) ...[
          const SizedBox(height: 16),
          MyCard(
            icon: FontAwesomeIcons.triangleExclamation,
            accentColor: context.color.error,
            title: context.lang.memoryImporterUnreadable(_unreadable.length),
            subtitle: context.lang.memoryImporterUnreadableBody,
            trailing: TextButton(
              onPressed: _busy ? null : _deleteUnreadable,
              style: TextButton.styleFrom(
                foregroundColor: context.color.error,
              ),
              child: Text(context.lang.memoryImporterDelete),
            ),
          ),
        ],
      ],
    );
  }
}
