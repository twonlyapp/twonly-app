import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';

/// Flutter only decides whether the user's network policy permits a download.
/// Transfer, validation, decryption, hashing, and state changes are Rust-owned.
Future<void> tryDownloadAllMediaFiles({bool force = false}) async {
  if (force) {
    await RustApi.downloadPendingMedia();
    return;
  }
  final mediaFiles = await rust_mediafiles.listMediaFiles(
    input: const db_mediafiles.MediaQuery(
      filter: db_mediafiles.MediaFilter.pendingDownload,
    ),
    transaction: currentDatabaseSession(),
  );
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
