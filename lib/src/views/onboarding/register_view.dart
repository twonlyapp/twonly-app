import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/signal.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key, required this.callbackOnSuccess});

  final Function callbackOnSuccess;
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();

  bool _isTryingToRegister = false;

  Future createNewUser() async {
    String username = usernameController.text;
    String inviteCode = inviteCodeController.text;
    setState(() {
      _isTryingToRegister = true;
    });

    final storage = FlutterSecureStorage();

    await createIfNotExistsSignalIdentity();

    final res = await apiProvider.register(username, inviteCode);

    if (res.isSuccess) {
      Logger("create_new_user").info("Got user_id ${res.value} from server");
      final userData = UserData(
        userId: res.value.userid.toInt(),
        username: username,
        displayName: username,
        subscriptionPlan: "Preview",
      );
      storage.write(key: "userData", value: jsonEncode(userData));
    }

    setState(() {
      _isTryingToRegister = false;
    });

    if (res.isSuccess) {
      apiProvider.authenticate();
      widget.callbackOnSuccess();
      return;
    }

    if (context.mounted) {
      // ignore: use_build_context_synchronously
      showAlertDialog(context, "Oh no!", errorCodeToText(context, res.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration getInputDecoration(hintText) {
      return InputDecoration(hintText: hintText, fillColor: Colors.grey[400]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(""),
      ),
      body: Padding(
          padding: EdgeInsets.all(10),
          child: Padding(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: ListView(
              children: [
                const SizedBox(height: 50),
                Text(
                  context.lang.registerTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    context.lang.registerSlogan,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 60),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Text(
                      context.lang.registerUsernameSlogan,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: usernameController,
                  onChanged: (value) {
                    usernameController.text = value.toLowerCase();
                    usernameController.selection = TextSelection.fromPosition(
                      TextPosition(offset: usernameController.text.length),
                    );
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(12),
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9A-Z]')),
                  ],
                  style: TextStyle(fontSize: 17),
                  decoration: getInputDecoration(
                    context.lang.registerUsernameDecoration,
                  ),
                ),
                const SizedBox(height: 5),
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Text(
                      context.lang.registerUsernameLimits,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 7),
                    ),
                  ),
                ),
                // const SizedBox(height: 15),
                // Center(
                //   child: Text(
                //     "To protect this small experimental project you need an invitation code! To get one just ask the right person!",
                //     textAlign: TextAlign.center,
                //   ),
                // ),
                // const SizedBox(height: 10),
                // TextField(
                //     controller: inviteCodeController,
                //     decoration: getInputDecoration("Voucher code")),
                // const SizedBox(height: 25),
                // Center(
                //   child: Text(
                //     "Please ",
                //     textAlign: TextAlign.center,
                //   ),
                // ),
                const SizedBox(height: 50),
                // Padding(
                //   padding: EdgeInsets.symmetric(horizontal: 10),
                Column(children: [
                  FilledButton.icon(
                    icon: _isTryingToRegister
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.group),
                    onPressed: () async {
                      createNewUser();
                    },
                    style: ButtonStyle(
                        padding: WidgetStateProperty.all<EdgeInsets>(
                          EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                        ),
                        backgroundColor: _isTryingToRegister
                            ? WidgetStateProperty.all<MaterialColor>(
                                Colors.grey)
                            : null),
                    label: Text(
                      context.lang.registerSubmitButton,
                      style: TextStyle(fontSize: 17),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      showAlertDialog(context, "Coming soon",
                          "This feature is not yet implemented! Just create a new account :/");
                    },
                    label: Text("Restore identity"),
                  ),
                ]),
                //   ),
              ],
            ),
          )),
    );
  }
}
