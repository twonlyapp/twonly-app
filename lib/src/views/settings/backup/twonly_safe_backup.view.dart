import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/services/backup.identitiy.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/settings/backup/twonly_safe_server.view.dart';

class TwonlyIdentityBackupView extends StatefulWidget {
  const TwonlyIdentityBackupView({super.key});

  @override
  State<TwonlyIdentityBackupView> createState() =>
      _TwonlyIdentityBackupViewState();
}

class _TwonlyIdentityBackupViewState extends State<TwonlyIdentityBackupView> {
  bool obscureText = true;
  bool isLoading = false;
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController repeatedPasswordCtrl = TextEditingController();

  Future onPressedEnableTwonlySafe() async {
    setState(() {
      isLoading = true;
    });

    await enableTwonlySafe(passwordCtrl.text);

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("twonly Safe"),
        actions: [
          IconButton(
            onPressed: () {
              showAlertDialog(context, "twonly Safe",
                  "twonly does not have any central user accounts. A key pair is created during installation, which consists of a public and a private key. The private key is only stored on your device to protect it from unauthorized access. The public key is uploaded to the server and linked to your chosen user name so that others can find you.\n\ntwonly Safe regularly creates an encrypted, anonymous backup of your private key together with your contacts and settings. Your username and chosen password are enough to restore this data on another device. ");
            },
            icon: FaIcon(FontAwesomeIcons.circleInfo),
            iconSize: 18,
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(vertical: 40, horizontal: 40),
        child: ListView(
          children: [
            Text(
              "Wähle ein sicheres Passwort. Dieses wird benötigt, wenn du dein twonly Safe-Backup wiederherstellen möchtest.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Stack(
              children: [
                TextField(
                  controller: passwordCtrl,
                  onChanged: (value) {
                    setState(() {});
                    // usernameController.text = value.toLowerCase();
                    // usernameController.selection = TextSelection.fromPosition(
                    //   TextPosition(offset: usernameController.text.length),
                    // );
                  },
                  style: TextStyle(fontSize: 17),
                  obscureText: obscureText,
                  decoration: getInputDecoration(
                    context,
                    "Password",
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
                )
              ],
            ),
            Padding(
              padding: EdgeInsetsGeometry.all(5),
              child: Text(
                "Passwort muss mind. 10 Zeichen lang sein.",
                style: TextStyle(
                    color: ((passwordCtrl.text.length <= 10 &&
                            passwordCtrl.text.isNotEmpty))
                        ? Colors.red
                        : Colors.transparent),
              ),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: repeatedPasswordCtrl,
              onChanged: (value) {
                setState(() {});
                // usernameController.text = value.toLowerCase();
                // usernameController.selection = TextSelection.fromPosition(
                //   TextPosition(offset: usernameController.text.length),
                // );
              },
              style: TextStyle(fontSize: 17),
              obscureText: true,
              decoration: getInputDecoration(
                context,
                "Passwordwiederholung",
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.all(5),
              child: Text(
                "Passwörter stimmen nicht überein.",
                style: TextStyle(
                    color: (passwordCtrl.text != repeatedPasswordCtrl.text &&
                            repeatedPasswordCtrl.text.isNotEmpty)
                        ? Colors.red
                        : Colors.transparent),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return TwonlySafeServerView();
                  }));
                },
                child: Text("Experten Einstellungen"),
              ),
            ),
            SizedBox(height: 10),
            Center(
                child: FilledButton.icon(
              onPressed: (!isLoading &&
                      (passwordCtrl.text == repeatedPasswordCtrl.text &&
                              passwordCtrl.text.length >= 10 ||
                          kDebugMode))
                  ? onPressedEnableTwonlySafe
                  : null,
              icon: isLoading
                  ? SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(strokeWidth: 1),
                    )
                  : Icon(Icons.lock_clock_rounded),
              label: Text("Automatisches Backup aktivieren"),
            ))
          ],
        ),
      ),
    );
  }
}
