import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/avatars.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:vector_graphics/vector_graphics.dart';

class AvatarIcon extends StatefulWidget {
  const AvatarIcon({
    super.key,
    this.group,
    this.contactId,
    this.myAvatar = false,
    this.fontSize = 20,
    this.color,
  });
  final Group? group;
  final int? contactId;
  final bool myAvatar;
  final double? fontSize;
  final Color? color;

  @override
  State<AvatarIcon> createState() => _AvatarIconState();
}

class _AvatarIconState extends State<AvatarIcon> {
  List<Contact> _avatarContacts = [];
  String? _globalUserDataCallBackId;
  String? _avatarSvg;

  StreamSubscription<List<Contact>>? groupStream;
  StreamSubscription<List<Contact>>? contactsStream;
  StreamSubscription<Contact?>? contactStream;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  @override
  void dispose() {
    groupStream?.cancel();
    contactStream?.cancel();
    contactsStream?.cancel();
    if (_globalUserDataCallBackId != null) {
      globalUserDataChangedCallBack.remove(_globalUserDataCallBackId);
    }
    super.dispose();
  }

  // ignore: strict_top_level_inference
  Widget errorBuilder(_, __, ___) {
    return const SvgPicture(
      AssetBytesLoader('assets/images/default_avatar.svg.vec'),
    );
  }

  Widget getAvatarForContact(Contact contact) {
    final avatarFile = avatarPNGFile(contact.userId);
    if (avatarFile.existsSync()) {
      return Image.file(
        avatarFile,
        errorBuilder: errorBuilder,
      );
    }
    if (contact.avatarSvgCompressed != null) {
      return SvgPicture.string(
        getAvatarSvg(contact.avatarSvgCompressed!),
        errorBuilder: errorBuilder,
      );
    }
    return errorBuilder(null, null, null);
  }

  Future<void> initAsync() async {
    if (widget.group != null) {
      groupStream = twonlyDB.groupsDao
          .watchGroupContact(widget.group!.groupId)
          .listen((contacts) {
        _avatarContacts = [];
        if (contacts.length == 1) {
          if (contacts.first.avatarSvgCompressed != null) {
            _avatarContacts.add(contacts.first);
          }
        } else {
          for (final contact in contacts) {
            if (contact.avatarSvgCompressed != null) {
              _avatarContacts.add(contact);
            }
          }
        }
        setState(() {});
      });
    } else if (widget.myAvatar) {
      _globalUserDataCallBackId = 'avatar_${getRandomString(10)}';
      globalUserDataChangedCallBack[_globalUserDataCallBackId!] = () {
        setState(() {
          if (gUser.avatarSvg != null) {
            _avatarSvg = gUser.avatarSvg;
          } else {
            _avatarContacts = [];
          }
        });
      };
      if (gUser.avatarSvg != null) {
        _avatarSvg = gUser.avatarSvg;
      }
    } else if (widget.contactId != null) {
      contactStream = twonlyDB.contactsDao
          .watchContact(widget.contactId!)
          .listen((contact) {
        if (contact != null && contact.avatarSvgCompressed != null) {
          _avatarContacts = [contact];
          setState(() {});
        }
      });
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final proSize = (widget.fontSize == null) ? 40 : (widget.fontSize! * 2);

    Widget avatars = Container();

    if (_avatarSvg != null) {
      avatars = SvgPicture.string(
        _avatarSvg!,
        errorBuilder: errorBuilder,
      );
    } else if (_avatarContacts.length == 1) {
      avatars = getAvatarForContact(_avatarContacts.first);
    } else if (_avatarContacts.length >= 2) {
      final a = getAvatarForContact(_avatarContacts.first);
      final b = getAvatarForContact(_avatarContacts[1]);
      if (_avatarContacts.length >= 3) {
        final c = getAvatarForContact(_avatarContacts[2]);
        avatars = Stack(
          children: [
            Transform.translate(
              offset: const Offset(-15, 5),
              child: Transform.scale(
                scale: 0.8,
                child: c,
              ),
            ),
            Transform.translate(
              offset: const Offset(15, 5),
              child: Transform.scale(
                scale: 0.8,
                child: b,
              ),
            ),
            a,
          ],
        );
      } else {
        avatars = Stack(
          children: [
            Transform.translate(
              offset: const Offset(-10, 5),
              child: Transform.scale(
                scale: 0.8,
                child: b,
              ),
            ),
            Transform.translate(offset: const Offset(10, 0), child: a),
          ],
        );
      }
    } else {
      avatars = const SvgPicture(
        AssetBytesLoader('assets/images/default_avatar.svg.vec'),
      );
    }

    return Container(
      constraints: BoxConstraints(
        minHeight: 2 * (widget.fontSize ?? 20),
        minWidth: 2 * (widget.fontSize ?? 20),
        maxWidth: 2 * (widget.fontSize ?? 20),
        maxHeight: 2 * (widget.fontSize ?? 20),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: proSize as double,
            width: proSize,
            color: widget.color,
            child: Center(child: avatars),
          ),
        ),
      ),
    );
  }
}
