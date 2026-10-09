import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
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
      stream: twonlyDB.contactsDao.watchHasPhotoAvatar(contact.userId),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        final preferPhoto = contact.preferPhotoAvatar ?? true;
        return BetterListTile(
          icon: Icons.account_circle_outlined,
          text: context.lang.contactAvatarTitle,
          subtitle: Text(
            preferPhoto
                ? context.lang.contactAvatarPhoto
                : context.lang.contactAvatarIllustrated,
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
                                  ? context.lang.contactAvatarPhoto
                                  : context.lang.contactAvatarIllustrated,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
            if (selected == null || selected == preferPhoto) return;
            await twonlyDB.contactsDao.updateContact(
              contact.userId,
              ContactsCompanion(preferPhotoAvatar: Value(selected)),
            );
          },
        );
      },
    );
  }
}
