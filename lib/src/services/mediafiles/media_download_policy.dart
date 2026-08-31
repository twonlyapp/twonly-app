import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

/// Flutter only decides whether the user's network policy permits a download.
/// Transfer, validation, decryption, hashing, and state changes are Rust-owned.
Future<void> tryDownloadAllMediaFiles({bool force = false}) async {
  if (force) {
    await RustApi.downloadPendingMedia();
    return;
  }
  final mediaFiles = await twonlyDB.mediaFilesDao
      .getAllMediaFilesPendingDownload();
  for (final media in mediaFiles) {
    if (await isAllowedToDownload(media.type)) {
      await RustApi.downloadMedia(mediaId: media.mediaId);
    }
  }
}

enum DownloadMediaTypes { video, image, audio }

Map<String, List<String>> defaultAutoDownloadOptions = {
  ConnectivityResult.mobile.name: [DownloadMediaTypes.audio.name],
  ConnectivityResult.wifi.name: [
    DownloadMediaTypes.video.name,
    DownloadMediaTypes.image.name,
    DownloadMediaTypes.audio.name,
  ],
};

Future<bool> isAllowedToDownload(MediaType type) async {
  if (type == MediaType.audio) return true;
  final connectivityResult = await Connectivity().checkConnectivity();
  final options =
      userService.currentUser.autoDownloadOptions ?? defaultAutoDownloadOptions;
  if (connectivityResult.contains(ConnectivityResult.mobile)) {
    return options[ConnectivityResult.mobile.name]!.contains(
      type == MediaType.video
          ? DownloadMediaTypes.video.name
          : DownloadMediaTypes.image.name,
    );
  }
  if (connectivityResult.contains(ConnectivityResult.wifi)) {
    return options[ConnectivityResult.wifi.name]!.contains(
      type == MediaType.video
          ? DownloadMediaTypes.video.name
          : DownloadMediaTypes.image.name,
    );
  }
  return false;
}

Future<void> startDownloadMedia(MediaFile media, bool force) async {
  if (force || await isAllowedToDownload(media.type)) {
    await RustApi.downloadMedia(mediaId: media.mediaId);
  }
}
