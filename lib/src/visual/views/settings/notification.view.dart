import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/views/settings/components/settings_layout.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView>
    with WidgetsBindingObserver {
  bool _isLoadingReset = false;
  bool? _hasNotificationPermission;
  // Resetting rotates the FCM token, which cannot exist without Play Services.
  bool _fcmAvailable = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    FcmNotificationService.isAvailable().then((available) {
      if (mounted) setState(() => _fcmAvailable = available);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final isGranted = await Permission.notification.isGranted;
    if (mounted) setState(() => _hasNotificationPermission = isGranted);
  }

  Future<void> _toggleStoryNotifications() async {
    await UserService.update(
      (user) => user.storyNotifications = !user.storyNotifications,
    );
    if (mounted) setState(() {});
  }

  Future<void> _resetTokens() async {
    setState(() => _isLoadingReset = true);
    try {
      await FcmNotificationService.resetFCMTokens();
      if (!mounted) return;
      await showAlertDialog(
        context,
        context.lang.settingsNotifyResetTitleReset,
        context.lang.settingsNotifyResetTitleResetDesc,
      );
    } catch (error, stackTrace) {
      Log.warn('Could not reset notification registration.', error, stackTrace);
      if (mounted) showSnackbar(context, context.lang.recoverErrorUnknown);
    } finally {
      if (mounted) setState(() => _isLoadingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    return Scaffold(
      appBar: AppBar(title: Text(lang.settingsNotification)),
      body: SettingsList(
        children: [
          if (_hasNotificationPermission == false) ...[
            ListTile(
              leading: const Icon(Icons.notifications_off_outlined),
              title: Text(lang.settingsNotificationsDisabled),
              subtitle: Text(lang.settingsNotifyPermissionDesc),
              trailing: const Icon(Icons.open_in_new),
              onTap: openAppSettings,
            ),
            const SettingsDivider(),
          ],
          SwitchListTile.adaptive(
            title: Text(lang.settingsNotifyStories),
            subtitle: Text(lang.settingsNotifyStoriesSubtitle),
            value: userService.currentUser.storyNotifications,
            onChanged: (_) => _toggleStoryNotifications(),
          ),
          if (_fcmAvailable)
            ListTile(
              title: Text(lang.settingsNotifyResetTitle),
              subtitle: Text(
                _hasNotificationPermission == false
                    ? lang.settingsNotificationsDisabledHelp
                    : lang.settingsNotifyResetTitleSubtitle,
              ),
              trailing: _isLoadingReset
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator.adaptive(
                        strokeWidth: 2,
                      ),
                    )
                  : null,
              onTap: switch (_hasNotificationPermission) {
                true => _isLoadingReset ? null : _resetTokens,
                false => openAppSettings,
                null => null,
              },
            ),
        ],
      ),
    );
  }
}
