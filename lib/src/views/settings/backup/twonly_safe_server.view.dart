import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

class TwonlySafeServerView extends StatefulWidget {
  const TwonlySafeServerView({super.key});

  @override
  State<TwonlySafeServerView> createState() => _TwonlySafeServerViewState();
}

class _TwonlySafeServerViewState extends State<TwonlySafeServerView> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    _urlController.text = "https://";
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    final user = await getUser();
    if (user?.backupServer != null) {
      var uri = Uri.parse(user!.backupServer!.serverUrl);
      // remove user auth data
      Uri serverUrl = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        path: uri.path,
        query: uri.query,
      );
      _urlController.text = serverUrl.toString();
      _usernameController.text = serverUrl.userInfo.split(":")[0].toString();
    }
    setState(() {});
  }

  Future checkAndUpdateBackupServer() async {
    String serverUrl = _urlController.text;
    if (!serverUrl.endsWith("/")) {
      serverUrl += "/";
    }

    String username = _usernameController.text;
    String password = _passwordController.text;

    if (username.isNotEmpty || password.isNotEmpty) {
      serverUrl = serverUrl.replaceAll("https://", "");
      serverUrl = "https://$username@$password$serverUrl";
    }

    final uri = Uri.parse("${serverUrl}config");

    final response = await http.get(
      uri,
      headers: {
        'User-Agent': 'twonly',
        'Accept': 'application/json',
      },
    );

    try {
      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON.
        final data = jsonDecode(response.body);

        final backupServer = BackupServer(
            serverUrl: serverUrl,
            retentionDays: data["retentionDays"]!,
            maxBackupBytes: data["maxBackupBytes"]!);
        await updateUserdata((user) {
          user.backupServer = backupServer;
          return user;
        });
        if (mounted) Navigator.pop(context);
      } else {
        // If the server did not return a 200 OK response, throw an exception.
        throw Exception(
            'Got invalid status code ${response.statusCode} from server.');
      }
    } catch (e) {
      Log.error("$e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('twonly Safe Server'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: ListView(
          children: [
            Text(
              "Speichere dein twonly Safe-Backup bei twonly oder auf einem beliebigen Server deiner Wahl.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _urlController,
              onChanged: (value) {
                if (value.length < 8) {
                  value = "";
                }
                value = value.replaceAll("https://", "");
                value = value.replaceAll("http://", "");
                value = "https://$value";
                _urlController.text = value;
                setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Server URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password (optional)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 20.0),
            Center(
              child: FilledButton.icon(
                onPressed: (_urlController.text.length > 8)
                    ? checkAndUpdateBackupServer
                    : null,
                icon: FaIcon(FontAwesomeIcons.server),
                label: Text('Server verwenden'),
              ),
            ),
            SizedBox(height: 10.0),
            Center(
              child: OutlinedButton(
                onPressed: () async {
                  await updateUserdata((user) {
                    user.backupServer = null;
                    return user;
                  });
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text("Standardserver verwenden"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
