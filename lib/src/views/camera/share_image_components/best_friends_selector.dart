import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/headline.dart';

class BestFriendsSelector extends StatelessWidget {
  const BestFriendsSelector({
    required this.groups,
    required this.selectedGroupIds,
    required this.updateSelectedGroupIds,
    required this.title,
    required this.showSelectAll,
    super.key,
  });
  final List<Group> groups;
  final HashSet<String> selectedGroupIds;
  final void Function(String, bool) updateSelectedGroupIds;
  final String title;
  final bool showSelectAll;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Container();
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: HeadLineComponent(title),
            ),
            if (showSelectAll)
              GestureDetector(
                onTap: () {
                  for (final group in groups) {
                    updateSelectedGroupIds(group.groupId, true);
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    context.lang.shareImagedSelectAll,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        Column(
          spacing: 8,
          children: List.generate(
            (groups.length + 1) ~/ 2,
            (rowIndex) {
              final firstUserIndex = rowIndex * 2;
              final secondUserIndex = firstUserIndex + 1;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: UserCheckbox(
                      key: ValueKey(groups[firstUserIndex]),
                      isChecked: selectedGroupIds
                          .contains(groups[firstUserIndex].groupId),
                      group: groups[firstUserIndex],
                      onChanged: updateSelectedGroupIds,
                    ),
                  ),
                  if (secondUserIndex < groups.length)
                    Expanded(
                      child: UserCheckbox(
                        key: ValueKey(groups[secondUserIndex]),
                        isChecked: selectedGroupIds
                            .contains(groups[secondUserIndex].groupId),
                        group: groups[secondUserIndex],
                        onChanged: updateSelectedGroupIds,
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
    required this.group,
    required this.onChanged,
    required this.isChecked,
    super.key,
  });
  final Group group;
  final void Function(String, bool) onChanged;
  final bool isChecked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 3,
      ), // Padding inside the container
      child: GestureDetector(
        onTap: () {
          onChanged(group.groupId, !isChecked);
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              AvatarIcon(
                group: group,
                fontSize: 12,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        substringBy(group.groupName, 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  FlameCounterWidget(groupId: group.groupId),
                ],
              ),
              Expanded(child: Container()),
              Checkbox(
                value: isChecked,
                side: WidgetStateBorderSide.resolveWith(
                  // ignore: strict_raw_type
                  (Set states) {
                    if (states.contains(WidgetState.selected)) {
                      return const BorderSide(width: 0);
                    }
                    return BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    );
                  },
                ),
                onChanged: (bool? value) {
                  onChanged(group.groupId, value ?? false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
