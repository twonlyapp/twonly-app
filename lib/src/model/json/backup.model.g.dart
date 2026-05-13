// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CurrentBackupStatus _$CurrentBackupStatusFromJson(Map<String, dynamic> json) =>
    CurrentBackupStatus()
      ..identityState = $enumDecode(
        _$LastBackupUploadStateEnumMap,
        json['identityState'],
      )
      ..identityLastSuccessFull = json['identityLastSuccessFull'] == null
          ? null
          : DateTime.parse(json['identityLastSuccessFull'] as String)
      ..identitySize = (json['identitySize'] as num?)?.toInt()
      ..archiveState = $enumDecode(
        _$LastBackupUploadStateEnumMap,
        json['archiveState'],
      )
      ..archiveLastSuccessFull = json['archiveLastSuccessFull'] == null
          ? null
          : DateTime.parse(json['archiveLastSuccessFull'] as String)
      ..archiveSize = (json['archiveSize'] as num?)?.toInt();

Map<String, dynamic> _$CurrentBackupStatusToJson(
  CurrentBackupStatus instance,
) => <String, dynamic>{
  'identityState': _$LastBackupUploadStateEnumMap[instance.identityState]!,
  'identityLastSuccessFull': instance.identityLastSuccessFull
      ?.toIso8601String(),
  'identitySize': instance.identitySize,
  'archiveState': _$LastBackupUploadStateEnumMap[instance.archiveState]!,
  'archiveLastSuccessFull': instance.archiveLastSuccessFull?.toIso8601String(),
  'archiveSize': instance.archiveSize,
};

const _$LastBackupUploadStateEnumMap = {
  LastBackupUploadState.none: 'none',
  LastBackupUploadState.pending: 'pending',
  LastBackupUploadState.failed: 'failed',
  LastBackupUploadState.success: 'success',
};

BackupRecovery _$BackupRecoveryFromJson(Map<String, dynamic> json) =>
    BackupRecovery(
      username: json['username'] as String,
      password: json['password'] as String,
      userId: (json['userId'] as num).toInt(),
    )..state = $enumDecode(_$BackupRecoveryStateEnumMap, json['state']);

Map<String, dynamic> _$BackupRecoveryToJson(BackupRecovery instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
      'userId': instance.userId,
      'state': _$BackupRecoveryStateEnumMap[instance.state]!,
    };

const _$BackupRecoveryStateEnumMap = {
  BackupRecoveryState.identityBackupStarted: 'identityBackupStarted',
  BackupRecoveryState.archiveBackupStarted: 'archiveBackupStarted',
};
