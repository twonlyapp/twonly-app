import 'dart:convert';
import 'package:drift/drift.dart';

enum UploadState {
  pending,
  readyToUpload,
  uploadTaskStarted,
  receiverNotified,
  // after all users notified all media files that are not storable by the other person will be deleted
}

@DataClassName('MediaUpload')
class MediaUploads extends Table {
  IntColumn get mediaUploadId => integer().autoIncrement()();
  TextColumn get state =>
      textEnum<UploadState>().withDefault(Constant(UploadState.pending.name))();

  TextColumn get metadata =>
      text().map(MediaUploadMetadataConverter()).nullable()();

  /// exists in UploadState.addedToMessagesDb
  TextColumn get messageIds => text().map(IntListTypeConverter()).nullable()();

  TextColumn get encryptionData =>
      text().map(MediaEncryptionDataConverter()).nullable()();
}

// --- state ----

class MediaUploadMetadata {
  late List<int> contactIds;
  late bool isRealTwonly;
  late int maxShowTime;
  late DateTime messageSendAt;
  late bool isVideo;
  late bool mirrorVideo;

  MediaUploadMetadata();

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

  factory MediaUploadMetadata.fromJson(Map<String, dynamic> json) {
    MediaUploadMetadata state = MediaUploadMetadata();
    state.contactIds = List<int>.from(json['contactIds']);
    state.isRealTwonly = json['isRealTwonly'];
    state.isVideo = json['isVideo'];
    state.mirrorVideo = json['mirrorVideo'];
    state.maxShowTime = json['maxShowTime'];
    state.maxShowTime = json['maxShowTime'];
    state.messageSendAt = DateTime.parse(json['messageSendAt']);
    return state;
  }
}

class MediaEncryptionData {
  late List<int> sha2Hash;
  late List<int> encryptionKey;
  late List<int> encryptionMac;
  late List<int> encryptionNonce;

  MediaEncryptionData();

  Map<String, dynamic> toJson() {
    return {
      'sha2Hash': sha2Hash,
      'encryptionKey': encryptionKey,
      'encryptionMac': encryptionMac,
      'encryptionNonce': encryptionNonce,
    };
  }

  factory MediaEncryptionData.fromJson(Map<String, dynamic> json) {
    MediaEncryptionData state = MediaEncryptionData();
    state.sha2Hash = List<int>.from(json['sha2Hash']);
    state.encryptionKey = List<int>.from(json['encryptionKey']);
    state.encryptionMac = List<int>.from(json['encryptionMac']);
    state.encryptionNonce = List<int>.from(json['encryptionNonce']);
    return state;
  }
}

// --- converters ----

class IntListTypeConverter extends TypeConverter<List<int>, String> {
  @override
  List<int> fromSql(String fromDb) {
    return List<int>.from(jsonDecode(fromDb));
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
