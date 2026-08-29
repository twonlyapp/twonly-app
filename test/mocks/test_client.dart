import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:twonly/core/bridge/api.dart';
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/pow.dart';

import 'user_config.dart';
import 'user_environment.dart';

class RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) {
        return true;
      };
  }
}

class TestClient {
  TestClient(this.localIdSeed) {
    final timeStr = DateTime.now().millisecondsSinceEpoch.toString();
    username = 't_${timeStr.substring(timeStr.length - 6)}$localIdSeed';
  }

  late final UserEnvironment env;
  late final ApiService api;
  final int localIdSeed;
  late String username;
  int realUserId = 0;

  Future<void> init({bool disablePqc = false}) async {
    env = await UserEnvironment.create(localIdSeed, username);
    if (disablePqc) {
      env.userService.currentUser.signalLastPqcPreKeysUploaded = DateTime.now()
          .add(const Duration(days: 365));
    }
    api = ApiService();

    await run(() async {
      Log.info('Requesting POW...');
      final FrbProofOfWork pow;
      try {
        pow = await RustApi.getProofOfWork();
      } catch (e, st) {
        if (kDebugMode) {
          print('POW EXCEPTION: $e\n$st');
        }
        rethrow;
      }
      Log.info('POW result: $pow');

      final proof = await calculatePoW(pow.prefix, pow.difficulty);

      realUserId = await RustApi.register(
        username: username,
        proofOfWork: proof,
        langCode: 'en',
        isIos: false,
      );

      final userData = testUserConfig(
        userId: realUserId,
        username: username,
        displayName: username,
        subscriptionPlan: 'Free',
        currentSetupPage: null,
        appVersion: 100,
      );
      await UserService.save(userData);
    });
  }

  Future<T> run<T>(Future<T> Function() computation) {
    return runInZone(env, api, computation);
  }
}
