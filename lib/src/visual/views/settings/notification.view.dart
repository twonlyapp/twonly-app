import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  bool _isLoadingReset = false;
  bool? _hasNotificationPermission;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final isGranted = await Permission.notification.isGranted;
    if (mounted) {
      setState(() {
        _hasNotificationPermission = isGranted;
      });
    }
  }

  Future<void> _resetTokens() async {
    setState(() {
      _isLoadingReset = true;
    });
    await FcmNotificationService.resetFCMTokens();
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
          if (_hasNotificationPermission == false)
            ListTile(
              title: Text(context.lang.settingsNotifyPermission),
              subtitle: Text(context.lang.settingsNotifyPermissionDesc),
              onTap: openAppSettings,
            ),
          if (_hasNotificationPermission == true)
            ListTile(
              title: Text(context.lang.settingsNotifyResetTitle),
              subtitle: Text(context.lang.settingsNotifyResetTitleSubtitle),
              trailing: _isLoadingReset
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                      ),
                    )
                  : null,
              onTap: _isLoadingReset ? null : _resetTokens,
            ),
        ],
      ),
    );
  }
}
