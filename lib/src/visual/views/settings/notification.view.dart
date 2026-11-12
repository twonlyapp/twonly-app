import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/services/notifications/periodic_poll.service.dart';
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
  PeriodicPollStatus? _periodicPoll;
  bool _isUpdatingPoll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _refreshPeriodicPoll();
    FcmNotificationService.isAvailable().then((available) {
      if (mounted && _periodicPoll == null) {
        setState(() => _fcmAvailable = available);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
      _refreshPeriodicPoll();
    }
  }

  Future<void> _refreshPeriodicPoll() async {
    try {
      final status = await PeriodicPollService.getStatus();
      if (mounted) {
        setState(() {
          _periodicPoll = status;
          if (status != null) _fcmAvailable = status.hasPlayServices;
        });
      }
    } catch (error, stackTrace) {
      Log.warn('Could not load periodic message checks.', error, stackTrace);
    }
  }

  Future<void> _togglePeriodicPoll(bool enabled) async {
    final status = _periodicPoll;
    if (status == null || _isUpdatingPoll) return;
    setState(() => _isUpdatingPoll = true);
    try {
      if (enabled) {
        final confirmed = await showAlertDialog(
          context,
          context.lang.settingsNotifyPollTitle,
          context.lang.settingsNotifyPollWarning(status.intervalMinutes),
          customOk: context.lang.enable,
          scrollable: true,
        );
        if (!confirmed || !mounted) return;
      }
      final updated = await PeriodicPollService.setEnabled(enabled);
      if (!mounted) return;
      if (updated == null) throw StateError('Periodic checks unavailable');
      setState(() => _periodicPoll = updated);
      if (enabled && !updated.ignoringBatteryOptimizations) {
        await _showBatteryHelp();
      }
    } catch (error, stackTrace) {
      Log.warn('Could not update periodic message checks.', error, stackTrace);
      if (mounted) showSnackbar(context, context.lang.recoverErrorUnknown);
      await _refreshPeriodicPoll();
    } finally {
      if (mounted) setState(() => _isUpdatingPoll = false);
    }
  }

  Future<void> _showBatteryHelp() async {
    final open = await showAlertDialog(
      context,
      context.lang.settingsNotifyPollBatteryTitle,
      context.lang.settingsNotifyPollBatteryHelp,
      customOk: context.lang.settingsNotifyPollOpenSettings,
      customCancel: context.lang.settingsNotifyPollLater,
      scrollable: true,
    );
    if (!open || !mounted) return;
    try {
      await PeriodicPollService.openBatterySettings();
    } catch (error, stackTrace) {
      Log.warn('Could not open battery settings.', error, stackTrace);
      if (mounted) showSnackbar(context, context.lang.recoverErrorUnknown);
    }
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
    final poll = _periodicPoll;
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
          if (poll != null && poll.showSettings) ...[
            const SettingsDivider(),
            SwitchListTile.adaptive(
              title: Text(lang.settingsNotifyPollTitle),
              subtitle: Text(
                lang.settingsNotifyPollSubtitle(poll.intervalMinutes),
              ),
              value: poll.enabled,
              onChanged: _isUpdatingPoll ? null : _togglePeriodicPoll,
            ),
            if (poll.enabled) ...[
              ListTile(
                leading: Icon(
                  poll.ignoringBatteryOptimizations
                      ? Icons.battery_full_outlined
                      : Icons.battery_alert_outlined,
                ),
                title: Text(
                  poll.ignoringBatteryOptimizations
                      ? lang.settingsNotifyPollBatteryDisabled
                      : lang.settingsNotifyPollBatteryActive,
                ),
                subtitle: Text(lang.settingsNotifyPollBatteryHelp),
                trailing: const Icon(Icons.open_in_new),
                onTap: _showBatteryHelp,
              ),
              if (poll.backgroundRestricted)
                ListTile(
                  leading: const Icon(Icons.warning_amber_outlined),
                  title: Text(lang.settingsNotifyPollRestrictedTitle),
                  subtitle: Text(lang.settingsNotifyPollRestrictedHelp),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: openAppSettings,
                ),
            ],
          ],
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
