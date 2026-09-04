import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/home_widget.service.dart';
import 'package:twonly/src/visual/components/snackbar.dart';

/// Shows the files the home widget reads, from the app side of the App Group.
///
/// The widget extension is a separate process that cannot be inspected from
/// here, and it renders a blank square for every failure. This screen answers
/// the half of the question the app can answer on its own: whether Rust wrote a
/// manifest at all, what is in it, and whether the images it points at exist.
/// Whether the extension can *reach* those same files is what the widget's own
/// `os_log` output ("eu.twonly.widget") reports.
class HomeWidgetDeveloperView extends StatefulWidget {
  const HomeWidgetDeveloperView({super.key});

  @override
  State<HomeWidgetDeveloperView> createState() =>
      _HomeWidgetDeveloperViewState();
}

class _HomeWidgetDeveloperViewState extends State<HomeWidgetDeveloperView> {
  String _report = 'Loading…';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Directory get _widgetDirectory =>
      Directory('${AppEnvironment.supportDir}/widget');

  Future<void> _load() async {
    final report = await _buildReport();
    if (!mounted) return;
    setState(() => _report = report);
  }

  Future<String> _buildReport() async {
    final lines = <String>[
      'platform: ${Platform.operatingSystem}',
      'support dir: ${AppEnvironment.supportDir}',
      '',
    ];

    final root = _widgetDirectory;
    lines
      ..addAll(await _reconcileSection())
      ..add('');
    if (!root.existsSync()) {
      lines
        ..add('${root.path} does not exist.')
        ..add('Rust has never written widget state on this install.');
      return lines.join('\n');
    }

    lines
      ..addAll(await _manifestSection(File('${root.path}/manifest.json')))
      ..add('')
      ..addAll(_nativeConfigSection(File('${root.path}/native-config.json')))
      ..add('')
      ..addAll(_imagesSection(Directory('${root.path}/images')));
    return lines.join('\n');
  }

  /// What WidgetKit itself says is on the home screen. This is the only
  /// authoritative answer: the placement file below is merely derived from it,
  /// so when the two disagree the fault is between these two sections.
  Future<List<String>> _reconcileSection() async {
    HomeWidgetService.invalidate();
    final report = await HomeWidgetService.reconcileReport();
    if (report == null) {
      return ['-- WidgetKit --', 'Not applicable on this platform.'];
    }
    if (report['error'] case final error?) {
      return [
        '-- WidgetKit --',
        'QUERY FAILED: $error',
        'The placement file was left untouched.',
      ];
    }
    final widgets = (report['widgets'] as List?) ?? const [];
    final summary =
        '${widgets.length} widget(s) installed, '
        '${report['matched']} confirmed placed';
    final lines = <String>[
      '-- WidgetKit --',
      'supported: ${report['supported']}',
      summary,
    ];
    for (final widget in widgets.cast<Map<Object?, Object?>>()) {
      lines.add(
        '  kind=${widget['kind']} family=${widget['family']} '
        'mine=${widget['mine']} live=${widget['live'] ?? '-'} '
        'groups=${widget['group_ids'] ?? '-'}'
        '${widget['configuration'] == null ? '' : ' UNREADABLE'}',
      );
    }
    if (widgets.isEmpty) {
      lines.add('  (none — the placement file should now be empty)');
    }
    return lines;
  }

  Future<List<String>> _manifestSection(File manifest) async {
    if (!manifest.existsSync()) {
      return [
        '-- manifest.json --',
        'MISSING. The widget shows "Open twonly once" in this state.',
      ];
    }

    final raw = await manifest.readAsString();
    final lines = <String>[
      '-- manifest.json --',
      '${raw.length} bytes, modified ${manifest.statSync().modified.toLocal()}',
    ];

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as Map<String, dynamic>;
    } catch (error) {
      return lines
        ..add('UNPARSEABLE: $error')
        ..add(raw);
    }

    final groups = (decoded['groups'] as List?) ?? [];
    final images = (decoded['images'] as List?) ?? [];
    lines.add(
      '${groups.length} contact groups, ${images.length} images '
      '(at most one per contact group)',
    );

    // The group IDs are the whole matching rule: the widget shows an image only
    // when its sender's groups intersect the groups the widget was configured
    // with, so a mismatch here is the difference between a picture and a blank.
    for (final group in groups.cast<Map<String, dynamic>>()) {
      lines.add('  group ${group['id']}: ${group['name']}');
    }
    for (final image in images.cast<Map<String, dynamic>>()) {
      final receivedAt = DateTime.fromMillisecondsSinceEpoch(
        ((image['received_at'] as num?)?.toInt() ?? 0) * 1000,
      );
      final exists = File('${image['path']}').existsSync();
      lines.add(
        '  ${image['media_id']} from ${image['sender']} '
        // One image per contact group, so these are the groups it is the
        // current image for — not the sender's full membership.
        'groups=${image['group_ids']} '
        'received ${receivedAt.toLocal()} '
        '${exists ? '' : 'FILE MISSING'}',
      );
    }
    return lines;
  }

  static const _missingNativeConfig =
      'MISSING. On iOS the widget writes this the first time WidgetKit builds '
      'its timeline; until then Rust grants nobody permission to share with '
      'the widget.';

  List<String> _nativeConfigSection(File config) {
    if (!config.existsSync()) {
      return ['-- native-config.json --', _missingNativeConfig];
    }
    return [
      '-- native-config.json --',
      'modified ${config.statSync().modified.toLocal()}',
      config.readAsStringSync(),
    ];
  }

  List<String> _imagesSection(Directory images) {
    if (!images.existsSync()) {
      return ['-- images/ --', 'MISSING'];
    }
    final files = images.listSync().whereType<File>().toList();
    return [
      '-- images/ --',
      if (files.isEmpty) '(empty)',
      for (final file in files)
        '  ${file.uri.pathSegments.last}  ${file.lengthSync()} bytes',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Widget'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy report',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _report));
              if (!context.mounted) return;
              showSnackbar(
                context,
                'Report copied.',
                level: SnackbarLevel.info,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () async {
                      await HomeWidgetService.syncPermissions();
                      await _load();
                    },
                    child: const Text('Rewrite manifest'),
                  ),
                ),
                const Expanded(
                  child: _ReloadWidgetButton(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                _report,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReloadWidgetButton extends StatelessWidget {
  const _ReloadWidgetButton();

  @override
  Widget build(BuildContext context) {
    return const FilledButton.tonal(
      onPressed: HomeWidgetService.refresh,
      child: Text('Reload widget'),
    );
  }
}
