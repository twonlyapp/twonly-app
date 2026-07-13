import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/utils/exclusive_access.utils.dart';
import 'package:twonly/src/utils/log.dart';

typedef ModelFactory = ({
  Object Function(Map<String, dynamic> json) fromJson,
  Map<String, dynamic> Function(Object value) toJson,
  Object Function() defaultValue,
});

class KeyValueStore {
  static final Map<Type, ModelFactory> _registry = {
    OnboardingState: (
      fromJson: OnboardingState.fromJson,
      toJson: (val) => (val as OnboardingState).toJson(),
      defaultValue: OnboardingState.new,
    ),
    CurrentBackupStatus: (
      fromJson: CurrentBackupStatus.fromJson,
      toJson: (val) => (val as CurrentBackupStatus).toJson(),
      defaultValue: CurrentBackupStatus.new,
    ),
    BackupRecovery: (
      fromJson: BackupRecovery.fromJson,
      toJson: (val) => (val as BackupRecovery).toJson(),
      defaultValue: () => BackupRecovery(username: '', password: '', userId: 0),
    ),
  };

  static final Map<String, Mutex> _mutexes = {};

  static Mutex _getMutex(String key) {
    return _mutexes.putIfAbsent(key, Mutex.new);
  }

  static Future<File> _getFilePath(String key) async {
    return File('${AppEnvironment.supportDir}/keyvalue/$key.json');
  }

  static Future<T> _exclusive<T>(String key, Future<T> Function() action) {
    return exclusiveAccess(
      lockName: 'keyvalue-$key',
      mutex: _getMutex(key),
      action: action,
    );
  }

  static Future<void> delete(String key) => _exclusive(key, () async {
    try {
      final file = await _getFilePath(key);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      Log.error('Error deleting file: $e');
    }
  });

  static Future<Map<String, dynamic>?> get(String key) async {
    return _exclusive(key, () async {
      final file = await _getFilePath(key);
      try {
        if (file.existsSync()) {
          final contents = await file.readAsString();
          return jsonDecode(contents) as Map<String, dynamic>;
        } else {
          return null;
        }
      } catch (e) {
        Log.warn('Error reading file. Deleting it.: $e');
        file.deleteSync();
        return null;
      }
    });
  }

  static Future<void> put(String key, Map<String, dynamic> value) async {
    return _exclusive(key, () async {
      try {
        final file = await _getFilePath(key);
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(value));
      } catch (e) {
        Log.error('Error writing file: $e');
      }
    });
  }

  static Future<T> update<T>({
    required String key,
    required FutureOr<void> Function(T value) update,
  }) async {
    final factory = _registry[T];
    if (factory == null) {
      throw ArgumentError('Type $T is not registered in KeyValueStore.');
    }
    return _exclusive(key, () async {
      T val;
      final file = await _getFilePath(key);
      try {
        if (file.existsSync()) {
          final contents = await file.readAsString();
          val = factory.fromJson(jsonDecode(contents) as Map<String, dynamic>) as T;
        } else {
          val = factory.defaultValue() as T;
        }
      } catch (e) {
        Log.warn('Error reading file. Resetting to default.: $e');
        val = factory.defaultValue() as T;
      }

      await update(val);

      try {
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(factory.toJson(val as Object)));
      } catch (e) {
        Log.error('Error writing file: $e');
      }
      return val;
    });
  }

  static Future<T> getModel<T>(String key) async {
    final factory = _registry[T];
    if (factory == null) {
      throw ArgumentError('Type $T is not registered in KeyValueStore.');
    }
    return _exclusive(key, () async {
      final file = await _getFilePath(key);
      try {
        if (file.existsSync()) {
          final contents = await file.readAsString();
          return factory.fromJson(jsonDecode(contents) as Map<String, dynamic>) as T;
        }
      } catch (e) {
        Log.warn('Error reading file. Returning default.: $e');
      }
      return factory.defaultValue() as T;
    });
  }

  static Future<T?> getModelOrNull<T>(String key) async {
    final factory = _registry[T];
    if (factory == null) {
      throw ArgumentError('Type $T is not registered in KeyValueStore.');
    }
    return _exclusive(key, () async {
      final file = await _getFilePath(key);
      try {
        if (file.existsSync()) {
          final contents = await file.readAsString();
          return factory.fromJson(jsonDecode(contents) as Map<String, dynamic>) as T;
        }
      } catch (e) {
        Log.warn('Error reading file.: $e');
      }
      return null;
    });
  }
}
