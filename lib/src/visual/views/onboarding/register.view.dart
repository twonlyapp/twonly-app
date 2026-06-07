// ignore_for_file: avoid_dynamic_calls

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/json/userdata.model.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/pow.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/views/groups/group.view.dart';
import 'package:twonly/src/visual/views/onboarding/components/link_logo_animation.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({
    required this.callbackOnSuccess,
    required this.proofOfWork,
    super.key,
  });

  final Function callbackOnSuccess;
  final (Future<int>?, bool) proofOfWork;
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();

  bool _registrationDisabled = false;
  bool _isTryingToRegister = false;
  bool _isValidUserName = false;

  bool _showProofOfWorkError = false;
  String? _usernameErrorText;

  late Future<int>? proofOfWork;

  @override
  void initState() {
    super.initState();
    proofOfWork = widget.proofOfWork.$1;
    _registrationDisabled = widget.proofOfWork.$2;
  }

  Future<void> createNewUser() async {
    if (!_isValidUserName) {
      setState(() {
        _usernameErrorText = context.lang.registerUsernameLimits;
      });
      return;
    }
    final username = usernameController.text;
    final inviteCode = inviteCodeController.text;

    setState(() {
      _isTryingToRegister = true;
      _usernameErrorText = null;
      _showProofOfWorkError = false;
    });

    try {
      late int proof;

      if (proofOfWork != null) {
        proof = await proofOfWork!;
      } else {
        final (pow, registrationDisabled) = await apiService.getProofOfWork();
        if (pow == null) {
          setState(() {
            _registrationDisabled = registrationDisabled;
            _isTryingToRegister = false;
          });
          if (mounted) {
            showNetworkIssue(context);
          }
          return;
        }
        proof = await calculatePoW(pow.prefix, pow.difficulty.toInt());
      }

      Log.info('The result of the POW is $proof');

      await createIfNotExistsSignalIdentity();

      var userId = 0;

      final res = await apiService.register(username, inviteCode, proof);
      if (res.isSuccess) {
        Log.info('Got user_id ${res.value} from server');
        userId = res.value.userid.toInt() as int;
      } else {
        proofOfWork = null;
        if (res.error == ErrorCode.RegistrationDisabled) {
          setState(() {
            _registrationDisabled = true;
            _isTryingToRegister = false;
          });
          return;
        }
        if (res.error == ErrorCode.UserIdAlreadyTaken) {
          Log.error('User ID already token. Tying again.');
          await deleteLocalUserData();
          return createNewUser();
        }
        if (res.error == ErrorCode.UsernameAlreadyTaken ||
            res.error == ErrorCode.UsernameNotValid) {
          setState(() {
            _usernameErrorText = errorCodeToText(
              context,
              res.error as ErrorCode,
            );
            _isTryingToRegister = false;
          });
          return;
        }
        if (res.error == ErrorCode.InvalidProofOfWork) {
          await deleteLocalUserData();
          setState(() {
            _showProofOfWorkError = true;
            _isTryingToRegister = false;
          });
          return;
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
        subscriptionPlan: 'Free',
        currentSetupPage: SetupPages.profile.name,
        appVersion: AppState.latestAppVersionId,
      );

      await UserService.save(userData);

      await apiService.authenticate();
      widget.callbackOnSuccess();
    } catch (e, stack) {
      Log.error('Error creating new user', e, stack);
      if (mounted) {
        setState(() {
          _isTryingToRegister = false;
        });
        await showAlertDialog(
          context,
          'Error',
          e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 30),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            child: LinkLogoAnimation(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            context.lang.registerSlogan,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.7) ??
                                  (isDark
                                      ? Colors.white.withValues(alpha: 0.7)
                                      : Colors.black.withValues(alpha: 0.7)),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        if (_registrationDisabled) ...[
                          Text(
                            context.lang.registrationClosed,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ] else ...[
                          Text(
                            context.lang.registerUsernameSlogan,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          MyInput(
                            controller: usernameController,
                            errorText: _usernameErrorText,
                            onChanged: (value) {
                              usernameController.text = value.toLowerCase();
                              usernameController.selection =
                                  TextSelection.fromPosition(
                                    TextPosition(
                                      offset: usernameController.text.length,
                                    ),
                                  );
                              setState(() {
                                _isValidUserName =
                                    usernameController.text.length >= 3;
                                _usernameErrorText = null;
                              });
                            },
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(12),
                              FilteringTextInputFormatter.allow(
                                RegExp('[a-z0-9A-Z._]'),
                              ),
                            ],
                            hintText: context.lang.registerUsernameDecoration,
                            prefixIcon: const Icon(Icons.alternate_email),
                          ),
                          if (_showProofOfWorkError) ...[
                            const SizedBox(height: 10),
                            Text(
                              context.lang.registerProofOfWorkFailed,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 32),
                          MyButton(
                            onPressed: _isTryingToRegister
                                ? null
                                : createNewUser,
                            child: _isTryingToRegister
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator.adaptive(
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    context.lang.registerSubmitButton,
                                  ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        MyButton(
                          onPressed: () => context.push(
                            Routes.settingsBackupRecovery,
                          ),
                          variant: MyButtonVariant.secondary,
                          child: Text(
                            context.lang.twonlySafeRecoverBtn,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
