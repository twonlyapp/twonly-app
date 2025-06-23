import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pbserver.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/services/fcm.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

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
            onLongPress: (kDebugMode)
                ? () async {
                    await twonlyDB.messageRetransmissionDao
                        .resetAckStatusForAllMessages(537506372);
                    tryTransmitMessages();
                  }
                : null,
            onTap: () async {
              await initFCMAfterAuthenticated();
              String? storedToken = await FlutterSecureStorage()
                  .read(key: SecureStorageKeys.googleFcm);
              await setupNotificationWithUsers(force: true);
              if (!context.mounted) return;

              if (storedToken == null) {
                final platform = Platform.isAndroid ? "Google's" : "Apple's";
                showAlertDialog(
                  context,
                  "Problem detected",
                  "twonly is not able to register your app to $platform push server infrastructure. For Android that can happen when you do not have the Google Play Services installed. If you theses installed and want to help us to fix the issue please send us your debug log in Settings > Help > Debug log.",
                );
              } else {
                final run = await showAlertDialog(
                    context,
                    context.lang.settingsNotifyTroubleshootingNoProblem,
                    context.lang.settingsNotifyTroubleshootingNoProblemDesc);

                if (run) {
                  final user = await getUser();
                  if (user != null) {
                    final pushData = await getPushData(
                      user.userId,
                      PushNotification(
                        messageId: Int64(0),
                        kind: PushKind.testNotification,
                      ),
                    );
                    await apiService.sendTextMessage(
                      user.userId,
                      Uint8List(0),
                      pushData,
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
