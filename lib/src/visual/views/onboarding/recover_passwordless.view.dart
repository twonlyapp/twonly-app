import 'dart:async';
import 'dart:convert';

import 'package:cryptography_plus/cryptography_plus.dart'
    show Hkdf, Hmac, Mac, SecretBox, SecretKey, Xchacha20;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hashlib/random.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/model/protobuf/client/generated/passwordless_recovery.pb.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/contact_chip.element.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/views/onboarding/components/animated_bell_icon.comp.dart';
import 'package:twonly/src/visual/views/onboarding/recovery_progress.view.dart';

class RecoverPasswordless extends StatefulWidget {
  const RecoverPasswordless({this.initialEmailToken, super.key});

  final String? initialEmailToken;

  @override
  State<RecoverPasswordless> createState() => _RecoverPasswordlessState();
}

class _RecoverPasswordlessState extends State<RecoverPasswordless> {
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  String _shareUrl = '';

  OnboardingState? _onboardingState;
  Timer? _pollTimer;

  RecoveryShareAnalysis _analysis = const RecoveryShareAnalysis();
  bool _isAnalyzing = false;
  bool _analyzeAgain = false;

  /// Rebuilt data the server refused for its account; skipped from now on.
  final Set<String> _rejectedSecrets = {};

  bool _isRecovering = false;
  final TextEditingController _secondFactorController = TextEditingController();

  StreamSubscription<String>? _emailTokenSubscription;

  @override
  void initState() {
    super.initState();
    final token =
        widget.initialEmailToken ?? PasswordlessRecoveryService.lastEmailToken;
    _secondFactorController.text = token ?? '';

    _emailTokenSubscription = PasswordlessRecoveryService
        .onEmailTokenReceived
        .stream
        .listen((token) async {
          if (mounted) {
            setState(() {
              _secondFactorController.text = token;
            });
          }
        });
    _initAsync(token);
  }

  @override
  void dispose() {
    _emailTokenSubscription?.cancel();
    _pollTimer?.cancel();
    _secondFactorController.dispose();
    super.dispose();
  }

  Future<void> _initAsync(String? initialToken) async {
    try {
      // 1. Load OnboardingState
      final state = await KeyValueStore.getModel<OnboardingState>(
        KeyValueKeys.onboardingState,
      );

      // The server has forgotten a link this old, so nothing can arrive
      // through it anymore.
      if (PasswordlessRecoveryService.isRecoverySessionExpired(state)) {
        await PasswordlessRecoveryService.resetRecoverySession(state);
        initialToken = null;
        _secondFactorController.clear();
      }

      if (initialToken != null && !state.emailRecoveryRequested) {
        state.emailRecoveryRequested = true;
        await KeyValueStore.update<OnboardingState>(
          key: KeyValueKeys.onboardingState,
          update: (s) => s.emailRecoveryRequested = true,
        );
      }

      // 2. Generate fields if they are missing
      if (state.notificationId == null) {
        state
          ..notificationId = uuid.v4()
          ..downloadAuthToken = getRandomUint8List(32)
          ..encryptionKey = getRandomUint8List(32)
          ..recoveryStartedAt = DateTime.now();
        await KeyValueStore.update<OnboardingState>(
          key: KeyValueKeys.onboardingState,
          update: (s) {
            s
              ..notificationId = state.notificationId
              ..downloadAuthToken = state.downloadAuthToken
              ..encryptionKey = state.encryptionKey
              ..recoveryStartedAt = state.recoveryStartedAt;
          },
        );
      } else if (state.recoveryStartedAt == null) {
        // Started before the app tracked the age. If the server already
        // purged it, the poll reports that and the session starts over.
        state.recoveryStartedAt = DateTime.now();
        await KeyValueStore.update<OnboardingState>(
          key: KeyValueKeys.onboardingState,
          update: (s) => s.recoveryStartedAt = state.recoveryStartedAt,
        );
      }

      // 3. Construct URL
      final keyBytes = state.encryptionKey!;
      final base64Key = base64Url.encode(keyBytes).replaceAll('=', '');
      _shareUrl = 'https://me.twonly.eu/r/#${state.notificationId}/$base64Key';
      if (!kReleaseMode) Log.info(_shareUrl);

      // 4. Check FCM Notification Settings
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      _notificationsEnabled =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      // 5. Register with the server if not registered yet
      if (!state.serverRegistered) {
        await _registerPasswordlessNotification(state);
      }

      _onboardingState = state;

      // 6. If already registered, do an immediate check and start the poll timer
      if (state.serverRegistered) _startPollTimer();

      unawaited(_analyzeShares());
    } catch (e) {
      Log.warn('Error during passwordless recovery initialization: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startPollTimer() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pollForMessages();
    });
    unawaited(_pollForMessages());
  }

  Future<void> _pollForMessages() async {
    final state = _onboardingState;
    if (state == null) return;
    final result = PasswordlessRecoveryService.isRecoverySessionExpired(state)
        ? RecoveryPollResult.expired
        : await PasswordlessRecoveryService.checkAndStorePasswordlessMessages(
            state,
          );
    if (!mounted) return;
    switch (result) {
      case RecoveryPollResult.expired:
        if (!_isRecovering) await _startOver(expired: true);
      case RecoveryPollResult.updated:
        // _onboardingState was changed in checkAndStorePasswordlessMessages
        setState(() => ());
        unawaited(_analyzeShares());
      case RecoveryPollResult.unchanged:
        break;
    }
  }

  /// Works out again what the received shares add up to. A call while one is
  /// running makes it run once more afterwards, so no new share is missed.
  Future<void> _analyzeShares() async {
    if (_isAnalyzing) {
      _analyzeAgain = true;
      return;
    }
    _isAnalyzing = true;
    try {
      do {
        _analyzeAgain = false;
        final state = _onboardingState;
        if (state == null) return;
        final analysis = await PasswordlessRecoveryService.analyzeShares(
          List.of(state.receivedShares),
          rejectedSecrets: _rejectedSecrets,
        );
        // Starting over replaced the session meanwhile.
        if (!identical(_onboardingState, state)) {
          _analyzeAgain = true;
          continue;
        }
        if (mounted) setState(() => _analysis = analysis);
      } while (_analyzeAgain && mounted);
    } finally {
      _isAnalyzing = false;
    }
  }

  Future<void> _confirmStartOver() async {
    final confirmed = await showAlertDialog(
      context,
      context.lang.passwordlessRecoveryStartOver,
      context.lang.passwordlessRecoveryStartOverBody,
      customOk: context.lang.passwordlessRecoveryStartOver,
    );
    if (confirmed) await _startOver();
  }

  /// Replaces the recovery link with a new one and forgets every share
  /// received through the old one.
  Future<void> _startOver({bool expired = false}) async {
    final state = _onboardingState;
    if (state == null) return;
    _pollTimer?.cancel();
    _pollTimer = null;
    await PasswordlessRecoveryService.resetRecoverySession(state);
    _rejectedSecrets.clear();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _onboardingState = null;
      _analysis = const RecoveryShareAnalysis();
      _secondFactorController.clear();
    });
    if (expired) {
      showSnackbar(context, context.lang.passwordlessRecoveryLinkExpired);
    }
    await _initAsync(null);
  }

  Future<void> _recoverNow() async {
    final analysis = _analysis;
    final reconstructed = analysis.secret;
    final account = analysis.account;
    if (reconstructed == null || account == null) return;

    setState(() {
      _isRecovering = true;
    });

    try {
      final userId = account.myUserId;
      Uint8List? serverKey;

      if (!reconstructed.hasEmailHint() &&
          reconstructed.hasServerKeyProtection()) {
        final pin = _secondFactorController.text.trim();
        if (pin.isEmpty) {
          showSnackbar(
            context,
            context.lang.passwordlessRecoveryEnterPin,
          );
          setState(() {
            _isRecovering = false;
          });
          return;
        }

        // Calculate pinProtectionKey via Hkdf
        final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
        final pinKey = await hkdf.deriveKey(
          secretKey: SecretKey(reconstructed.serverKeyProtection),
          nonce: utf8.encode(pin),
        );

        // Fetch serverKey
        final res = await rustApiResult(
          RustApi.getServerKeyForPasswordlessRecovery(
            userId: userId,
            serverKeyProtection: const [],
            pinUnlockToken: Uint8List.fromList(reconstructed.pinUnlockToken),
            pinProtectionKey: Uint8List.fromList(await pinKey.extractBytes()),
          ),
        );

        if (res.isError) {
          if (mounted) {
            showSnackbar(
              context,
              context.lang.passwordlessRecoveryTestPinIncorrect,
            );
          }
          setState(() {
            _isRecovering = false;
          });
          return;
        }

        serverKey = Uint8List.fromList(res.value!);
      } else if (reconstructed.hasEmailHint()) {
        final state = _onboardingState;
        if (state == null) return;

        if (!state.emailRecoveryRequested) {
          // Stage 1: Send Email
          final email = _secondFactorController.text.trim();
          if (email.isEmpty) {
            showSnackbar(
              context,
              context.lang.passwordlessRecoveryEnterEmail,
            );
            setState(() {
              _isRecovering = false;
            });
            return;
          }

          // Fetch serverKey (sends recovery email)
          final res = await rustApiResult(
            RustApi.getServerKeyForPasswordlessRecovery(
              userId: userId,
              email: email,
              serverKeyProtection: reconstructed.serverKeyProtection,
            ),
          );

          if (res.isError) {
            if (mounted) {
              final isInternalError = res.error == ErrorCode.InternalError;
              showSnackbar(
                context,
                isInternalError
                    ? context.lang.passwordlessRecoveryNetworkError
                    : context.lang.passwordlessRecoveryInvalidEmail,
              );
            }
            setState(() {
              _isRecovering = false;
            });
            return;
          }

          // Success - server sent recovery email. Store in state
          state.emailRecoveryRequested = true;
          await KeyValueStore.update<OnboardingState>(
            key: KeyValueKeys.onboardingState,
            update: (s) => s.emailRecoveryRequested = true,
          );

          _secondFactorController.clear();
          if (mounted) {
            showSnackbar(
              context,
              context.lang.passwordlessRecoveryEmailSent,
              level: SnackbarLevel.success,
            );
          }
          setState(() {
            _isRecovering = false;
          });
          return;
        } else {
          // Stage 2: Token verification
          final token = _secondFactorController.text.trim();
          if (token.isEmpty) {
            if (mounted) {
              showSnackbar(
                context,
                'Please enter the recovery token from your email.',
              );
            }
            setState(() {
              _isRecovering = false;
            });
            return;
          }

          try {
            serverKey = base64Url.decode(base64Url.normalize(token));
          } catch (e) {
            if (mounted) {
              showSnackbar(
                context,
                'Invalid verification token format.',
              );
            }
            setState(() {
              _isRecovering = false;
            });
            return;
          }
        }
      }

      // Decrypt recoveryData using serverKey if present
      List<int> recoveryDataBytes;
      if (serverKey != null) {
        final envelope = EncryptedEnvelope.fromBuffer(
          reconstructed.recoveryData,
        );
        final secretBox = SecretBox(
          envelope.encryptedData,
          nonce: envelope.iv,
          mac: Mac(envelope.mac),
        );
        final xchacha20 = Xchacha20.poly1305Aead();
        recoveryDataBytes = await xchacha20.decrypt(
          secretBox,
          secretKey: SecretKey(serverKey),
        );
      } else {
        recoveryDataBytes = reconstructed.recoveryData;
      }

      final recoveryData = RecoveryData.fromBuffer(recoveryDataBytes);
      final keyManager = Uint8List.fromList(recoveryData.keyManager);

      // Account and keys come from the helpers' shares. Before anything is
      // staged, the server confirms that the keys belong to that account.
      if (recoveryData.userId.toInt() != userId ||
          !await PasswordlessRecoveryService.recoveredKeysBelongTo(
            userId,
            keyManager,
          )) {
        Log.warn('Recovered keys do not belong to account $userId');
        _rejectedSecrets.add(analysis.secretId!);
        _secondFactorController.clear();
        unawaited(_analyzeShares());
        if (mounted) {
          showSnackbar(context, context.lang.passwordlessRecoveryWrongAccount);
        }
        return;
      }

      if (!mounted) return;

      // Start full passwordless recovery. The progress view reports every
      // step and restarts the app once the recovery succeeded.
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RecoveryProgressView(
            username: account.myDisplayName,
            steps: const [
              RecoveryProgress.restoringIdentity,
              RecoveryProgress.downloadingArchive,
              RecoveryProgress.extractingData,
            ],
            runRecovery: (onProgress) =>
                BackupService.startPasswordlessBackupRecovery(
                  userId,
                  account.myDisplayName,
                  keyManager,
                  onProgress: onProgress,
                ),
          ),
        ),
      );
    } catch (e) {
      Log.error('Failed to recover passwordless: $e');
      if (mounted) {
        showSnackbar(
          context,
          '${context.lang.recoverErrorUnknown}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRecovering = false;
        });
      }
    }
  }

  Future<void> _registerPasswordlessNotification(OnboardingState state) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (!mounted) return;
    final res = await rustApiResult(
      RustApi.registerPasswordlessNotification(
        notificationId: state.notificationId!,
        downloadAuthToken: state.downloadAuthToken!,
        langCode: Localizations.localeOf(context).languageCode,
        googleFcm: fcmToken,
      ),
    );
    if (res.isSuccess) {
      state.serverRegistered = true;
      await KeyValueStore.update<OnboardingState>(
        key: KeyValueKeys.onboardingState,
        update: (s) => s.serverRegistered = true,
      );
      _startPollTimer();
    }
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (mounted) setState(() => _notificationsEnabled = true);
        final state = _onboardingState;
        if (state != null) {
          await _registerPasswordlessNotification(state);
        }
      }
    } catch (e) {
      Log.error('Error requesting notification permission: $e');
    }
  }

  Widget _buildProgressSection(BuildContext context) {
    final analysis = _analysis;
    final first = analysis.account!;
    final shares = analysis.shares;
    final threshold = analysis.threshold;
    final thresholdReached = analysis.thresholdReached;
    final secret = analysis.secret;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              AvatarIcon(
                svg: first.myAvatarSvg != null
                    ? RustApi.decodeAvatarSvg(
                        avatarSvgCompressed: first.myAvatarSvg!,
                      )
                    : null,
                fontSize: 60,
              ),
              const SizedBox(height: 12),
              Text(
                first.myDisplayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.lang.recoverPasswordlessSharesReceived(
                shares.length,
                threshold,
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: (shares.length / threshold).clamp(0.0, 1.0),
            minHeight: 12,
            backgroundColor: context.color.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              thresholdReached
                  ? context.appColor(AppColor.success)
                  : context.color.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: shares.map((share) {
            return ContactChip(
              username: share.trustedFriendDisplayName,
              avatarSvg: share.trustedFriendAvatarSvg,
            );
          }).toList(),
        ),

        if (analysis.ignoredShares > 0) ...[
          const SizedBox(height: 12),
          Text(
            context.lang.recoverPasswordlessSharesIgnored(
              analysis.ignoredShares,
            ),
            style: TextStyle(
              fontSize: 13,
              color: context.color.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        const SizedBox(height: 24),

        if (secret == null && (thresholdReached || analysis.tooManyShares))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              analysis.tooManyShares
                  ? context.lang.recoverPasswordlessTooManyShares
                  : context.lang.recoverPasswordlessSharesDoNotFit,
              style: TextStyle(color: context.color.error),
              textAlign: TextAlign.center,
            ),
          )
        else if (secret != null) ...[
          if (secret.hasServerKeyProtection() && !secret.hasEmailHint()) ...[
            MyInput(
              controller: _secondFactorController,
              hintText: context.lang.passwordlessRecoveryMethodPinHint,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
          ] else if (secret.hasEmailHint()) ...[
            if (_onboardingState != null &&
                !_onboardingState!.emailRecoveryRequested) ...[
              MyInput(
                controller: _secondFactorController,
                hintText: secret.emailHint,
                prefixIcon: const Icon(Icons.email_rounded),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
            ] else ...[
              MyInput(
                controller: _secondFactorController,
                hintText: 'Enter recovery token',
                prefixIcon: const Icon(Icons.key_rounded),
              ),
              const SizedBox(height: 16),
            ],
          ],
          MyButton(
            onPressed: _isRecovering ? null : _recoverNow,
            child: _isRecovering
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: context.color.onPrimary,
                    ),
                  )
                : Text(
                    secret.hasEmailHint() &&
                            _onboardingState != null &&
                            !_onboardingState!.emailRecoveryRequested
                        ? 'Send recovery email'
                        : context.lang.recoverPasswordlessRecoverNowBtn,
                  ),
          ),
          const SizedBox(height: 16),
          if (secret.hasEmailHint() &&
              _onboardingState != null &&
              _onboardingState!.emailRecoveryRequested) ...[
            MyButton(
              onPressed: _isRecovering
                  ? null
                  : () async {
                      final state = _onboardingState;
                      if (state == null) return;
                      setState(() {
                        state.emailRecoveryRequested = false;
                        _secondFactorController.clear();
                      });
                      await KeyValueStore.update<OnboardingState>(
                        key: KeyValueKeys.onboardingState,
                        update: (s) => s.emailRecoveryRequested = false,
                      );
                    },
              variant: MyButtonVariant.secondary,
              child: Text(context.lang.passwordlessRecoveryResendEmail),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasShares = _analysis.account != null;
    // Friends still need the link until the shares rebuild the data.
    final needsMoreShares = _analysis.secret == null;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.lang.passwordlessRecoveryRecoverBtn),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: context.color.onSurfaceVariant,
            iconSize: 20,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.passwordlessRecoveryRecoverBtn),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: context.color.onSurfaceVariant,
          iconSize: 20,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_onboardingState?.notificationId != null)
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: context.lang.passwordlessRecoveryStartOver,
              onPressed: _isRecovering ? null : _confirmStartOver,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!hasShares) ...[
                Text(
                  context.lang.recoverPasswordlessExplanation,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
              ],

              if (hasShares) _buildProgressSection(context),

              if (!_notificationsEnabled && !hasShares) ...[
                Container(
                  decoration: BoxDecoration(
                    color: context.color.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.color.outlineVariant,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AnimatedBellIcon(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context
                                  .lang
                                  .recoverPasswordlessNotificationCardTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context
                                  .lang
                                  .recoverPasswordlessNotificationCardSubtitle,
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            MyButton(
                              variant: MyButtonVariant.secondaryDense,
                              onPressed: _requestNotificationPermission,
                              child: Text(
                                context
                                    .lang
                                    .recoverPasswordlessNotificationCardBtn,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              if (needsMoreShares) ...[
                if (!hasShares)
                  Container(
                    decoration: BoxDecoration(
                      color: context.color.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.color.outlineVariant,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: context.color.onSurfaceVariant,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.lang.recoverPasswordlessQrInstructions,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (!hasShares) const SizedBox(height: 20),

                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.appColor(AppColor.qrBackground),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: context.color.shadow.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: QrImageView.withQr(
                      qr: QrCode.fromData(
                        data: _shareUrl,
                        errorCorrectLevel: QrErrorCorrectLevel.M,
                      ),
                      eyeStyle: QrEyeStyle(
                        color: context.appColor(AppColor.qrForeground),
                        borderRadius: 4,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        color: context.appColor(AppColor.qrForeground),
                        borderRadius: 4,
                      ),
                      gapless: false,
                      size: 200,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                MyInput(
                  controller: TextEditingController(text: _shareUrl),
                  readOnly: true,
                  hintText: '',
                  prefixIcon: const Icon(Icons.link_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy_rounded),
                        tooltip: context.lang.recoverPasswordlessCopyBtn,
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: _shareUrl),
                          );
                          showSnackbar(
                            context,
                            context.lang.recoverPasswordlessCopiedSnackbar,
                            level: SnackbarLevel.success,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_rounded),
                        tooltip: context.lang.recoverPasswordlessShareBtn,
                        onPressed: () {
                          final params = ShareParams(
                            text: _shareUrl,
                          );
                          SharePlus.instance.share(params);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
