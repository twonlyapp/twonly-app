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
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/groups/group.view.dart';
import 'package:twonly/src/visual/views/onboarding/components/link_logo_animation.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_wrapper.dart';
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
  bool _showUserNameError = false;
  bool _showProofOfWorkError = false;

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
        _showUserNameError = true;
      });
      return;
    }
    final username = usernameController.text;
    final inviteCode = inviteCodeController.text;

    setState(() {
      _isTryingToRegister = true;
      _showUserNameError = false;
      _showProofOfWorkError = false;
    });

    late int proof;

    if (proofOfWork != null) {
      proof = await proofOfWork!;
    } else {
      final (pow, registrationDisabled) = await apiService.getProofOfWork();
      if (pow == null) {
        _registrationDisabled = registrationDisabled;
        if (mounted) {
          showNetworkIssue(context);
        }
        return;
        // Starting with the proof of work.
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
        _registrationDisabled = true;
        return;
      }
      if (res.error == ErrorCode.UserIdAlreadyTaken) {
        Log.error('User ID already token. Tying again.');
        await deleteLocalUserData();
        return createNewUser();
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputColor = isDark ? const Color(0xFF0F172A) : Colors.grey[100];
    final sloganColor = isDark ? Colors.white.withValues(alpha: 0.9) : Colors.grey[800];
    final secondaryButtonColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return OnboardingWrapper(
      children: [
        const SizedBox(height: 30),
        Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: const LinkLogoAnimation(),
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
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_registrationDisabled) ...[
                const SizedBox(height: 24),
                Text(
                  context.lang.registrationClosed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 48),
              ] else ...[
                Text(
                  context.lang.registerUsernameSlogan,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: sloganColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  onChanged: (value) {
                    usernameController.text = value.toLowerCase();
                    usernameController.selection = TextSelection.fromPosition(
                      TextPosition(
                        offset: usernameController.text.length,
                      ),
                    );
                    setState(() {
                      _isValidUserName = usernameController.text.length >= 3;
                    });
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(12),
                    FilteringTextInputFormatter.allow(
                      RegExp('[a-z0-9A-Z._]'),
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: context.lang.registerUsernameDecoration,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                    filled: true,
                    fillColor: inputColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: Icon(
                      Icons.alternate_email,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                if (_showUserNameError && usernameController.text.length < 3) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.lang.registerUsernameLimits,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_showProofOfWorkError) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.lang.registerProofOfWorkFailed,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isTryingToRegister ? null : createNewUser,
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _isTryingToRegister
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          context.lang.registerSubmitButton,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
              TextButton(
                onPressed: () => context.push(
                  Routes.settingsBackupRecovery,
                ),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: secondaryButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  context.lang.twonlySafeRecoverBtn,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const SizedBox(height: 40),
      ],
    );
  }
}
