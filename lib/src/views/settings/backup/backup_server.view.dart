// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

class BackupServerView extends StatefulWidget {
  const BackupServerView({super.key});

  @override
  State<BackupServerView> createState() => _BackupServerViewState();
}

class _BackupServerViewState extends State<BackupServerView> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    _urlController.text = 'https://';
    super.initState();
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    if (gUser.backupServer != null) {
      final uri = Uri.parse(gUser.backupServer!.serverUrl);
      // remove user auth data
      final serverUrl = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        path: uri.path,
        query: uri.query,
      );
      _urlController.text = serverUrl.toString();
      _usernameController.text = serverUrl.userInfo.split(':')[0];
    }
    setState(() {});
  }

  Future<void> checkAndUpdateBackupServer() async {
    var serverUrl = _urlController.text;
    if (!serverUrl.endsWith('/')) {
      serverUrl += '/';
    }

    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isNotEmpty || password.isNotEmpty) {
      serverUrl = serverUrl.replaceAll('https://', '');
      serverUrl = 'https://$username@$password$serverUrl';
    }

    try {
      final uri = Uri.parse('${serverUrl}config');
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'twonly',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON.
        final data = jsonDecode(response.body);

        final backupServer = BackupServer(
          serverUrl: serverUrl,
          retentionDays: data['retentionDays']! as int,
          maxBackupBytes: data['maxBackupBytes']! as int,
        );
        await updateUserdata((user) {
          user.backupServer = backupServer;
          return user;
        });
        if (mounted) Navigator.pop(context, backupServer);
      } else {
        // If the server did not return a 200 OK response, throw an exception.
        throw Exception(
          'Got invalid status code ${response.statusCode} from server.',
        );
      }
    } catch (e) {
      Log.error('$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('twonly Backup Server'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: ListView(
          children: [
            Text(
              context.lang.backupOwnServerDesc,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _urlController,
              onChanged: (value) {
                if (value.length < 8) {
                  value = '';
                }
                value = value.replaceAll('https://', '');
                value = value.replaceAll('http://', '');
                value = 'https://$value';
                _urlController.text = value;
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Server URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password (optional)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed: (_urlController.text.length > 8)
                    ? checkAndUpdateBackupServer
                    : null,
                icon: const FaIcon(FontAwesomeIcons.server),
                label: Text(context.lang.backupUseOwnServer),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: OutlinedButton(
                onPressed: () async {
                  await updateUserdata((user) {
                    user.backupServer = null;
                    return user;
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(context.lang.backupResetServer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
