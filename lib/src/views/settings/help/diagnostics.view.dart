import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/loader.dart';

class DiagnosticsView extends StatefulWidget {
  const DiagnosticsView({super.key});

  @override
  State<DiagnosticsView> createState() => _DiagnosticsViewState();
}

class _DiagnosticsViewState extends State<DiagnosticsView> {
  String? _debugLogText;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    _debugLogText = await readLast1000Lines();
    setState(() {});
  }

  Future<void> _deleteDebugLog() async {
    if (await deleteLogFile()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log file deleted!'),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log file does not exist.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: (_debugLogText == null)
          ? const Center(child: ThreeRotatingDots(size: 40))
          : Column(
              children: [
                Expanded(
                  child: LogViewerWidget(
                    logLines: _debugLogText!,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () =>
                            context.push(Routes.settingsHelpContactUs),
                        child: const Text('Share debug log'),
                      ),
                      TextButton(
                        onPressed: _deleteDebugLog,
                        child: const Text('Delete Log File'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class LogViewerWidget extends StatefulWidget {
  const LogViewerWidget({required this.logLines, super.key});
  final String logLines;

  @override
  State<LogViewerWidget> createState() => _LogViewerWidgetState();
}

class _LogViewerWidgetState extends State<LogViewerWidget> {
  String _filterLevel = 'ALL'; // ALL, FINE, WARNING, SHOUT
  bool _showTimestamps = true;
  late List<_LogEntry> _entries;
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _entries =
        widget.logLines.split('\n').reversed.map(_LogEntry.parse).toList();
  }

  void _setFilter(String level) => setState(() => _filterLevel = level);
  void _toggleTimestamps() =>
      setState(() => _showTimestamps = !_showTimestamps);

  List<_LogEntry> get _filtered {
    return _entries.where((e) {
      if (_filterLevel != 'ALL' && e.level != _filterLevel) return false;
      return true;
    }).toList();
  }

  Color _colorForLevel(String? level) {
    switch (level) {
      case 'WARNING':
        return Colors.orange.shade700;
      case 'SHOUT':
        return Colors.red.shade600;
      case 'FINE':
        return Colors.blueGrey.shade600;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _iconForLevel(String? level) {
    switch (level) {
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'SHOUT':
        return Icons.error_outline;
      case 'FINE':
        return Icons.info_outline;
      default:
        return Icons.notes;
    }
  }

  Widget _buildLevelChip(String label) {
    final selected = _filterLevel == label;
    return ChoiceChip(
      padding: EdgeInsets.zero,
      label: Text(label),
      selected: selected,
      onSelected: (_) => _setFilter(label),
      selectedColor: _colorForLevel(label).withAlpha(120),
    );
  }

  TextSpan _formatLineSpan(_LogEntry e) {
    final tsStyle = TextStyle(
      color: isDarkMode(context) ? Colors.white : Colors.black,
      fontFamily: 'monospace',
    );
    final levelStyle = TextStyle(
      color: Colors.blueGrey.shade600,
      fontWeight: FontWeight.bold,
      fontFamily: 'monospace',
    );
    final msgStyle = TextStyle(
      color: isDarkMode(context) ? Colors.white : Colors.black,
      fontFamily: 'monospace',
    );

    return TextSpan(
      children: [
        if (_showTimestamps && e.timestamp != null)
          TextSpan(
            text: '${e.timestamp} '.replaceAll('.000', ''),
            style: tsStyle,
          ),
        TextSpan(text: '${e.fileName}\n', style: levelStyle),
        TextSpan(text: e.message, style: msgStyle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              IconButton(
                tooltip:
                    _showTimestamps ? 'Hide timestamps' : 'Show timestamps',
                onPressed: _toggleTimestamps,
                icon: Icon(
                  _showTimestamps
                      ? Icons.access_time
                      : Icons.access_time_filled_outlined,
                ),
              ),
              _buildLevelChip('ALL'),
              const SizedBox(width: 3),
              _buildLevelChip('FINE'),
              const SizedBox(width: 3),
              _buildLevelChip('WARNING'),
              const SizedBox(width: 3),
              _buildLevelChip('SHOUT'),
              const Spacer(),
              Text(
                '${_filtered.length} lines',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(left: 8),
            child: Scrollbar(
              controller: _controller,
              child: ListView.builder(
                controller: _controller,
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final e = _filtered[i];
                  return InkWell(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: e.line));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied line')),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _colorForLevel(e.level).withAlpha(40),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _iconForLevel(e.level),
                              color: _colorForLevel(e.level),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: _formatLineSpan(e),
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogEntry {
  _LogEntry({
    required this.message,
    required this.line,
    required this.fileName,
    this.timestamp,
    this.level,
  });

  // Minimal parser based on the sample log format
  factory _LogEntry.parse(String raw) {
    // Example line:
    // 2025-12-25 23:36:52 WARNING [twonly] api.service.dart:189) > websocket error: ...
    final trimmed = raw.trim();
    DateTime? ts;
    String? level;
    var msg = trimmed;

    // Try to parse leading timestamp (YYYY-MM-DD HH:MM:SS)
    final tsRegex = RegExp(r'^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s+(.*)$');
    final mTs = tsRegex.firstMatch(trimmed);
    if (mTs != null) {
      try {
        ts = DateTime.parse(mTs.group(1)!.replaceFirst(' ', 'T'));
      } catch (_) {
        ts = null;
      }
      msg = mTs.group(2)!;
    }

    // Try to extract level token (FINE|WARNING|SHOUT)
    final lvlRegex = RegExp(r'^(FINE|WARNING|SHOUT)\b\s*(.*)$');
    final mLvl = lvlRegex.firstMatch(msg);
    if (mLvl != null) {
      level = mLvl.group(1);
      msg = mLvl.group(2)!;
    } else {
      // sometimes level appears after timestamp then tag like: "FINE [twonly] ..."
      final lvl2 = RegExp(r'^(?:\[[^\]]+\]\s*)?(FINE|WARNING|SHOUT)\b\s*(.*)$');
      final m2 = lvl2.firstMatch(msg);
      if (m2 != null) {
        level = m2.group(1);
        msg = m2.group(2)!;
      }
    }

    msg = msg.trim().replaceAll('[twonly] ', '');
    final fileNameS = msg.split(' > ');
    final fileName = fileNameS[0];

    msg = fileNameS.sublist(1).join();

    return _LogEntry(
      timestamp: ts,
      level: level,
      message: msg,
      line: raw,
      fileName: fileName,
    );
  }
  final DateTime? timestamp;
  final String? level;
  final String message;
  final String line;
  final String fileName;
}
