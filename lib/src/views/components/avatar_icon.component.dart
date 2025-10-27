import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

class AvatarIcon extends StatefulWidget {
  const AvatarIcon({
    super.key,
    this.group,
    this.contact,
    this.userData,
    this.fontSize = 20,
    this.color,
  });
  final Group? group;
  final Contact? contact;
  final UserData? userData;
  final double? fontSize;
  final Color? color;

  @override
  State<AvatarIcon> createState() => _AvatarIconState();
}

class _AvatarIconState extends State<AvatarIcon> {
  List<String> avatarSVGs = [];

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
          avatarSVGs.add(getAvatarSvg(contacts.first.avatarSvgCompressed!));
        }
      } else {
        for (final contact in contacts) {
          if (contact.avatarSvgCompressed != null) {
            avatarSVGs.add(getAvatarSvg(contact.avatarSvgCompressed!));
          }
        }
      }
      // avatarSvg = group!.avatarSvg;
    } else if (widget.userData?.avatarSvg != null) {
      avatarSVGs.add(widget.userData!.avatarSvg!);
    } else if (widget.contact?.avatarSvgCompressed != null) {
      avatarSVGs.add(getAvatarSvg(widget.contact!.avatarSvgCompressed!));
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final proSize = (widget.fontSize == null) ? 40 : (widget.fontSize! * 2);

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
            child: Center(
              child: avatarSVGs.isEmpty
                  ? SvgPicture.asset('assets/images/default_avatar.svg')
                  : SvgPicture.string(
                      avatarSVGs.first,
                      errorBuilder: (context, error, stackTrace) {
                        Log.error('$error');
                        return Container();
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
