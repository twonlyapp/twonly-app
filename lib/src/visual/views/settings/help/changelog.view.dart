import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/utils/misc.dart';

enum _ChangeKind { added, improved, fixed, security, other }

@immutable
class _Change {
  const _Change(this.kind, this.label, this.text);

  final _ChangeKind kind;
  final String? label;
  final String text;
}

class _Release {
  const _Release(this.version, this.changes);

  final String version;
  final List<_Change> changes;
}

const Map<String, _ChangeKind> _kindsByPrefix = {
  'new': _ChangeKind.added,
  'improve': _ChangeKind.improved,
  'fix': _ChangeKind.fixed,
  'hotfix': _ChangeKind.fixed,
  'security fix': _ChangeKind.security,
};

final _prefixPattern = RegExp(r'^([A-Za-z ]+):\s*(.*)$');

_Change _parseChange(String line) {
  final match = _prefixPattern.firstMatch(line);
  if (match != null) {
    final kind = _kindsByPrefix[match.group(1)!.toLowerCase()];
    if (kind != null) return _Change(kind, match.group(1), match.group(2)!);
  }
  return _Change(_ChangeKind.other, null, line);
}

List<_Release> _parseChangelog(String markdown) {
  final releases = <_Release>[];
  for (final raw in markdown.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('# ')) continue;
    if (line.startsWith('## ')) {
      releases.add(_Release(line.substring(3).trim(), []));
      continue;
    }
    if (releases.isEmpty) continue;
    final text = line.startsWith('- ') ? line.substring(2) : line;
    releases.last.changes.add(_parseChange(text));
  }
  return releases;
}

class ChangeLogView extends StatefulWidget {
  const ChangeLogView({super.key, this.changeLog});

  final String? changeLog;

  @override
  State<ChangeLogView> createState() => _ChangeLogViewState();
}

class _ChangeLogViewState extends State<ChangeLogView> {
  List<_Release>? _releases;

  @override
  void initState() {
    super.initState();
    if (widget.changeLog != null) {
      _releases = _parseChangelog(widget.changeLog!);
    } else {
      unawaited(initAsync());
    }
  }

  Future<void> initAsync() async {
    final changeLog = await rootBundle.loadString('CHANGELOG.md');
    if (mounted) setState(() => _releases = _parseChangelog(changeLog));
  }

  @override
  Widget build(BuildContext context) {
    final releases = _releases;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsChangelog),
      ),
      body: releases == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : SafeArea(
              top: false,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: releases.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _ReleaseCard(
                  release: releases[index],
                  isLatest: index == 0,
                ),
              ),
            ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({required this.release, required this.isLatest});

  final _Release release;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: isLatest
            ? Border.all(color: context.color.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VersionChip(version: release.version, highlighted: isLatest),
            const SizedBox(height: 8),
            ...release.changes.map((change) => _ChangeRow(change: change)),
          ],
        ),
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({required this.version, required this.highlighted});

  final String version;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted
            ? context.color.primaryContainer
            : context.color.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          'v$version',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: highlighted
                ? context.color.onPrimaryContainer
                : context.color.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({required this.change});

  final _Change change;

  @override
  Widget build(BuildContext context) {
    final (icon, background, foreground) = switch (change.kind) {
      _ChangeKind.added => (
        Icons.auto_awesome_rounded,
        context.color.primaryContainer,
        context.color.onPrimaryContainer,
      ),
      _ChangeKind.improved => (
        Icons.trending_up_rounded,
        context.color.tertiaryContainer,
        context.color.onTertiaryContainer,
      ),
      _ChangeKind.fixed => (
        Icons.build_rounded,
        context.color.secondaryContainer,
        context.color.onSecondaryContainer,
      ),
      _ChangeKind.security => (
        Icons.shield_rounded,
        context.color.errorContainer,
        context.color.onErrorContainer,
      ),
      _ChangeKind.other => (
        Icons.circle,
        context.color.surfaceContainerHighest,
        context.color.onSurfaceVariant,
      ),
    };
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      height: 1.35,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: change.kind == _ChangeKind.other ? 6 : 15,
              color: foreground,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text.rich(
                TextSpan(
                  children: [
                    if (change.label != null)
                      TextSpan(
                        text: '${change.label}  ',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    TextSpan(text: change.text),
                  ],
                ),
                style: textStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
