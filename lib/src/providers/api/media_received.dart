import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/media_send.dart';
import 'package:twonly/src/utils/misc.dart';
import 'dart:typed_data';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:logging/logging.dart';
import 'package:twonly/app.dart';
import 'package:twonly/src/model/protobuf/api/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/model/protobuf/api/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/server_to_client.pbserver.dart';

Map<int, DateTime> downloadStartedForMediaReceived = {};

Future tryDownloadAllMediaFiles() async {
  // this is called when websocket is newly connected, so allow all downloads to be restarted.
  downloadStartedForMediaReceived = {};
  List<Message> messages =
      await twonlyDatabase.messagesDao.getAllMessagesPendingDownloading();

  for (Message message in messages) {
    await startDownloadMedia(message, false);
  }
}

Future startDownloadMedia(Message message, bool force) async {
  if (message.contentJson == null) return;
  if (downloadStartedForMediaReceived[message.messageId] != null) {
    DateTime started = downloadStartedForMediaReceived[message.messageId]!;
    Duration elapsed = DateTime.now().difference(started);
    if (elapsed <= Duration(seconds: 60)) {
      Logger("media_received.dart").shout("Download already started...");
      return;
    }
  }

  final content =
      MessageContent.fromJson(message.kind, jsonDecode(message.contentJson!));

  if (content is! MediaMessageContent) return;
  if (content.downloadToken == null) return;

  var media = await twonlyDatabase.mediaDownloadsDao
      .getMediaDownloadById(message.messageId)
      .getSingleOrNull();
  if (media == null) {
    await twonlyDatabase.mediaDownloadsDao.insertMediaDownload(
      MediaDownloadsCompanion(
        messageId: Value(message.messageId),
        downloadToken: Value(content.downloadToken!),
      ),
    );
    media = await twonlyDatabase.mediaDownloadsDao
        .getMediaDownloadById(message.messageId)
        .getSingleOrNull();
  }

  if (media == null) return;

  if (!force && !await isAllowedToDownload(content.isVideo)) {
    return;
  }

  if (message.downloadState != DownloadState.downloaded) {
    await twonlyDatabase.messagesDao.updateMessageByMessageId(
      message.messageId,
      MessagesCompanion(
        downloadState: Value(DownloadState.downloading),
      ),
    );

    int offset = 0;
    Uint8List? bytes = await readMediaFile(media.messageId, "encrypted");
    if (bytes != null && bytes.isNotEmpty) {
      offset = bytes.length;
    }

    downloadStartedForMediaReceived[message.messageId] = DateTime.now();
    apiProvider.triggerDownload(content.downloadToken!, offset);
  }
}

Future<client.Response> handleDownloadData(DownloadData data) async {
  if (globalIsAppInBackground) {
    // download should only be done when the app is open
    return client.Response()..error = ErrorCode.InternalError;
  }

  Logger("server_messages")
      .info("downloading: ${data.downloadToken} ${data.fin}");

  final media = await twonlyDatabase.mediaDownloadsDao
      .getMediaDownloadByDownloadToken(data.downloadToken)
      .getSingleOrNull();

  if (media == null) {
    Logger("server_messages")
        .shout("download data received, but unknown messageID");
    // answers with ok, so the server will delete the message
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  if (data.fin && data.offset == 3_980_938_213 && data.data.isEmpty) {
    Logger("media_received.dart").shout("Image already deleted by the server!");
    // media file was deleted by the server. remove the media from device
    await twonlyDatabase.messagesDao.updateMessageByMessageId(
      media.messageId,
      MessagesCompanion(
        errorWhileSending: Value(true),
      ),
    );
    await deleteMediaFile(media.messageId, "encrypted");
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  Uint8List? buffered = await readMediaFile(media.messageId, "encrypted");
  Uint8List downloadedBytes;
  if (buffered != null) {
    if (data.offset != buffered.length) {
      Logger("media_received.dart")
          .shout("server send wrong offset: ${data.offset} ${buffered.length}");
      return client.Response()..error = ErrorCode.InvalidOffset;
    }
    var b = BytesBuilder();
    b.add(buffered);
    b.add(data.data);
    downloadedBytes = b.takeBytes();
  } else {
    downloadedBytes = Uint8List.fromList(data.data);
  }

  await writeMediaFile(media.messageId, "encrypted", downloadedBytes);

  if (!data.fin) {
    // download not finished, so waiting for more data...
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  Message? msg = await twonlyDatabase.messagesDao
      .getMessageByMessageId(media.messageId)
      .getSingleOrNull();

  if (msg == null) {
    await deleteMediaFile(media.messageId, "encrypted");
    Logger("media_received.dart")
        .info("messageId not found in database. Ignoring download");
    // answers with ok, so the server will delete the message
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  MediaMessageContent content =
      MediaMessageContent.fromJson(jsonDecode(msg.contentJson!));

  final xchacha20 = Xchacha20.poly1305Aead();
  SecretKeyData secretKeyData = SecretKeyData(content.encryptionKey!);

  SecretBox secretBox = SecretBox(
    downloadedBytes,
    nonce: content.encryptionNonce!,
    mac: Mac(content.encryptionMac!),
  );

  try {
    final plaintextBytes =
        await xchacha20.decrypt(secretBox, secretKey: secretKeyData);
    var imageBytes = Uint8List.fromList(plaintextBytes);

    if (content.isVideo) {
      final splited = extractUint8Lists(imageBytes);
      imageBytes = splited[0];
      await writeMediaFile(media.messageId, "mp4", splited[1]);
    }

    await writeMediaFile(media.messageId, "png", imageBytes);
  } catch (e) {
    Logger("media_received.dart").info("Decryption error: $e");
    await twonlyDatabase.messagesDao.updateMessageByMessageId(
      media.messageId,
      MessagesCompanion(
        errorWhileSending: Value(true),
      ),
    );
    // answers with ok, so the server will delete the message
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  await twonlyDatabase.messagesDao.updateMessageByMessageId(
    media.messageId,
    MessagesCompanion(downloadState: Value(DownloadState.downloaded)),
  );

  await deleteMediaFile(media.messageId, "encrypted");

  var ok = client.Response_Ok()..none = true;
  return client.Response()..ok = ok;
}

Future<Uint8List?> getImageBytes(int mediaId) async {
  return await readMediaFile(mediaId, "png");
}

Future<File?> getVideoPath(int mediaId) async {
  String basePath = await getMediaFilePath(mediaId, "received");
  return File("$basePath.mp4");
}

/// --- helper functions ---

Future<Uint8List?> readMediaFile(int mediaId, String type) async {
  String basePath = await getMediaFilePath(mediaId, "received");
  File file = File("$basePath.$type");
  if (!await file.exists()) {
    return null;
  }
  return await file.readAsBytes();
}

Future<void> writeMediaFile(int mediaId, String type, Uint8List data) async {
  String basePath = await getMediaFilePath(mediaId, "received");
  File file = File("$basePath.$type");
  await file.writeAsBytes(data);
}

Future<void> deleteMediaFile(int mediaId, String type) async {
  String basePath = await getMediaFilePath(mediaId, "received");
  File file = File("$basePath.$type");
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    Logger("media_received.dart").shout("Erro deleting: $e");
  }
}

Future<void> purgeReceivedMediaFiles() async {
  final basedir = await getApplicationSupportDirectory();
  final directory = Directory(join(basedir.path, 'media', "received"));
  await purgeMediaFiles(directory);
}

Future<void> purgeMediaFiles(Directory directory) async {
  // Check if the directory exists
  if (await directory.exists()) {
    // List all files in the directory
    List<FileSystemEntity> files = directory.listSync();

    List<int> integerFilenames = [];

    // Iterate over each file
    for (var file in files) {
      // Get the filename
      String filename = file.uri.pathSegments.last;

      // Use a regular expression to extract the integer part
      final match = RegExp(r'(\d+)').firstMatch(filename);
      if (match != null) {
        // Parse the integer and add it to the list
        int messageId = int.parse(match.group(0)!);
        Message? message = await twonlyDatabase.messagesDao
            .getMessageByMessageId(messageId)
            .getSingleOrNull();

        if ((message == null) ||
            (message.openedAt != null && !message.mediaStored) ||
            message.errorWhileSending) {
          try {
            file.deleteSync();
          } catch (e) {
            Logger("media_received.dart").shout("$e");
          }
        }
      }
    }

    print(integerFilenames);
  }
}
