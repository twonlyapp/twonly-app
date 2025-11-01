import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/utils/misc.dart';

class AvatarIcon extends StatefulWidget {
  const AvatarIcon({
    super.key,
    this.group,
    this.contact,
    this.contactId,
    this.userData,
    this.fontSize = 20,
    this.color,
  });
  final Group? group;
  final Contact? contact;
  final int? contactId;
  final UserData? userData;
  final double? fontSize;
  final Color? color;

  @override
  State<AvatarIcon> createState() => _AvatarIconState();
}

class _AvatarIconState extends State<AvatarIcon> {
  final List<String> _avatarSVGs = [];

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    if (widget.group != null) {
      final contacts =
          await twonlyDB.groupsDao.getGroupContact(widget.group!.groupId);
      if (contacts.length == 1) {
        if (contacts.first.avatarSvgCompressed != null) {
          _avatarSVGs.add(getAvatarSvg(contacts.first.avatarSvgCompressed!));
        }
      } else {
        for (final contact in contacts) {
          if (contact.avatarSvgCompressed != null) {
            _avatarSVGs.add(getAvatarSvg(contact.avatarSvgCompressed!));
          }
        }
      }
      // avatarSvg = group!.avatarSvg;
    } else if (widget.userData?.avatarSvg != null) {
      _avatarSVGs.add(widget.userData!.avatarSvg!);
    } else if (widget.contact?.avatarSvgCompressed != null) {
      _avatarSVGs.add(getAvatarSvg(widget.contact!.avatarSvgCompressed!));
    } else if (widget.contactId != null) {
      final contact =
          await twonlyDB.contactsDao.getContactById(widget.contactId!);
      if (contact != null && contact.avatarSvgCompressed != null) {
        _avatarSVGs.add(getAvatarSvg(contact.avatarSvgCompressed!));
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final proSize = (widget.fontSize == null) ? 40 : (widget.fontSize! * 2);

    Widget avatars = SvgPicture.asset('assets/images/default_avatar.svg');

    if (_avatarSVGs.length == 1) {
      avatars = SvgPicture.string(
        _avatarSVGs.first,
        errorBuilder: (a, b, c) => avatars,
      );
    } else if (_avatarSVGs.length >= 2) {
      final a = SvgPicture.string(
        _avatarSVGs.first,
        errorBuilder: (a, b, c) => avatars,
      );
      final b = SvgPicture.string(
        _avatarSVGs[1],
        errorBuilder: (a, b, c) => avatars,
      );
      if (_avatarSVGs.length >= 3) {
        final c = SvgPicture.string(
          _avatarSVGs[2],
          errorBuilder: (a, b, c) => avatars,
        );
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
