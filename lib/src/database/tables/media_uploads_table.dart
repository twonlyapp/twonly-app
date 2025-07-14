import 'dart:convert';
import 'package:drift/drift.dart';

enum UploadState {
  pending,
  readyToUpload,
  uploadTaskStarted,
  receiverNotified,
}

@DataClassName('MediaUpload')
class MediaUploads extends Table {
  IntColumn get mediaUploadId => integer().autoIncrement()();
  TextColumn get state =>
      textEnum<UploadState>().withDefault(Constant(UploadState.pending.name))();

  TextColumn get metadata =>
      text().map(const MediaUploadMetadataConverter()).nullable()();

  /// exists in UploadState.addedToMessagesDb
  TextColumn get messageIds => text().map(IntListTypeConverter()).nullable()();

  TextColumn get encryptionData =>
      text().map(const MediaEncryptionDataConverter()).nullable()();
}

// --- state ----

class MediaUploadMetadata {
  MediaUploadMetadata();
  factory MediaUploadMetadata.fromJson(Map<String, dynamic> json) {
    return MediaUploadMetadata()
      ..contactIds = List<int>.from(json['contactIds'] as Iterable<dynamic>)
      ..isRealTwonly = json['isRealTwonly'] as bool
      ..isVideo = json['isVideo'] as bool
      ..mirrorVideo = json['mirrorVideo'] as bool
      ..maxShowTime = json['maxShowTime'] as int
      ..maxShowTime = json['maxShowTime'] as int
      ..messageSendAt = DateTime.parse(json['messageSendAt'] as String);
  }

  late List<int> contactIds;
  late bool isRealTwonly;
  late int maxShowTime;
  late DateTime messageSendAt;
  late bool isVideo;
  late bool mirrorVideo;

  Map<String, dynamic> toJson() {
    return {
      'contactIds': contactIds,
      'isRealTwonly': isRealTwonly,
      'mirrorVideo': mirrorVideo,
      'maxShowTime': maxShowTime,
      'isVideo': isVideo,
      'messageSendAt': messageSendAt.toIso8601String(),
    };
  }
}

class MediaEncryptionData {
  MediaEncryptionData();

  factory MediaEncryptionData.fromJson(Map<String, dynamic> json) {
    return MediaEncryptionData()
      ..sha2Hash = List<int>.from(json['sha2Hash'] as Iterable<dynamic>)
      ..encryptionKey =
          List<int>.from(json['encryptionKey'] as Iterable<dynamic>)
      ..encryptionMac =
          List<int>.from(json['encryptionMac'] as Iterable<dynamic>)
      ..encryptionNonce =
          List<int>.from(json['encryptionNonce'] as Iterable<dynamic>);
  }
  late List<int> sha2Hash;
  late List<int> encryptionKey;
  late List<int> encryptionMac;
  late List<int> encryptionNonce;

  Map<String, dynamic> toJson() {
    return {
      'sha2Hash': sha2Hash,
      'encryptionKey': encryptionKey,
      'encryptionMac': encryptionMac,
      'encryptionNonce': encryptionNonce,
    };
  }
}

// --- converters ----

class IntListTypeConverter extends TypeConverter<List<int>, String> {
  @override
  List<int> fromSql(String fromDb) {
    return List<int>.from(jsonDecode(fromDb) as Iterable<dynamic>);
  }

  @override
  String toSql(List<int> value) {
    return json.encode(value);
  }
}

class MediaUploadMetadataConverter
    extends TypeConverter<MediaUploadMetadata, String>
    with JsonTypeConverter2<MediaUploadMetadata, String, Map<String, Object?>> {
  const MediaUploadMetadataConverter();

  @override
  MediaUploadMetadata fromSql(String fromDb) {
    return fromJson(json.decode(fromDb) as Map<String, dynamic>);
  }

  @override
  String toSql(MediaUploadMetadata value) {
    return json.encode(toJson(value));
  }

  @override
  MediaUploadMetadata fromJson(Map<String, Object?> json) {
    return MediaUploadMetadata.fromJson(json);
  }

  @override
  Map<String, Object?> toJson(MediaUploadMetadata value) {
    return value.toJson();
  }
}

class MediaEncryptionDataConverter
    extends TypeConverter<MediaEncryptionData, String>
    with JsonTypeConverter2<MediaEncryptionData, String, Map<String, Object?>> {
  const MediaEncryptionDataConverter();

  @override
  MediaEncryptionData fromSql(String fromDb) {
    return fromJson(json.decode(fromDb) as Map<String, dynamic>);
  }

  @override
  String toSql(MediaEncryptionData value) {
    return json.encode(toJson(value));
  }

  @override
  MediaEncryptionData fromJson(Map<String, Object?> json) {
    return MediaEncryptionData.fromJson(json);
  }

  @override
  Map<String, Object?> toJson(MediaEncryptionData value) {
    return value.toJson();
  }
}
