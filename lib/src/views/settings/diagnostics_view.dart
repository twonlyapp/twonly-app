import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/utils/misc.dart';

class DiagnosticsView extends StatelessWidget {
  const DiagnosticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<String>(
        future: _loadLogFile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final logText = snapshot.data ?? '';

            return Scaffold(
              appBar: AppBar(title: const Text('Diagnostics')),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
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
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: logText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Log copied to clipboard!')),
                            );
                          },
                          child: const Text('Copy All Text'),
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
              ),
            );
          }
        },
      ),
    );
  }

  Future<String> _loadLogFile() async {
    final directory = await getApplicationSupportDirectory();
    final logFile = File('${directory.path}/app.log');

    if (await logFile.exists()) {
      return await logFile.readAsString();
    } else {
      return 'Log file does not exist.';
    }
  }
}
