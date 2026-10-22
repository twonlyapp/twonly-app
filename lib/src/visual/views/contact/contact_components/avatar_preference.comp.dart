import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';

class AvatarPreferenceTile extends StatelessWidget {
  const AvatarPreferenceTile({required this.contact, super.key});
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    if (contact.avatarSvgCompressed == null ||
        contact.avatarSvgCompressed!.isEmpty) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<bool>(
      stream: watchRustDatabase(
        (control) => rust_contacts.watchContactPhoto(
          id: contact.userId,
          control: control,
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        final preferPhoto = contact.preferPhotoAvatar ?? true;
        return BetterListTile(
          icon: FontAwesomeIcons.circleUser,
          text: context.lang.contactAvatarTitle,
          subtitle: Text(
            preferPhoto
                ? context.lang.customAvatarPhotoTab
                : context.lang.customAvatarSvgTab,
          ),
          onTap: () async {
            final selected = await showDialog<bool>(
              context: context,
              builder: (context) => SimpleDialog(
                title: Text(context.lang.contactAvatarTitle),
                children: [
                  for (final photo in [true, false])
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, photo),
                      child: Row(
                        children: [
                          Icon(
                            photo == preferPhoto
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              photo
                                  ? context.lang.customAvatarPhotoTab
                                  : context.lang.customAvatarSvgTab,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
            if (selected == null || selected == preferPhoto) return;
            await rust_contacts.updateContact(
              id: contact.userId,
              patch: ContactPatch(
                preferPhotoAvatar: NullableInt(
                  value: databaseNullableFlag(selected),
                ),
              ),
              transaction: currentDatabaseSession(),
            );
          },
        );
      },
    );
  }
}
