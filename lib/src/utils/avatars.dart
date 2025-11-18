import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_svg/svg.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/misc.dart';

Future<void> createPushAvatars() async {
  final contacts = await twonlyDB.contactsDao.getAllNotBlockedContacts();

  for (final contact in contacts) {
    if (contact.avatarSvgCompressed == null) continue;

    final avatarSvg = getAvatarSvg(contact.avatarSvgCompressed!);

    final pictureInfo = await vg.loadPicture(SvgStringLoader(avatarSvg), null);

    final image = await pictureInfo.picture.toImage(300, 300);

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    await avatarPNGFile(contact.userId).writeAsBytes(pngBytes);
    pictureInfo.picture.dispose();
  }
}

File avatarPNGFile(int contactId) {
  final avatarsDirectory =
      Directory('$globalApplicationCacheDirectory/avatars');

  if (!avatarsDirectory.existsSync()) {
    avatarsDirectory.createSync(recursive: true);
  }
  return File('${avatarsDirectory.path}/$contactId.png');
}
