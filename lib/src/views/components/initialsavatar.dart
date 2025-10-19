import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/utils/log.dart';

class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    super.key,
    this.contact,
    this.userData,
    this.fontSize = 20,
    this.color,
  });
  final Contact? contact;
  final UserData? userData;
  final double? fontSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    String? avatarSvg;

    if (contact != null) {
      avatarSvg = contact!.avatarSvg;
    } else if (userData != null) {
      avatarSvg = userData!.avatarSvg;
    } else {
      return Container();
    }

    final proSize = (fontSize == null) ? 40 : (fontSize! * 2);

    return Container(
      constraints: BoxConstraints(
        minHeight: 2 * (fontSize ?? 20),
        minWidth: 2 * (fontSize ?? 20),
        maxWidth: 2 * (fontSize ?? 20),
        maxHeight: 2 * (fontSize ?? 20),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: proSize as double,
            width: proSize,
            color: color,
            child: Center(
              child: avatarSvg == null
                  ? SvgPicture.asset('assets/images/default_avatar.svg')
                  : SvgPicture.string(
                      avatarSvg,
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
