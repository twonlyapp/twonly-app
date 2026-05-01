import 'package:mutex/mutex.dart';

/// Unified lock for all Signal protocol operations (encryption, decryption, session management).
final lockingSignalProtocol = Mutex();

/// Tracking users who have already been resynced in the current session.
final resyncedUsers = <int>{};

/// Reset the resync tracking set.
void resetResyncedUsers() {
  resyncedUsers.clear();
}
