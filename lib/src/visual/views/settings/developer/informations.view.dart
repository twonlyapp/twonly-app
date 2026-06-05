import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/visual/components/snackbar.dart';

class DeveloperInformationsView extends StatefulWidget {
  const DeveloperInformationsView({super.key});

  @override
  State<DeveloperInformationsView> createState() =>
      _DeveloperInformationsViewState();
}

class _DeveloperInformationsViewState extends State<DeveloperInformationsView> {
  String? _lastFcmTimestamp;
  String? _lastServerTimestamp;

  @override
  void initState() {
    super.initState();
    _loadInformations();
  }

  Future<void> _loadInformations({bool showFeedback = false}) async {
    const storage = FlutterSecureStorage();
    try {
      final lastFcm = await storage.read(
        key: SecureStorageKeys.lastFcmMessageTimestamp,
        iOptions: const IOSOptions(
          groupId: 'CN332ZUGRP.eu.twonly.shared',
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
      final lastServer = await storage.read(
        key: SecureStorageKeys.lastServerMessageTimestamp,
        iOptions: const IOSOptions(
          groupId: 'CN332ZUGRP.eu.twonly.shared',
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
      if (mounted) {
        setState(() {
          _lastFcmTimestamp = lastFcm;
          _lastServerTimestamp = lastServer;
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

  String _formatTimestamp(String? timestampStr) {
    if (timestampStr == null) return 'Never';
    final ms = int.tryParse(timestampStr);
    if (ms == null) return 'Invalid: $timestampStr';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return dt.toLocal().toString();
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
