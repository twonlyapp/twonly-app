import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/misc.dart';

Future<void> createPushAvatars({int? forceForUserId}) async {
  final contacts = await twonlyDB.contactsDao.getAllContacts();

  for (final contact in contacts) {
    if (contact.avatarSvgCompressed == null) continue;

    if (forceForUserId == null) {
      if (avatarPNGFile(contact.userId).existsSync()) {
        continue; // only create the avatar in case no avatar exists yet fot this user
      }
    } else if (contact.userId != forceForUserId) {
      // only update the avatar for this specified contact
      continue;
    }

    final avatarSvg = getAvatarSvg(contact.avatarSvgCompressed!);

    final pictureInfo = await vg.loadPicture(SvgStringLoader(avatarSvg), null);

    final image = await pictureInfo.picture.toImage(270, 300);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    await avatarPNGFile(contact.userId).writeAsBytes(pngBytes);
    pictureInfo.picture.dispose();
  }
}

File avatarPNGFile(int contactId) {
  final avatarsDirectory = Directory(
    '${AppEnvironment.cacheDir}/avatars',
  );

  if (!avatarsDirectory.existsSync()) {
    avatarsDirectory.createSync(recursive: true);
  }
  return File('${avatarsDirectory.path}/$contactId.png');
}

Future<Uint8List> getUserAvatar() async {
  if (gUser.avatarSvg == null) {
    final data = await rootBundle.load('assets/images/default_avatar.png');
    return data.buffer.asUint8List();
  }

  final pictureInfo = await vg.loadPicture(
    SvgStringLoader(gUser.avatarSvg!),
    null,
  );

  final image = await pictureInfo.picture.toImage(270, 300);

  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  final file = avatarPNGFile(gUser.userId)..writeAsBytesSync(pngBytes);
  pictureInfo.picture.dispose();

  return file.readAsBytesSync();
}
