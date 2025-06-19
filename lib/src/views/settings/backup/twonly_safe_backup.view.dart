import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/services/twonly_safe/common.twonly_safe.dart';
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
    if (!mounted) return;
    if (!await isSecurePassword(passwordCtrl.text)) {
      if (!mounted) return;
      bool ignore = await showAlertDialog(
        context,
        context.lang.backupInsecurePassword,
        context.lang.backupInsecurePasswordDesc,
        customCancel: context.lang.backupInsecurePasswordOk,
        customOk: context.lang.backupInsecurePasswordCancel,
      );
      if (ignore) {
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    await Future.delayed(Duration(milliseconds: 100));
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
              showAlertDialog(
                context,
                "twonly Safe",
                context.lang.backupTwonlySafeLongDesc,
              );
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
              context.lang.backupSelectStrongPassword,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Stack(
              children: [
                TextField(
                  controller: passwordCtrl,
                  onChanged: (value) {
                    setState(() {});
                  },
                  style: TextStyle(fontSize: 17),
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
                )
              ],
            ),
            Padding(
              padding: EdgeInsetsGeometry.all(5),
              child: Text(
                context.lang.backupPasswordRequirement,
                style: TextStyle(
                    color: ((passwordCtrl.text.length < 8 &&
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
              },
              style: TextStyle(fontSize: 17),
              obscureText: true,
              decoration: getInputDecoration(
                context,
                context.lang.passwordRepeated,
              ),
            ),
            Padding(
              padding: EdgeInsetsGeometry.all(5),
              child: Text(
                context.lang.passwordRepeatedNotEqual,
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
                child: Text(context.lang.backupExpertSettings),
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
              label: Text(context.lang.backupEnableBackup),
            ))
          ],
        ),
      ),
    );
  }
}

Future<bool> isSecurePassword(String password) async {
  String badPasswordsStr =
      await rootBundle.loadString('assets/passwords/bad_passwords.txt');
  List<String> badPasswords = badPasswordsStr.split("\n");
  if (badPasswords.contains(password)) {
    return false;
  }
  // Check if the password meets all criteria
  return RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password);
}
