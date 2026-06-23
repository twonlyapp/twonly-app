import 'dart:async';
import 'dart:convert';

import 'package:cryptography_plus/cryptography_plus.dart'
    show Hmac, Mac, SecretBox, SecretKey, Xchacha20;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hashlib/random.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:restart_app/restart_app.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twonly/core/bridge/wrapper.dart' show RustUtils;
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/model/protobuf/client/generated/passwordless_recovery.pb.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/views/onboarding/components/animated_bell_icon.comp.dart';

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

  SharedSecretData? _reconstructedSecret;
  bool _isReconstructing = false;
  String? _reconstructionError;

  bool _isRecovering = false;
  final TextEditingController _secondFactorController = TextEditingController();

  StreamSubscription<String>? _emailTokenSubscription;

  @override
  void initState() {
    super.initState();
    _secondFactorController.text = widget.initialEmailToken ?? '';
    _emailTokenSubscription = PasswordlessRecoveryService
        .onEmailTokenReceived
        .stream
        .listen((token) async {
          if (mounted) {
            final state = _onboardingState;
            if (state != null && !state.emailRecoveryRequested) {
              state.emailRecoveryRequested = true;
              await KeyValueStore.update<OnboardingState>(
                key: KeyValueKeys.onboardingState,
                update: (s) => s.emailRecoveryRequested = true,
              );
            }
            setState(() {
              _secondFactorController.text = token;
            });
          }
        });
    _initAsync();
  }

  @override
  void dispose() {
    _emailTokenSubscription?.cancel();
    _pollTimer?.cancel();
    _secondFactorController.dispose();
    super.dispose();
  }

  Future<void> _initAsync() async {
    try {
      // 1. Load OnboardingState
      final state = await KeyValueStore.getModel<OnboardingState>(
        KeyValueKeys.onboardingState,
      );

      if (widget.initialEmailToken != null && !state.emailRecoveryRequested) {
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
          ..encryptionKey = getRandomUint8List(32);
        await KeyValueStore.update<OnboardingState>(
          key: KeyValueKeys.onboardingState,
          update: (s) {
            s
              ..notificationId = state.notificationId
              ..downloadAuthToken = state.downloadAuthToken
              ..encryptionKey = state.encryptionKey;
          },
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

      _checkAndReconstruct();
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
    if (_onboardingState == null) return;
    final didUpdate =
        await PasswordlessRecoveryService.checkAndStorePasswordlessMessages(
          _onboardingState!,
        );
    // _onboardingState was changed in checkAndStorePasswordlessMessages
    if (didUpdate && mounted) {
      setState(() => ());
      _checkAndReconstruct();
    }
  }

  void _checkAndReconstruct() {
    final state = _onboardingState;
    if (state != null) {
      final shares = state.receivedShares;
      if (shares.isNotEmpty) {
        final threshold = shares.first.threshold;
        if (shares.length >= threshold &&
            _reconstructedSecret == null &&
            !_isReconstructing) {
          unawaited(_reconstructSecret());
        }
      }
    }
  }

  Future<void> _reconstructSecret() async {
    final state = _onboardingState;
    if (state == null) return;
    final shares = state.receivedShares;
    if (shares.isEmpty) return;
    final threshold = shares.first.threshold;
    if (shares.length < threshold) return;

    setState(() {
      _isReconstructing = true;
      _reconstructionError = null;
    });

    try {
      final shareBytesList = shares
          .map((s) => Uint8List.fromList(s.sharedSecretDataBytes))
          .toList();
      final secretBytes = await RustUtils.recoverSecret(
        shares: shareBytesList,
        threshold: threshold,
      );
      final sharedSecretData = SharedSecretData.fromBuffer(secretBytes);
      if (mounted) {
        setState(() {
          _reconstructedSecret = sharedSecretData;
        });
      }
    } catch (e) {
      Log.error('Failed to reconstruct secret: $e');
      if (mounted) {
        setState(() {
          _reconstructionError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReconstructing = false;
        });
      }
    }
  }

  Future<void> _recoverNow(List<ReceivedRecoveryShare> shares) async {
    final reconstructed = _reconstructedSecret;
    if (reconstructed == null) return;

    setState(() {
      _isRecovering = true;
    });

    try {
      final userId = shares.first.myUserId;
      Uint8List? serverKey;

      if (reconstructed.hasPinSeed()) {
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

        // Calculate pinProtectionKey
        final pinProtectionKey = await Hmac.sha256().calculateMac(
          Uint8List.fromList(utf8.encode(pin)),
          secretKey: SecretKey(reconstructed.pinSeed),
        );

        // Fetch serverKey
        final res = await apiService.getServerKeyForPasswordlessRecovery(
          userId: userId,
          pinUnlockToken: reconstructed.pinUnlockToken,
          pinProtectionKey: pinProtectionKey.bytes,
          encryptedServerKeyNone: reconstructed.encryptedServerKeyNonce,
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

        final ok = res.value as server.Response_Ok;
        serverKey = Uint8List.fromList(ok.passwordlessRecoveryServerKey);
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
          final res = await apiService.getServerKeyForPasswordlessRecovery(
            userId: userId,
            email: email,
            encryptedServerKeyNone: reconstructed.encryptedServerKeyNonce,
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
              context.lang.passwordlessRecoveryShareSent,
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

      // Start full passwordless recovery
      final error = await BackupService.startPasswordlessBackupRecovery(
        recoveryData.userId.toInt(),
        shares.first.myDisplayName,
        Uint8List.fromList(recoveryData.keyManager),
      );

      if (!mounted) return;

      if (error != null) {
        showSnackbar(
          context,
          error.toLocalizedString(context),
        );
        setState(() {
          _isRecovering = false;
        });
        return;
      }

      // Successful! Restart the app to apply restored keymanager/archive database
      await Restart.restartApp(
        notificationTitle: context.lang.recoverSuccessTitle,
        notificationBody: context.lang.recoverSuccessBody,
        forceKill: true,
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
    final res = await apiService.registerPasswordlessNotification(
      notificationId: state.notificationId!,
      downloadAuthToken: state.downloadAuthToken!,
      langCode: Localizations.localeOf(context).languageCode,
      googleFcm: fcmToken,
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

  Widget _buildProgressSection(
    BuildContext context,
    bool isDark,
    List<ReceivedRecoveryShare> shares,
  ) {
    final first = shares.first;
    final threshold = first.threshold;
    final thresholdReached = shares.length >= threshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Column(
            children: [
              AvatarIcon(
                svg: utf8.decode(first.myAvatarSvg ?? []),
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
          children: [
            Text(
              context.lang.recoverPasswordlessSharesReceived(
                shares.length,
                threshold,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            if (thresholdReached)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 20,
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: shares.length / threshold,
            minHeight: 8,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              thresholdReached ? Colors.green : context.color.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        ...shares.map(
          (share) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              share.trustedFriendDisplayName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),

        const SizedBox(height: 24),

        if (thresholdReached) ...[
          if (_isReconstructing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_reconstructionError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Reconstruction failed: $_reconstructionError',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          else if (_reconstructedSecret != null) ...[
            if (_reconstructedSecret!.hasPinSeed()) ...[
              MyInput(
                controller: _secondFactorController,
                hintText: context.lang.passwordlessRecoveryMethodPinHint,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ] else if (_reconstructedSecret!.hasEmailHint()) ...[
              if (_onboardingState != null &&
                  !_onboardingState!.emailRecoveryRequested) ...[
                MyInput(
                  controller: _secondFactorController,
                  hintText: _reconstructedSecret!.emailHint,
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
              onPressed: _isRecovering ? null : () => _recoverNow(shares),
              child: _isRecovering
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black87,
                      ),
                    )
                  : Text(
                      _reconstructedSecret!.hasEmailHint() &&
                              _onboardingState != null &&
                              !_onboardingState!.emailRecoveryRequested
                          ? 'Send recovery email'
                          : context.lang.recoverPasswordlessRecoverNowBtn,
                    ),
            ),
            const SizedBox(height: 16),
            if (_reconstructedSecret!.hasEmailHint() &&
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);
    final shares = _onboardingState?.receivedShares ?? [];
    final hasShares = shares.isNotEmpty;
    final threshold = hasShares ? shares.first.threshold : 0;
    final thresholdReached = hasShares && shares.length >= threshold;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.lang.passwordlessRecoveryRecoverBtn),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: isDark ? Colors.white70 : Colors.black54,
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
          color: isDark ? Colors.white70 : Colors.black54,
          iconSize: 20,
          onPressed: () => Navigator.of(context).pop(),
        ),
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

              if (hasShares) _buildProgressSection(context, isDark, shares),

              if (!_notificationsEnabled && !hasShares) ...[
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
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

              if (!thresholdReached) ...[
                if (!hasShares)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark ? Colors.white70 : Colors.black54,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.08,
                          ),
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
                      eyeStyle: const QrEyeStyle(
                        color: Colors.black,
                        borderRadius: 4,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        color: Colors.black,
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
