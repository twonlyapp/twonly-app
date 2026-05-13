import 'package:json_annotation/json_annotation.dart';
part 'backup.model.g.dart';

enum LastBackupUploadState { none, pending, failed, success }

@JsonSerializable()
class CurrentBackupStatus {
  CurrentBackupStatus();
  factory CurrentBackupStatus.fromJson(Map<String, dynamic> json) =>
      _$CurrentBackupStatusFromJson(json);

  LastBackupUploadState identityState = LastBackupUploadState.none;
  DateTime? identityLastSuccessFull;
  int? identitySize;

  LastBackupUploadState archiveState = LastBackupUploadState.none;

  DateTime? archiveLastSuccessFull;
  int? archiveSize;

  Map<String, dynamic> toJson() => _$CurrentBackupStatusToJson(this);
}

enum BackupRecoveryState {
  // The userId was loaded from the server and the user is asked to enter his password.
  identityBackupStarted,
  // -> Download identity, replace keymanager

  // Identity was downloaded and Keymanager was updated
  archiveBackupStarted,
  // -> Download archive, replace files, restart app
}

@JsonSerializable()
class BackupRecovery {
  BackupRecovery({
    required this.username,
    required this.password,
    required this.userId,
  });

  factory BackupRecovery.fromJson(Map<String, dynamic> json) =>
      _$BackupRecoveryFromJson(json);

  String username;
  String password;
  int userId;
  BackupRecoveryState state = BackupRecoveryState.identityBackupStarted;

  Map<String, dynamic> toJson() => _$BackupRecoveryToJson(this);
}
