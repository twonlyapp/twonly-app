import 'dart:convert';
import 'package:drift/drift.dart';

enum MediaType {
  image,
  video,
  gif,
  audio,
}

enum UploadState {
  // Image/Video was taken. A database entry was created to track it...
  initialized,
  // Image was stored but not send
  storedOnly,
  // At this point the user is finished with editing, and the media file can be uploaded
  preprocessing,
  uploading,
  backgroundUploadTaskStarted,
  uploaded,

  uploadLimitReached,
  // readyToUpload,
  // uploadTaskStarted,
  // receiverNotified,
}

enum DownloadState {
  pending,
  downloading,
  downloaded,
  ready,
  reuploadRequested
}

@DataClassName('MediaFile')
class MediaFiles extends Table {
  TextColumn get mediaId => text()();

  TextColumn get type => textEnum<MediaType>()();

  TextColumn get uploadState => textEnum<UploadState>().nullable()();
  TextColumn get downloadState => textEnum<DownloadState>().nullable()();

  BoolColumn get requiresAuthentication =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get stored => boolean().withDefault(const Constant(false))();
  BoolColumn get isDraftMedia => boolean().withDefault(const Constant(false))();

  TextColumn get reuploadRequestedBy =>
      text().map(IntListTypeConverter()).nullable()();

  IntColumn get displayLimitInMilliseconds => integer().nullable()();
  BoolColumn get removeAudio => boolean().nullable()();

  BlobColumn get downloadToken => blob().nullable()();
  BlobColumn get encryptionKey => blob().nullable()();
  BlobColumn get encryptionMac => blob().nullable()();
  BlobColumn get encryptionNonce => blob().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {mediaId};
}

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
