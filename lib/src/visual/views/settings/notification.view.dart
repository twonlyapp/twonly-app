import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/model/protobuf/client/generated/push_notification.pb.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/secure_storage.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  bool _isLoadingTroubleshooting = false;
  bool _isLoadingReset = false;
  bool _troubleshootingDidRun = false;

  Future<void> _troubleshooting() async {
    setState(() {
      _isLoadingTroubleshooting = true;
    });

    await initFCMAfterAuthenticated(force: true);

    final storedToken = await SecureStorage.instance.read(
      key: SecureStorageKeys.googleFcm,
    );

    await setupNotificationWithUsers(force: true);

    if (!mounted) return;

    if (storedToken == null) {
      final platform = Platform.isAndroid ? "Google's" : "Apple's";
      await showAlertDialog(
        context,
        'Problem detected',
        'twonly is not able to register your app to $platform push server infrastructure. For Android that can happen when you do not have the Google Play Services installed. If you theses installed and want to help us to fix the issue please send us your debug log in Settings > Help > Debug log.',
      );
    } else {
      final run = await showAlertDialog(
        context,
        context.lang.settingsNotifyTroubleshootingNoProblem,
        context.lang.settingsNotifyTroubleshootingNoProblemDesc,
      );

      if (run) {
        final user = await getUser();
        if (user != null) {
          final pushData = await encryptPushNotification(
            user.userId,
            PushNotification(
              messageId: uuid.v4(),
              kind: PushKind.TEST_NOTIFICATION,
            ),
          );
          await apiService.sendTextMessage(
            user.userId,
            Uint8List(0),
            pushData,
          );
        }
        _troubleshootingDidRun = true;
      }
    }
    setState(() {
      _isLoadingTroubleshooting = false;
    });
  }

  Future<void> resetTokens() async {
    setState(() {
      _isLoadingReset = true;
    });
    await resetFCMTokens();
    if (!mounted) return;
    await showAlertDialog(
      context,
      context.lang.settingsNotifyResetTitleReset,
      context.lang.settingsNotifyResetTitleResetDesc,
    );
    setState(() {
      _isLoadingReset = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsNotification),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.lang.settingsNotifyTroubleshooting),
            subtitle: Text(context.lang.settingsNotifyTroubleshootingDesc),
            trailing: _isLoadingTroubleshooting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : null,
            onTap: _isLoadingTroubleshooting ? null : _troubleshooting,
          ),
          if (_troubleshootingDidRun)
            ListTile(
              title: Text(context.lang.settingsNotifyResetTitle),
              subtitle: Text(context.lang.settingsNotifyResetTitleSubtitle),
              trailing: _isLoadingReset
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : null,
              onTap: _isLoadingReset ? null : resetTokens,
            ),
        ],
      ),
    );
  }
}
