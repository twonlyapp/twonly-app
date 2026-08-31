import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/core/bridge/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/visual/components/snackbar.dart';

class DeveloperInformationsView extends StatefulWidget {
  const DeveloperInformationsView({super.key});

  @override
  State<DeveloperInformationsView> createState() =>
      _DeveloperInformationsViewState();
}

class _DeveloperInformationsViewState extends State<DeveloperInformationsView> {
  DateTime? _lastFcmTimestamp;
  DateTime? _lastServerTimestamp;

  @override
  void initState() {
    super.initState();
    _loadInformations();
  }

  Future<void> _loadInformations({bool showFeedback = false}) async {
    try {
      final config = await UserConfigApi.load();
      if (mounted) {
        setState(() {
          final lastFcmWakeup = config?.lastFcmWakeupAt;
          final lastServerMessage = config?.lastServerMessageAt;
          _lastFcmTimestamp = lastFcmWakeup == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(lastFcmWakeup * 1000);
          _lastServerTimestamp = lastServerMessage == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  lastServerMessage * 1000,
                );
        });
        if (showFeedback) {
          showSnackbar(
            context,
            'Developer information loaded',
            level: SnackbarLevel.success,
          );
        }
      }
    } catch (_) {}
  }

  String _formatTimestamp(DateTime? timestamp) {
    return timestamp?.toLocal().toString() ?? 'Never';
  }

  @override
  Widget build(BuildContext context) {
    final userId = userService.currentUser.userId.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadInformations(showFeedback: true),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('User ID'),
            subtitle: Text(userId),
            trailing: IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: userId));
                showSnackbar(context, 'User ID copied to clipboard');
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Last FCM Message'),
            subtitle: Text(_formatTimestamp(_lastFcmTimestamp)),
          ),
          ListTile(
            title: const Text('Last Server Message'),
            subtitle: Text(_formatTimestamp(_lastServerTimestamp)),
          ),
        ],
      ),
    );
  }
}
