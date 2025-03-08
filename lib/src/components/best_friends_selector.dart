import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:twonly/src/components/verified_shield.dart';
import 'package:twonly/src/database/contacts_db.dart';
import 'package:twonly/src/database/database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/components/flame.dart';
import 'package:twonly/src/components/headline.dart';
import 'package:twonly/src/components/initialsavatar.dart';

class BestFriendsSelector extends StatelessWidget {
  final List<Contact> users;
  final Function(int, bool) updateStatus;
  final HashSet<int> selectedUserIds;
  final int maxTotalMediaCounter;
  final bool isRealTwonly;

  const BestFriendsSelector({
    super.key,
    required this.users,
    required this.maxTotalMediaCounter,
    required this.isRealTwonly,
    required this.updateStatus,
    required this.selectedUserIds,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Container();
    }

    return Column(
      children: [
        HeadLineComponent(context.lang.shareImageBestFriends),
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
                      maxTotalMediaCounter: maxTotalMediaCounter,
                    ),
                  ),
                  (secondUserIndex < users.length)
                      ? Expanded(
                          child: UserCheckbox(
                              isChecked: selectedUserIds
                                  .contains(users[secondUserIndex].userId),
                              user: users[secondUserIndex],
                              onChanged: updateStatus,
                              isRealTwonly: isRealTwonly,
                              maxTotalMediaCounter: maxTotalMediaCounter),
                        )
                      : Expanded(
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
  final Contact user;
  final Function(int, bool) onChanged;
  final bool isChecked;
  final bool isRealTwonly;
  final int maxTotalMediaCounter;

  const UserCheckbox({
    super.key,
    required this.user,
    required this.maxTotalMediaCounter,
    required this.onChanged,
    required this.isRealTwonly,
    required this.isChecked,
  });

  @override
  Widget build(BuildContext context) {
    String displayName = getContactDisplayName(user);

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 3), // Padding inside the container
      child: GestureDetector(
        onTap: () {
          onChanged(user.userId, !isChecked);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              InitialsAvatar(
                displayName,
                fontSize: 12,
              ),
              SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isRealTwonly)
                        Padding(
                            padding: EdgeInsets.only(right: 2),
                            child: VerifiedShield(
                              user,
                              size: 12,
                            )),
                      Text(
                        displayName.length > 10
                            ? '${displayName.substring(0, 10)}...'
                            : displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  StreamBuilder(
                    stream: context.db.watchFlameCounter(user.userId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData && snapshot.data! != 0) {
                        return Container();
                      }
                      return FlameCounterWidget(
                          user, snapshot.data!, maxTotalMediaCounter);
                    },
                  )
                ],
              ),
              Expanded(child: Container()),
              Checkbox(
                value: isChecked,
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
