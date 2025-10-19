import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';

enum MediaType {
  image,
  video,
  gif,
}

enum UploadState {
  pending,
  readyToUpload,
  uploadTaskStarted,
  receiverNotified,
}

enum DownloadState {
  pending,
}

@DataClassName('MediaFile')
class MediaFiles extends Table {
  TextColumn get mediaId => text().clientDefault(() => uuid.v4())();

  TextColumn get type => textEnum<MediaType>()();

  TextColumn get uploadState => textEnum<UploadState>().nullable()();
  TextColumn get downloadState => textEnum<DownloadState>().nullable()();

  BoolColumn get requiresAuthentication => boolean()();
  BoolColumn get reopenByContact =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get storedByContact =>
      boolean().withDefault(const Constant(false))();

  IntColumn get displayLimitInMilliseconds => integer().nullable()();

  BlobColumn get downloadToken => blob().nullable()();
  BlobColumn get encryptionKey => blob().nullable()();
  BlobColumn get encryptionMac => blob().nullable()();
  BlobColumn get encryptionNonce => blob().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {mediaId};
}
