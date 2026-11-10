import 'package:flutter/material.dart';
import 'package:twonly/core/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/location_metadata.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

/// Flips a setting that records the location. Switching it on first asks for
/// precise location access and leaves the setting off when it is not granted.
Future<void> toggleLocationSetting(
  BuildContext context, {
  required bool Function(UserConfig user) enabled,
  required void Function(UserConfig user, bool value) set,
}) async {
  void showDenied() {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.lang.memoryLocationPermissionDenied)),
    );
  }

  final currentlyEnabled = enabled(userService.currentUser);
  try {
    if (!currentlyEnabled &&
        !await LocationMetadataService.requestPrecisePermission()) {
      showDenied();
      return;
    }
    await UserService.update((user) => set(user, !currentlyEnabled));
  } catch (error, stackTrace) {
    Log.error(
      'Could not update a location setting',
      error: error,
      stackTrace: stackTrace,
    );
    showDenied();
  }
}
