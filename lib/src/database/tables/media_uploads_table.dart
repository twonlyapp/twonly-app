import 'dart:convert';
import 'package:drift/drift.dart';

enum UploadState {
  pending,
  addedToMessagesDb,
  // added .compressed to filename
  isCompressed,
  // added .encypted to filename
  isEncrypted,
  hasUploadToken,
  isUploaded,
  receiverNotified,
  // after all users notified all media files that are not storeable by the other person will be deleted
}

@DataClassName('MediaUpload')
class MediaUploads extends Table {
  IntColumn get mediaUploadId => integer().autoIncrement()();
  TextColumn get state =>
      textEnum<UploadState>().withDefault(Constant(UploadState.pending.name))();

  TextColumn get metadata => text().map(MediaUploadMetadataConverter())();

  /// exists in UploadState.addedToMessagesDb
  TextColumn get messageIds => text().map(IntListTypeConverter()).nullable()();

  /// exsists in UploadState.isEncrypted
  TextColumn get encryptionData =>
      text().map(MediaEncryptionDataConverter()).nullable()();

  /// exsists in UploadState.hasUploadToken
  TextColumn get uploadTokens =>
      text().map(MediaUploadTokensConverter()).nullable()();

  /// exists in UploadState.addedToMessagesDb
  TextColumn get alreadyNotified =>
      text().map(IntListTypeConverter()).withDefault(Constant("[]"))();
}

// --- state ----

class MediaUploadMetadata {
  late List<int> contactIds;
  late bool isRealTwonly;
  late int maxShowTime;
  late DateTime messageSendAt;
  late bool isVideo;
  late bool videoWithAudio;

  MediaUploadMetadata();

  Map<String, dynamic> toJson() {
    return {
      'contactIds': contactIds,
      'isRealTwonly': isRealTwonly,
      'maxShowTime': maxShowTime,
      'isVideo': isVideo,
      'videoWithAudio': videoWithAudio,
      'messageSendAt': messageSendAt.toIso8601String(),
    };
  }

  factory MediaUploadMetadata.fromJson(Map<String, dynamic> json) {
    MediaUploadMetadata state = MediaUploadMetadata();
    state.contactIds = List<int>.from(json['contactIds']);
    state.isRealTwonly = json['isRealTwonly'];
    state.videoWithAudio = json['videoWithAudio'];
    state.isVideo = json['isVideo'];
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

class MediaUploadTokens {
  late List<int> uploadToken;
  late List<List<int>> downloadTokens;

  MediaUploadTokens();

  Map<String, dynamic> toJson() {
    return {
      'uploadToken': uploadToken,
      'downloadTokens': downloadTokens,
    };
  }

  factory MediaUploadTokens.fromJson(Map<String, dynamic> json) {
    MediaUploadTokens state = MediaUploadTokens();
    state.uploadToken = List<int>.from(json['uploadToken']);
    state.downloadTokens = List<List<int>>.from(
      json['downloadTokens'].map((token) => List<int>.from(token)),
    );
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

class MediaUploadTokensConverter
    extends TypeConverter<MediaUploadTokens, String>
    with JsonTypeConverter2<MediaUploadTokens, String, Map<String, Object?>> {
  const MediaUploadTokensConverter();

  @override
  MediaUploadTokens fromSql(String fromDb) {
    return fromJson(json.decode(fromDb) as Map<String, dynamic>);
  }

  @override
  String toSql(MediaUploadTokens value) {
    return json.encode(toJson(value));
  }

  @override
  MediaUploadTokens fromJson(Map<String, Object?> json) {
    return MediaUploadTokens.fromJson(json);
  }

  @override
  Map<String, Object?> toJson(MediaUploadTokens value) {
    return value.toJson();
  }
}
