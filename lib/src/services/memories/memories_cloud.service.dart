import 'dart:async';
import 'dart:io';

import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/backup.pb.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

class MemoriesBackupProgress {
  MemoriesBackupProgress({
    required this.totalPending,
    required this.currentUploaded,
    required this.currentUploadProgress,
    this.currentMediaId,
  });

  final int totalPending;
  final int currentUploaded;
  final double currentUploadProgress;
  final String? currentMediaId;
}

class ProgressMultipartRequest extends http.MultipartRequest {
  ProgressMultipartRequest(super.method, super.url, {this.onProgress});

  final void Function(int bytes, int totalBytes)? onProgress;

  @override
  http.ByteStream finalize() {
    final byteStream = super.finalize();
    if (onProgress == null) return byteStream;

    final total = contentLength;
    var bytes = 0;

    final transformer = StreamTransformer<List<int>, List<int>>.fromHandlers(
      handleData: (data, sink) {
        bytes += data.length;
        onProgress!(bytes, total);
        sink.add(data);
      },
    );

    return http.ByteStream(byteStream.transform(transformer));
  }
}

class MemoriesCloudService {
  static final Map<String, Mutex> _fileMutexes = {};

  Timer? _timer;
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  final _progressController =
      StreamController<MemoriesBackupProgress?>.broadcast();
  Stream<MemoriesBackupProgress?> get progressStream =>
      _progressController.stream;

  MemoriesBackupProgress? _currentProgress;
  MemoriesBackupProgress? get currentProgress => _currentProgress;

  void init() {
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      checkUploads();
    });
    // Run immediately
    Future.delayed(const Duration(seconds: 10), checkUploads);
  }

  void dispose() {
    _timer?.cancel();
    _progressController.close();
  }

  void _updateProgress({
    required int totalPending,
    required int currentUploaded,
    required double currentUploadProgress,
    String? currentMediaId,
  }) {
    _currentProgress = MemoriesBackupProgress(
      totalPending: totalPending,
      currentUploaded: currentUploaded,
      currentUploadProgress: currentUploadProgress,
      currentMediaId: currentMediaId,
    );
    _progressController.add(_currentProgress);
  }

  Future<void> checkUploads() async {
    if (_isProcessing || !userService.currentUser.isCloudBackupEnabled) return;

    try {
      final memories = await twonlyDB.mediaFilesDao.getMemoriesToBackup();
      if (memories.isEmpty) {
        return;
      }

      _isProcessing = true;

      final total = memories.length;
      var uploaded = 0;

      _updateProgress(
        totalPending: total,
        currentUploaded: uploaded,
        currentUploadProgress: 0,
      );

      for (final mediaFile in memories) {
        _updateProgress(
          totalPending: total,
          currentUploaded: uploaded,
          currentUploadProgress: 0,
          currentMediaId: mediaFile.mediaId,
        );

        final success = await _backupMemory(mediaFile, (progress) {
          _updateProgress(
            totalPending: total,
            currentUploaded: uploaded,
            currentUploadProgress: progress,
            currentMediaId: mediaFile.mediaId,
          );
        });

        if (success) {
          uploaded++;
        }

        _updateProgress(
          totalPending: total,
          currentUploaded: uploaded,
          currentUploadProgress: 0,
        );
      }
    } catch (e) {
      Log.error('Error in MemoriesCloudService.checkUploads: $e');
    } finally {
      _currentProgress = null;
      _isProcessing = false;
      _progressController.add(null);
    }
  }

  static Future<bool> downloadFromCloud(
    MediaFileService media, {
    required bool isThumbnail,
  }) async {
    final mediaId = media.mediaFile.mediaId;
    final mutex = _fileMutexes.putIfAbsent(mediaId, Mutex.new);

    return mutex.protect(() async {
      final targetPath = isThumbnail ? media.thumbnailPath : media.storedPath;

      if (targetPath.existsSync() && targetPath.lengthSync() > 0) {
        return true;
      }

      String? downloadUrl;
      try {
        downloadUrl = await RustApi.getMemoriesUrl(
          mediaId: mediaId,
          thumbnail: isThumbnail,
        );
      } catch (_) {}
      if (downloadUrl == null || downloadUrl.isEmpty) return false;

      try {
        final response = await http.get(Uri.parse(downloadUrl));

        if (response.statusCode == 200) {
          return await _decryptFile(response.bodyBytes, targetPath);
        } else {
          Log.warn(
            'Failed to download ${isThumbnail ? 'thumbnail' : 'full media'} statuscode ${response.statusCode}',
          );
        }
      } catch (e) {
        Log.warn(e);
      }
      return false;
    });
  }

  Future<bool> _backupMemory(
    MediaFile mediaFile,
    void Function(double progress) onProgress,
  ) async {
    try {
      final ms = MediaFileService(mediaFile);

      if (!ms.storedPath.existsSync()) return false;

      if (!mediaFile.hasThumbnail) {
        await MediaFileService(mediaFile).createThumbnail();
      }

      final sizeBytes = ms.storedPath.lengthSync();
      final FrbMemoriesUploadUrls? urls;
      try {
        urls = await RustApi.requestMemoriesUpload(
          size: sizeBytes,
          originalDate: mediaFile.createdAt.millisecondsSinceEpoch,
          mediaId: mediaFile.mediaId,
        );
      } catch (error) {
        Log.error(
          'Could not get upload URLs for memory ${mediaFile.mediaId}',
          error: error,
        );
        return false;
      }

      await twonlyDB.mediaFilesDao.updateMedia(
        mediaFile.mediaId,
        const MediaFilesCompanion(
          cloudState: Value(CloudState.pending),
        ),
      );

      final mediaKey = getRandomUint8List(32);
      final encryptedMediaKey = await RustKeyManager.encryptCloudMediaKey(
        mediaKey: mediaKey,
        addition: 'app',
      );

      final tempDir = await getTemporaryDirectory();

      // 1. Upload thumbnail if exists
      final thumbUpload = urls.thumbnailUpload;
      if (ms.thumbnailPath.existsSync() && thumbUpload != null) {
        final thumbFile = await _encryptFile(
          ms.thumbnailPath,
          mediaKey,
          encryptedMediaKey,
          tempDir,
          'thumb_${mediaFile.mediaId}',
        );
        try {
          await _uploadToS3(thumbUpload, thumbFile, (_) {});
        } finally {
          if (thumbFile.existsSync()) {
            thumbFile.deleteSync();
          }
        }
      }

      // 2. Upload full media if exists
      final fullUpload = urls.fullUpload;
      if (fullUpload != null) {
        final fullFile = await _encryptFile(
          ms.storedPath,
          mediaKey,
          encryptedMediaKey,
          tempDir,
          'full_${mediaFile.mediaId}',
        );
        try {
          await _uploadToS3(fullUpload, fullFile, onProgress);
        } finally {
          if (fullFile.existsSync()) {
            fullFile.deleteSync();
          }
        }
      }

      // 3. Confirm upload
      final confirmRes = await rustApiResult(
        RustApi.confirmMemoriesUpload(mediaId: mediaFile.mediaId),
      );
      if (confirmRes.isSuccess) {
        await twonlyDB.mediaFilesDao.updateMedia(
          mediaFile.mediaId,
          const MediaFilesCompanion(
            cloudState: Value(CloudState.uploaded),
          ),
        );
        Log.info(
          'Cloud backup complete and confirmed for ${mediaFile.mediaId}',
        );
        return true;
      } else {
        throw Exception('Server confirmation failed: ${confirmRes.error}');
      }
    } catch (e) {
      Log.error('Error backing up memory ${mediaFile.mediaId}: $e');
      await twonlyDB.mediaFilesDao.updateMedia(
        mediaFile.mediaId,
        const MediaFilesCompanion(
          cloudState: Value(CloudState.none),
        ),
      );
      return false;
    }
  }

  Future<void> _uploadToS3(
    FrbPresignedPost presignedPost,
    File file,
    void Function(double progress) onProgress,
  ) async {
    final request = ProgressMultipartRequest(
      'POST',
      Uri.parse(presignedPost.url),
      onProgress: (bytes, total) {
        if (total > 0) {
          onProgress(bytes / total);
        }
      },
    );

    request.fields.addAll(
      Map.fromEntries(presignedPost.fields.map((f) => MapEntry(f.$1, f.$2))),
    );
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: 'file',
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'S3 upload failed: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<File> _encryptFile(
    File inputFile,
    Uint8List mediaKey,
    List<int> encryptedMediaKey,
    Directory tempDir,
    String prefix,
  ) async {
    final dataToEncrypt = await inputFile.readAsBytes();
    final chacha20 = FlutterChacha20.poly1305Aead();
    final nonce = chacha20.newNonce();

    final secretBox = await chacha20.encrypt(
      dataToEncrypt,
      secretKey: SecretKey(mediaKey),
      nonce: nonce,
    );

    final cipherTextWithMac = Uint8List.fromList(
      secretBox.cipherText + secretBox.mac.bytes,
    );

    final payload = CloudMediaBackupEncrypted()
      ..addition = 'app'
      ..encryptedMediaKey = encryptedMediaKey
      ..mediaNonce = nonce
      ..mediaCiphertext = cipherTextWithMac;

    final outFile = File('${tempDir.path}/$prefix.encrypted');
    await outFile.writeAsBytes(payload.writeToBuffer());
    return outFile;
  }

  static Future<bool> _decryptFile(
    Uint8List encryptedData,
    File outFile,
  ) async {
    try {
      // 2. Parse the protobuf payload FIRST to access the key and addition
      final payload = CloudMediaBackupEncrypted.fromBuffer(encryptedData);

      // 3. Get the media key using the encrypted key and addition from the payload
      final mediaKey = await RustKeyManager.decryptCloudMediaKey(
        encryptedMediaKey: payload.encryptedMediaKey,
        addition: payload.addition,
      );

      // 4. Extract the concatenated ciphertext + MAC, and the nonce
      final nonce = payload.mediaNonce;
      final cipherTextWithMac = payload.mediaCiphertext;

      // 5. Separate the ciphertext and the MAC (Poly1305 MAC is always 16 bytes)
      const macLength = 16;
      final cipherTextLength = cipherTextWithMac.length - macLength;

      final cipherText = cipherTextWithMac.sublist(0, cipherTextLength);
      final macBytes = cipherTextWithMac.sublist(cipherTextLength);

      // 6. Reconstruct the SecretBox
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(macBytes),
      );

      // 7. Decrypt the data using the newly retrieved media key
      final chacha20 = FlutterChacha20.poly1305Aead();
      final decryptedBytes = await chacha20.decrypt(
        secretBox,
        secretKey: SecretKey(mediaKey),
      );

      await outFile.writeAsBytes(decryptedBytes);
      return true;
    } catch (e) {
      Log.error(e);
      return false;
    }
  }
}

final memoriesCloudService = MemoriesCloudService();
