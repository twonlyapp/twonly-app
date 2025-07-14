// ignore_for_file: strict_raw_type

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/headline.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/views/components/verified_shield.dart';

class BestFriendsSelector extends StatelessWidget {
  const BestFriendsSelector({
    required this.users,
    required this.isRealTwonly,
    required this.updateStatus,
    required this.selectedUserIds,
    required this.title,
    super.key,
  });
  final List<Contact> users;
  final void Function(int, bool) updateStatus;
  final HashSet<int> selectedUserIds;
  final bool isRealTwonly;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Container();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: HeadLineComponent(title),
            ),
            if (!isRealTwonly)
              GestureDetector(
                onTap: () {
                  for (final user in users) {
                    updateStatus(user.userId, true);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withAlpha(50),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 10.9,
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(context.lang.shareImagedSelectAll,
                      style: const TextStyle(fontSize: 10)),
                ),
              ),
          ],
        ),
        Column(
          spacing: 8,
          children: List.generate(
            (users.length + 1) ~/ 2,
            (rowIndex) {
              final firstUserIndex = rowIndex * 2;
              final secondUserIndex = firstUserIndex + 1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: UserCheckbox(
                      isChecked: selectedUserIds
                          .contains(users[firstUserIndex].userId),
                      user: users[firstUserIndex],
                      onChanged: updateStatus,
                      isRealTwonly: isRealTwonly,
                    ),
                  ),
                  if (secondUserIndex < users.length)
                    Expanded(
                      child: UserCheckbox(
                        isChecked: selectedUserIds
                            .contains(users[secondUserIndex].userId),
                        user: users[secondUserIndex],
                        onChanged: updateStatus,
                        isRealTwonly: isRealTwonly,
                      ),
                    )
                  else
                    Expanded(
                      child: Container(),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class UserCheckbox extends StatelessWidget {
  const UserCheckbox({
    required this.user,
    required this.onChanged,
    required this.isRealTwonly,
    required this.isChecked,
    super.key,
  });
  final Contact user;
  final void Function(int, bool) onChanged;
  final bool isChecked;
  final bool isRealTwonly;

  @override
  Widget build(BuildContext context) {
    final displayName = getContactDisplayName(user);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 3), // Padding inside the container
      child: GestureDetector(
        onTap: () {
          onChanged(user.userId, !isChecked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outline.withAlpha(50),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10.9,
                color: Color.fromRGBO(0, 0, 0, 0.1),
              ),
            ],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              ContactAvatar(
                contact: user,
                fontSize: 12,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isRealTwonly)
                        Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: VerifiedShield(
                              user,
                              size: 12,
                            )),
                      Text(
                        displayName.length > 8
                            ? '${displayName.substring(0, 8)}...'
                            : displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  StreamBuilder(
                    stream: twonlyDB.contactsDao.watchFlameCounter(user.userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data! == 0) {
                        return Container();
                      }
                      return FlameCounterWidget(user, snapshot.data!);
                    },
                  )
                ],
              ),
              Expanded(child: Container()),
              Checkbox(
                value: isChecked,
                side: WidgetStateBorderSide.resolveWith(
                  (Set states) {
                    if (states.contains(WidgetState.selected)) {
                      return const BorderSide(width: 0);
                    }
                    return BorderSide(
                        color: Theme.of(context).colorScheme.outline);
                  },
                ),
                onChanged: (bool? value) {
                  onChanged(user.userId, value ?? false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
