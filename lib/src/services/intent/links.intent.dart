import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/share_image_editor.view.dart';
import 'package:twonly/src/views/chats/add_new_user.view.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/contact/contact.view.dart';
import 'package:twonly/src/views/public_profile.view.dart';

Future<void> handleIntentUrl(BuildContext context, Uri uri) async {
  if (!uri.scheme.startsWith('http')) return;
  if (uri.host != 'me.twonly.eu') return;
  if (uri.hasEmptyPath) return;

  final publicKey = uri.hasFragment ? uri.fragment : null;
  final userPaths = uri.path.split('/');
  if (userPaths.length != 2) return;
  final username = userPaths[1];

  if (!context.mounted) return;

  if (username == gUser.username) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const PublicProfileView();
        },
      ),
    );
    return;
  }

  Log.info(
    'Opened via deep link!: username = $username public_key = ${uri.fragment}',
  );
  final contacts = await twonlyDB.contactsDao.getContactsByUsername(username);
  if (contacts.isEmpty) {
    if (!context.mounted) return;
    Uint8List? publicKeyBytes;
    if (publicKey != null) {
      publicKeyBytes = base64Url.decode(publicKey);
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AddNewUserView(
            username: username,
            publicKey: publicKeyBytes,
          );
        },
      ),
    );
  } else if (publicKey != null) {
    try {
      final contact = contacts.first;
      final storedPublicKey = await getPublicKeyFromContact(contact.userId);
      final receivedPublicKey = base64Url.decode(publicKey);
      if (storedPublicKey == null ||
          receivedPublicKey.isEmpty ||
          !context.mounted) {
        return;
      }
      if (storedPublicKey.equals(receivedPublicKey)) {
        if (!contact.verified) {
          final markAsVerified = await showAlertDialog(
            context,
            context.lang.linkFromUsername(contact.username),
            context.lang.linkFromUsernameLong,
            customOk: context.lang.gotLinkFromFriend,
          );
          if (markAsVerified) {
            await twonlyDB.contactsDao.updateContact(
              contact.userId,
              const ContactsCompanion(
                verified: Value(true),
              ),
            );
          }
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return ContactView(contact.userId);
              },
            ),
          );
        }
      } else {
        await showAlertDialog(
          context,
          context.lang.couldNotVerifyUsername(contact.username),
          context.lang.linkPubkeyDoesNotMatch,
          customCancel: '',
        );
      }
    } catch (e) {
      Log.warn(e);
    }
  }
}

Future<void> handleIntentMediaFile(
  BuildContext context,
  String filePath,
  MediaType type,
) async {
  final file = File(filePath);
  if (!file.existsSync()) {
    Log.error('The shared intent file does not exits.');
    return;
  }

  final newMediaService = await initializeMediaUpload(
    type,
    gUser.defaultShowTime,
  );
  if (newMediaService == null) {
    Log.error('Could not create new media file for intent shared file');
    return;
  }

  file.copySync(newMediaService.originalPath.path);
  if (!context.mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ShareImageEditorView(
        mediaFileService: newMediaService,
        sharedFromGallery: true,
      ),
    ),
  );
}

Future<void> handleIntentSharedFile(
  BuildContext context,
  List<SharedFile> files,
  void Function(Uri) onUrlCallBack,
) async {
  for (final file in files) {
    if (file.value == null) {
      Log.error(
        'Got shared media, but value is empty: getMediaStream ${file.mimeType}',
      );
      continue;
    }
    Log.info('got file via intent ${file.type} ${file.value}');

    switch (file.type) {
      case SharedMediaType.URL:
        if (file.value?.startsWith('http') ?? false) {
          onUrlCallBack(Uri.parse(file.value!));
        }
      case SharedMediaType.IMAGE:
        var type = MediaType.image;
        if (file.value!.endsWith('.gif')) {
          type = MediaType.gif;
        }
        await handleIntentMediaFile(context, file.value!, type);
      case SharedMediaType.VIDEO:
        await handleIntentMediaFile(context, file.value!, MediaType.video);
      // ignore: no_default_cases
      default:
    }
    break; // only handle one file...
  }
}
