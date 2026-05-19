import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/userdata.model.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';

base class ZoneIOOverrides extends IOOverrides {
  @override
  File createFile(String path) {
    final userId = Zone.current[#userId] as int?;
    if (userId != null) {
      final newPath = _rewritePath(path, userId);
      return super.createFile(newPath);
    }
    return super.createFile(path);
  }

  @override
  Directory createDirectory(String path) {
    final userId = Zone.current[#userId] as int?;
    if (userId != null) {
      final newPath = _rewritePath(path, userId);
      return super.createDirectory(newPath);
    }
    return super.createDirectory(path);
  }

  String _rewritePath(String path, int userId) {
    if (path.contains('/user_$userId') || path.contains('/$userId')) {
      return path;
    }
    if (path.contains('/keyvalue/')) {
      return path.replaceFirst('/keyvalue/', '/keyvalue/user_$userId/');
    }
    return path;
  }
}

Future<T> runInZone<T>(
  UserEnvironment env,
  ApiService api,
  Future<T> Function() computation,
) {
  return IOOverrides.runWithIOOverrides(
    () => runZoned(
      computation,
      zoneValues: {
        #twonlyDB: env.db,
        #userService: env.userService,
        #apiService: api,
        #userId: env.userId,
      },
    ),
    ZoneIOOverrides(),
  );
}

class UserEnvironment {
  UserEnvironment({
    required this.userId,
    required this.username,
    required this.db,
    required this.userService,
    required this.identityKeyPair,
    required this.registrationId,
  });
  final int userId;
  final String username;
  final TwonlyDB db;
  final UserService userService;
  final IdentityKeyPair identityKeyPair;
  final int registrationId;

  static Future<UserEnvironment> create(
    int userId,
    String username,
  ) async {
    final db = TwonlyDB.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );

    final us = UserService();
    // ignore: cascade_invocations
    us.currentUser = UserData(
      userId: userId,
      username: username,
      displayName: '$username Display',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
    )..appVersion = 100;

    // ignore: cascade_invocations
    us.isUserCreated = true;

    final identityKeyPair = generateIdentityKeyPair();
    final registrationId = generateRegistrationId(true);

    // Save to keyvalue store using zone so it is isolated per-user
    await runZoned(
      () => KeyValueStore.put('user', us.currentUser.toJson()),
      zoneValues: {
        #userId: userId,
      },
    );

    return UserEnvironment(
      userId: userId,
      username: username,
      db: db,
      userService: us,
      identityKeyPair: identityKeyPair,
      registrationId: registrationId,
    );
  }
}
