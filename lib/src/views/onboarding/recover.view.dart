import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/services/twonly_safe/restore.twonly_safe.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/settings/backup/twonly_safe_server.view.dart';

class BackupRecoveryView extends StatefulWidget {
  const BackupRecoveryView({super.key});

  @override
  State<BackupRecoveryView> createState() => _BackupRecoveryViewState();
}

class _BackupRecoveryViewState extends State<BackupRecoveryView> {
  bool obscureText = true;
  bool isLoading = false;
  BackupServer? backupServer;
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  Future<void> _recoverTwonlySafe() async {
    setState(() {
      isLoading = true;
    });

    try {
      await recoverTwonlySafe(
        usernameCtrl.text,
        passwordCtrl.text,
        backupServer,
      );

      await Restart.restartApp(
        notificationTitle: 'Backup successfully recovered.',
        notificationBody: 'Click here to open the app again',
      );
    } catch (e) {
      // in case something was already written from the backup...
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

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('twonly Backup ${context.lang.twonlySafeRecoverTitle}'),
        actions: [
          IconButton(
            onPressed: () async {
              await showAlertDialog(
                context,
                'twonly Backup',
                context.lang.backupTwonlySafeLongDesc,
              );
            },
            icon: const FaIcon(FontAwesomeIcons.circleInfo),
            iconSize: 18,
          ),
        ],
      ),
      body: Padding(
        padding:
            const EdgeInsetsGeometry.symmetric(vertical: 40, horizontal: 40),
        child: ListView(
          children: [
            Text(
              context.lang.twonlySafeRecoverDesc,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: usernameCtrl,
              onChanged: (value) {
                setState(() {});
              },
              style: const TextStyle(fontSize: 17),
              decoration: getInputDecoration(
                context,
                context.lang.registerUsernameDecoration,
              ),
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                TextField(
                  controller: passwordCtrl,
                  onChanged: (value) {
                    setState(() {});
                  },
                  style: const TextStyle(fontSize: 17),
                  obscureText: obscureText,
                  decoration: getInputDecoration(
                    context,
                    context.lang.password,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                    icon: FaIcon(
                      obscureText
                          ? FontAwesomeIcons.eye
                          : FontAwesomeIcons.eyeSlash,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: OutlinedButton(
                onPressed: () async {
                  backupServer = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const TwonlySafeServerView();
                      },
                    ),
                  );
                  setState(() {});
                },
                child: Text(context.lang.backupExpertSettings),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: FilledButton.icon(
                onPressed: (!isLoading) ? _recoverTwonlySafe : null,
                icon: isLoading
                    ? const SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(strokeWidth: 1),
                      )
                    : const Icon(Icons.lock_clock_rounded),
                label: Text(context.lang.twonlySafeRecoverBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
