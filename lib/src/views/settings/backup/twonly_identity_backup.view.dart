import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';

class TwonlyIdentityBackupView extends StatefulWidget {
  const TwonlyIdentityBackupView({super.key});

  @override
  State<TwonlyIdentityBackupView> createState() =>
      _TwonlyIdentityBackupViewState();
}

class _TwonlyIdentityBackupViewState extends State<TwonlyIdentityBackupView> {
  bool obscureText = true;
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController repeatedPasswordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("twonly Safe"),
        actions: [
          IconButton(
            onPressed: () {
              showAlertDialog(context, "twonly Safe",
                  "Backup of your twonly-Identity. As twonly does not have any second factor like your phone number or email, this backup contains your twonly-Identity. If you lose your device, the only option to recover is with the twonly-ID Backup. This backup will be protected by a password chosen by you in the next step and anonymously uploaded to the twonly servers. Read more [here](https://twonly.eu/s/backup)");
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
          ],
        ),
      ),
    );
  }
}
