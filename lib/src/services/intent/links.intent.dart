import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/qr.utils.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor.view.dart';
import 'package:twonly/src/visual/views/chats/add_new_user.view.dart';

Future<bool> handleIntentUrl(BuildContext context, Uri uri) async {
  if (!uri.scheme.startsWith('http')) return false;
  if (uri.host != 'me.twonly.eu') return false;
  if (uri.hasEmptyPath) return false;

  // Check if this is the QR code link which was
  // therefore scanned with the system camera

  if (uri.toString().startsWith(QrCodeUtils.linkPrefix)) {
    final result = await QrCodeUtils.handleQrCodeLink(uri.toString());

    if (!context.mounted) return false;

    if (result != null) {
      final (profile, contact, verificationOk) = result;

      if (profile.username == userService.currentUser.username) {
        await context.push(Routes.settingsPublicProfile);
        return true;
      }

      if (contact != null) {
        if (verificationOk) {
          await context.push(Routes.profileContact(contact.userId));
        } else {
          await _pubKeysDoNotMatch(context, contact.username);
        }
      } else {
        await context.navPush(
          AddNewUserView(
            username: profile.username,
            publicKey: Uint8List.fromList(profile.publicIdentityKey),
          ),
        );
      }
    }

    return true;
  }

  final publicKey = uri.hasFragment ? uri.fragment : null;
  final userPaths = uri.path.split('/');
  if (userPaths.length != 2) return false;
  final username = userPaths[1];

  if (!context.mounted) return false;

  if (username == userService.currentUser.username) {
    await context.push(Routes.settingsPublicProfile);
    return true;
  }

  Log.info(
    'Opened via deep link!: username = $username public_key = ${uri.fragment}',
  );

  final contacts = await twonlyDB.contactsDao.getContactsByUsername(username);
  if (!context.mounted) return true;

  if (contacts.isEmpty) {
    // User does not yet exists, making a request...
    Uint8List? publicKeyBytes;
    if (publicKey != null) {
      publicKeyBytes = base64Url.decode(publicKey);
    }
    await context.navPush(
      AddNewUserView(
        username: username,
        publicKey: publicKeyBytes,
      ),
    );
    return true;
  }

  if (publicKey != null) {
    try {
      final contact = contacts.first;
      final storedPublicKey = await getPublicKeyFromContact(contact.userId);
      final receivedPublicKey = base64Url.decode(publicKey);
      if (storedPublicKey == null ||
          receivedPublicKey.isEmpty ||
          !context.mounted) {
        return true;
      }
      if (storedPublicKey.equals(receivedPublicKey)) {
        final markAsVerified = await showAlertDialog(
          context,
          context.lang.linkFromUsername(contact.username),
          context.lang.linkFromUsernameLong,
          customOk: context.lang.gotLinkFromFriend,
        );
        if (markAsVerified) {
          await twonlyDB.keyVerificationDao.addKeyVerification(
            contact.userId,
            VerificationType.link,
          );
        }
        if (context.mounted) {
          await context.push(Routes.profileContact(contact.userId));
        }
      } else {
        await _pubKeysDoNotMatch(context, contact.username);
      }
    } catch (e) {
      Log.warn(e);
    }
  }

  return true;
}

Future<void> _pubKeysDoNotMatch(BuildContext context, String username) async {
  await showAlertDialog(
    context,
    context.lang.couldNotVerifyUsername(username),
    context.lang.linkPubkeyDoesNotMatch,
    customCancel: '',
  );
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
    userService.currentUser.defaultShowTime,
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

StreamSubscription<List<SharedFile>> initIntentStreams(
  BuildContext context,
  void Function(Uri) onUrlCallBack,
) {
  FlutterSharingIntent.instance.getInitialSharing().then((f) {
    if (!context.mounted) return;
    handleIntentSharedFile(context, f, onUrlCallBack);
  });

  return FlutterSharingIntent.instance.getMediaStream().listen(
    (f) {
      if (!context.mounted) return;
      handleIntentSharedFile(context, f, onUrlCallBack);
    },
    // ignore: inference_failure_on_untyped_parameter
    onError: (err) {
      Log.error('getIntentDataStream error: $err');
    },
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

    Log.info('got file via intent ${file.type}');

    switch (file.type) {
      case SharedMediaType.URL:
        if (file.value?.startsWith('http') ?? false) {
          final uri = Uri.parse(file.value!);
          Log.info('Got link via handle intent share file: ${uri.scheme}');
          onUrlCallBack(uri);
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
