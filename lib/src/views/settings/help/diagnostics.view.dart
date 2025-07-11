import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/src/utils/log.dart';

class DiagnosticsView extends StatefulWidget {
  const DiagnosticsView({super.key});

  @override
  State<DiagnosticsView> createState() => _DiagnosticsViewState();
}

class _DiagnosticsViewState extends State<DiagnosticsView> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    // Assuming the button is at the bottom of the scroll view
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent, // Scroll to the bottom
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: FutureBuilder<String>(
        future: loadLogFile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final logText = snapshot.data ?? '';

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    child: Text(logText),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final directory =
                              await getApplicationSupportDirectory();
                          final logFile = XFile('${directory.path}/app.log');

                          final params = ShareParams(
                            text: 'Debug log',
                            files: [logFile],
                          );

                          final result = await SharePlus.instance.share(params);

                          if (result.status != ShareResultStatus.success) {
                            Clipboard.setData(ClipboardData(text: logText));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Log copied to clipboard!')),
                              );
                            }
                          }
                        },
                        child: const Text('Share debug log'),
                      ),
                      TextButton(
                        onPressed: _scrollToBottom,
                        child: const Text('Scroll to Bottom'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (await deleteLogFile()) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Log file deleted!')),
                            );
                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Log file does not exist.')),
                            );
                          }
                        },
                        child: const Text('Delete Log File'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
