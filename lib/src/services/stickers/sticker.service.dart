import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';

class StickerService {
  const StickerService._();

  static const fallbackText = '🖼️';

  static StickerData? decodeAdditional(Uint8List? bytes) {
    if (bytes == null) return null;
    try {
      final additional = AdditionalMessageData.fromBuffer(bytes);
      if (additional.type != AdditionalMessageData_Type.STICKER ||
          !additional.hasSticker()) {
        return null;
      }
      final sticker = additional.sticker;
      if (sticker.version != 1 ||
          sticker.webp.isEmpty ||
          sticker.webp.length > 128 * 1024 ||
          sticker.sha256.length != 32 ||
          sticker.width < 1 ||
          sticker.width > 300 ||
          sticker.height < 1 ||
          sticker.height > 300) {
        return null;
      }
      final digest = sha256.convert(sticker.webp).bytes;
      for (var index = 0; index < digest.length; index++) {
        if (digest[index] != sticker.sha256[index]) return null;
      }
      return sticker;
    } on Object {
      return null;
    }
  }

  static StickerData fromLocal(LocalSticker sticker) {
    return StickerData(
      version: 1,
      webp: sticker.webp,
      sha256: hex.decode(sticker.contentHash),
      width: sticker.width,
      height: sticker.height,
    );
  }

  static Uint8List encodeAdditional(LocalSticker sticker) {
    return AdditionalMessageData(
      type: AdditionalMessageData_Type.STICKER,
      sticker: fromLocal(sticker),
    ).writeToBuffer();
  }

  static Future<LocalSticker> createFromPath(String imagePath) async {
    final output = await RustApi.createSticker(imagePath: imagePath);
    await twonlyDB.stickersDao.save(
      webp: output.webp,
      width: output.width,
      height: output.height,
      expectedHash: output.contentHash,
    );
    final sticker = await twonlyDB.stickersDao.getByHash(output.contentHash);
    if (sticker == null) {
      throw StateError('created sticker was not stored');
    }
    return sticker;
  }

  /// Finds the best full-resolution local source for a stored memory. A
  /// cloud-only memory is downloaded before its path is returned.
  static Future<String?> resolveMediaPath(MediaFileService media) async {
    File? readableSource() {
      for (final file in [
        media.storedPath,
        media.tempPath,
        media.originalPath,
      ]) {
        final stat = file.statSync();
        if (stat.type != FileSystemEntityType.notFound && stat.size > 0) {
          return file;
        }
      }
      return null;
    }

    var source = readableSource();
    if (source == null && media.mediaFile.cloudState == CloudState.uploaded) {
      final downloaded = await MemoriesCloudService.downloadFromCloud(
        media,
        isThumbnail: false,
      );
      if (downloaded) source = readableSource();
    }
    return source?.path;
  }

  static Future<LocalSticker> createFromMedia(MediaFileService media) async {
    final path = await resolveMediaPath(media);
    if (path == null) {
      throw StateError('sticker source media is unavailable');
    }
    return createFromPath(path);
  }

  static Future<bool> saveReceived(StickerData sticker) {
    return twonlyDB.stickersDao.save(
      webp: Uint8List.fromList(sticker.webp),
      width: sticker.width,
      height: sticker.height,
      expectedHash: hex.encode(sticker.sha256),
    );
  }

  static Future<void> send({
    required String groupId,
    required LocalSticker sticker,
    String? quoteMessageId,
  }) async {
    await RustApi.insertAndSendText(
      groupId: groupId,
      text: fallbackText,
      quoteMessageId: quoteMessageId,
      additionalMessageData: encodeAdditional(sticker),
    );
    await twonlyDB.stickersDao.recordUse(sticker.contentHash);
  }
}
