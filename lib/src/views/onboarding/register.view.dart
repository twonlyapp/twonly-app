import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twonly/globals.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/onboarding/recover.view.dart';

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
  bool _isValidUserName = false;

  Future createNewUser({bool isDemoAccount = false}) async {
    String username = (isDemoAccount) ? "<demo>" : usernameController.text;
    String inviteCode = inviteCodeController.text;

    setState(() {
      _isTryingToRegister = true;
    });

    await createIfNotExistsSignalIdentity();

    int userId = 0;

    if (!isDemoAccount) {
      final res = await apiService.register(username, inviteCode);
      if (res.isSuccess) {
        Log.info("Got user_id ${res.value} from server");
        userId = res.value.userid.toInt();
      } else {
        if (res.error == ErrorCode.UserIdAlreadyTaken) {
          Log.error("User ID already token. Tying again.");
          await deleteLocalUserData();
          return createNewUser();
        }
        if (mounted) {
          showAlertDialog(
            context,
            "Oh no!",
            errorCodeToText(context, res.error),
          );
        }
        return;
      }
    }

    setState(() {
      _isTryingToRegister = false;
    });

    final userData = UserData(
      userId: userId,
      username: username,
      displayName: username,
      subscriptionPlan: "Preview",
      isDemoUser: isDemoAccount,
    );

    FlutterSecureStorage()
        .write(key: SecureStorageKeys.userData, value: jsonEncode(userData));

    if (!isDemoAccount) {
      await apiService.authenticate();
    } else {
      gIsDemoUser = true;
      createFakeDemoData();
    }
    widget.callbackOnSuccess();
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
                    setState(() {
                      _isValidUserName = usernameController.text.length >= 3;
                    });
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
                // const SizedBox(height: 5),
                // Center(
                //   child: Padding(
                //     padding: EdgeInsets.only(left: 10, right: 10),
                //     child: Text(
                //       context.lang.registerUsernameLimits,
                //       textAlign: TextAlign.center,
                //       style: TextStyle(fontSize: 9),
                //     ),
                //   ),
                // ),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    context.lang.registerTwonlyCodeText,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: inviteCodeController,
                  decoration:
                      getInputDecoration(context.lang.registerTwonlyCodeLabel),
                ),
                const SizedBox(height: 30),
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
                    onPressed: _isValidUserName ? createNewUser : null,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          createNewUser(isDemoAccount: true);
                        },
                        label: Text("Demo"),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) {
                              return BackupRecoveryView();
                            },
                          ));
                        },
                        label: Text("Restore identity"),
                      ),
                    ],
                  ),
                ]),
                //   ),
              ],
            ),
          )),
    );
  }
}
