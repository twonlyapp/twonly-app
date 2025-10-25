// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/onboarding/recover.view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({required this.callbackOnSuccess, super.key});

  final Function callbackOnSuccess;
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();

  bool _isTryingToRegister = false;
  bool _isValidUserName = false;
  bool _showUserNameError = false;

  Future<void> createNewUser() async {
    if (!_isValidUserName) {
      setState(() {
        _showUserNameError = true;
      });
      return;
    }
    final username = usernameController.text;
    final inviteCode = inviteCodeController.text;

    setState(() {
      _isTryingToRegister = true;
      _showUserNameError = false;
    });

    await createIfNotExistsSignalIdentity();

    var userId = 0;

    final res = await apiService.register(username, inviteCode);
    if (res.isSuccess) {
      Log.info('Got user_id ${res.value} from server');
      userId = res.value.userid.toInt() as int;
    } else {
      if (res.error == ErrorCode.UserIdAlreadyTaken) {
        Log.error('User ID already token. Tying again.');
        await deleteLocalUserData();
        return createNewUser();
      }
      if (mounted) {
        setState(() {
          _isTryingToRegister = false;
        });
        await showAlertDialog(
          context,
          'Oh no!',
          errorCodeToText(context, res.error as ErrorCode),
        );
      }
      return;
    }

    setState(() {
      _isTryingToRegister = false;
    });

    final userData = UserData(
      userId: userId,
      username: username,
      displayName: username,
      subscriptionPlan: 'Preview',
    )..appVersion = 62;

    await const FlutterSecureStorage()
        .write(key: SecureStorageKeys.userData, value: jsonEncode(userData));

    gUser = userData;

    await apiService.authenticate();
    widget.callbackOnSuccess();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration getInputDecoration(String hintText) {
      return InputDecoration(hintText: hintText, fillColor: Colors.grey[400]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: ListView(
            children: [
              const SizedBox(height: 50),
              Text(
                context.lang.registerTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 30),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  context.lang.registerSlogan,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 60),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Text(
                    context.lang.registerUsernameSlogan,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
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
                  FilteringTextInputFormatter.allow(RegExp('[a-z0-9A-Z]')),
                ],
                style: const TextStyle(fontSize: 17),
                decoration: getInputDecoration(
                  context.lang.registerUsernameDecoration,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.lang.registerUsernameLimits,
                style: TextStyle(
                  color: _showUserNameError ? Colors.red : Colors.transparent,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              // const SizedBox(height: 5),
              // Center(
              //   child: Padding(
              //     padding: EdgeInsets.only(left: 10, right: 10),
              //     child: Text(
              //       context.lang.registerUsernameLimits,
              //       textAlign: TextAlign.center,
              //       style: const TextStyle(fontSize: 9),
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 30),
              // Center(
              //   child: Text(
              //     context.lang.registerTwonlyCodeText,
              //     textAlign: TextAlign.center,
              //   ),
              // ),
              // const SizedBox(height: 10),
              // TextField(
              //   controller: inviteCodeController,
              //   decoration:
              //       getInputDecoration(context.lang.registerTwonlyCodeLabel),
              // ),
              const SizedBox(height: 30),
              Column(
                children: [
                  FilledButton.icon(
                    icon: _isTryingToRegister
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.group),
                    onPressed: createNewUser,
                    style: ButtonStyle(
                      padding: WidgetStateProperty.all<EdgeInsets>(
                        const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 30,
                        ),
                      ),
                      backgroundColor: _isTryingToRegister
                          ? WidgetStateProperty.all<MaterialColor>(
                              Colors.grey,
                            )
                          : null,
                    ),
                    label: Text(
                      context.lang.registerSubmitButton,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const BackupRecoveryView();
                              },
                            ),
                          );
                        },
                        label: Text(context.lang.twonlySafeRecoverBtn),
                      ),
                    ],
                  ),
                ],
              ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}
