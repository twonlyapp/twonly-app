import 'dart:collection';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twonly/src/components/flame.dart';
import 'package:twonly/src/components/headline.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/model/contacts_model.dart';

class BestFriendsSelector extends StatelessWidget {
  final List<Contact> users;
  final Function(Int64, bool) updateStatus;
  final HashSet<Int64> selectedUserIds;
  final int maxTotalMediaCounter;

  const BestFriendsSelector({
    super.key,
    required this.users,
    required this.maxTotalMediaCounter,
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
        HeadLineComponent(AppLocalizations.of(context)!.shareImageBestFriends),
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
  final Function(Int64, bool) onChanged;
  final bool isChecked;
  final int maxTotalMediaCounter;

  const UserCheckbox({
    super.key,
    required this.user,
    required this.maxTotalMediaCounter,
    required this.onChanged,
    required this.isChecked,
  });

  @override
  Widget build(BuildContext context) {
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
                fontSize: 15,
                displayName: user.displayName,
              ),
              SizedBox(width: 8),
              Text(
                user.displayName.length > 10
                    ? '${user.displayName.substring(0, 10)}...'
                    : user.displayName,
                overflow: TextOverflow.ellipsis,
              ),
              if (user.flameCounter > 0)
                FlameCounterWidget(user, maxTotalMediaCounter),
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
