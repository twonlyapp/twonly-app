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
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
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
import 'package:twonly/src/visual/views/onboarding/components/onboarding_brand.comp.dart';
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
    // Without Play Services getToken throws and recovery could never register;
    // the server accepts a missing token and the view polls instead.
    final fcmToken = await FcmNotificationService.isAvailable()
        ? await FirebaseMessaging.instance.getToken()
        : null;
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

  bool get _emailRequested =>
      _onboardingState != null && _onboardingState!.emailRecoveryRequested;

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
    color: context.color.surfaceContainerLow,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(
      color: context.color.outlineVariant.withValues(alpha: 0.5),
    ),
  );

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: Row(
        children: [
          IconButton(
            // Lines the arrow up with the text below.
            padding: EdgeInsets.zero,
            alignment: AlignmentDirectional.centerStart,
            icon: const BackButtonIcon(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          if (!_isLoading && _onboardingState?.notificationId != null)
            IconButton(
              padding: EdgeInsets.zero,
              alignment: AlignmentDirectional.centerEnd,
              icon: const Icon(Icons.restart_alt_rounded),
              color: context.color.onSurfaceVariant,
              tooltip: context.lang.passwordlessRecoveryStartOver,
              onPressed: _isRecovering ? null : _confirmStartOver,
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.color.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.color.primary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: AnimatedBellIcon()),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.lang.recoverPasswordlessNotificationCardTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.color.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.lang.recoverPasswordlessNotificationCardSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: context.color.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                MyButton(
                  variant: MyButtonVariant.primaryDense,
                  onPressed: _requestNotificationPermission,
                  child: Text(
                    context.lang.recoverPasswordlessNotificationCardBtn,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The QR code and link friends open to send their share.
  Widget _buildShareSection(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.appColor(AppColor.qrBackground),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.color.outlineVariant.withValues(alpha: 0.5),
            ),
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
        const SizedBox(height: 14),
        ConstrainedBox(
          // Not wider than the QR code above it.
          constraints: const BoxConstraints(maxWidth: 240),
          child: Text(
            context.lang.recoverPasswordlessQrInstructions,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: context.color.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 20),
        MyButton(
          variant: MyButtonVariant.primaryMiddle,
          onPressed: () =>
              SharePlus.instance.share(ShareParams(text: _shareUrl)),
          child: _ButtonLabel(
            icon: Icons.ios_share_rounded,
            text: context.lang.recoverPasswordlessShareBtn,
          ),
        ),
      ],
    );
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AvatarIcon(
                    svg: first.myAvatarSvg != null
                        ? RustApi.decodeAvatarSvg(
                            avatarSvgCompressed: first.myAvatarSvg!,
                          )
                        : null,
                    fontSize: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          first.myDisplayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                            color: context.color.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.lang.recoverPasswordlessSharesReceived(
                            shares.length,
                            threshold,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: context.color.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (shares.length / threshold).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: context.color.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    thresholdReached
                        ? context.appColor(AppColor.success)
                        : context.color.primary,
                  ),
                ),
              ),
              if (shares.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: shares.map((share) {
                    return ContactChip(
                      username: share.trustedFriendDisplayName,
                      avatarSvg: share.trustedFriendAvatarSvg,
                    );
                  }).toList(),
                ),
              ],
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
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (secret == null && (thresholdReached || analysis.tooManyShares))
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.color.errorContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: context.color.onErrorContainer,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    analysis.tooManyShares
                        ? context.lang.recoverPasswordlessTooManyShares
                        : context.lang.recoverPasswordlessSharesDoNotFit,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: context.color.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (secret != null) ...[
          if (secret.hasServerKeyProtection() && !secret.hasEmailHint()) ...[
            MyInput(
              controller: _secondFactorController,
              hintText: context.lang.passwordlessRecoveryMethodPinHint,
              prefixIcon: const Icon(Icons.pin_outlined),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
          ] else if (secret.hasEmailHint()) ...[
            if (_onboardingState != null && !_emailRequested) ...[
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
                            !_emailRequested
                        ? 'Send recovery email'
                        : context.lang.recoverPasswordlessRecoverNowBtn,
                  ),
          ),
          if (secret.hasEmailHint() && _emailRequested) ...[
            const SizedBox(height: 12),
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
          ],
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasShares = _analysis.account != null;
    // Friends still need the link until the shares rebuild the data.
    final needsMoreShares = _analysis.secret == null;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            const OnboardingBackgroundGlow(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.lang.passwordlessRecoveryRecoverBtn,
                            style: TextStyle(
                              fontSize: 32,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: context.color.onSurface,
                            ),
                          ),
                          if (!hasShares) ...[
                            const SizedBox(height: 12),
                            Text(
                              context.lang.recoverPasswordlessExplanation,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                color: context.color.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.only(top: 60),
                              child: Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            )
                          else ...[
                            if (hasShares) _buildProgressSection(context),
                            if (!_notificationsEnabled && !hasShares) ...[
                              _buildNotificationCard(context),
                              const SizedBox(height: 16),
                            ],
                            if (needsMoreShares) _buildShareSection(context),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
