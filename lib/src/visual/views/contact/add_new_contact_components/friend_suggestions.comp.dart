import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/daos/user_discovery.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/elements/headline.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/groups/group.view.dart';

List<TextSpan> buildFriendsListText(
  BuildContext context,
  List<(Contact, DateTime?)> friends,
) {
  final names = friends.map((f) => getContactDisplayName(f.$1)).toList();
  return buildFriendsListTextString(context, names);
}

List<TextSpan> buildFriendsListTextString(
  BuildContext context,
  List<String> friends,
) {
  final names = friends.map((f) => '*$f*').toList();

  return formattedText(
    context,
    context.lang.friendSuggestionsFriendsWith(
      joinWithAnd(names, context.lang.andWord),
    ),
  );
}

class FriendSuggestionsComp extends StatelessWidget {
  const FriendSuggestionsComp(this.announcedUsers, {super.key});

  final AnnouncedUsersWithRelations announcedUsers;

  Future<void> _requestAnnouncedUser(
    BuildContext context,
    UserDiscoveryAnnouncedUser user,
  ) async {
    Log.info('Requesting user via friend suggestions');

    final userdata = await apiService.getUserById(user.announcedUserId);

    if (userdata == null) {
      if (context.mounted) {
        showNetworkIssue(context);
      }
      return;
    }

    final added = await twonlyDB.contactsDao.insertOnConflictUpdate(
      ContactsCompanion(
        username: Value(user.username!),
        userId: Value(userdata.userId.toInt()),
        requested: const Value(false),
        blocked: const Value(false),
        deletedByUser: const Value(false),
      ),
    );

    if (added > 0) await importSignalContactAndCreateRequest(userdata);

    await UserService.update(
      (u) => u.userStudyCountNewFriendsViaSuggestion += 1,
    );
  }

  Future<void> _hideAnnouncedUser(int userId) async {
    await twonlyDB.userDiscoveryDao.updateAnnouncedUser(
      userId,
      const UserDiscoveryAnnouncedUsersCompanion(
        isHidden: Value(true),
      ),
    );
  }

  Future<void> _askFriends(
    BuildContext context,
    UserDiscoveryAnnouncedUser user,
    List<(Contact, DateTime?)> friends,
  ) async {
    Log.info('Asking friends about user: ${user.announcedUserId}');
    final selectedFriends = <int>{};
    final username = user.username ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(context.lang.askFriendsDialogTitle(username)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.lang.askFriendsDialogDescription),
                  const SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: friends.map((f) {
                          final contact = f.$1;
                          final isSelected =
                              selectedFriends.contains(contact.userId);
                          return CheckboxListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(contact.displayName ?? contact.username),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedFriends.add(contact.userId);
                                } else {
                                  selectedFriends.remove(contact.userId);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.lang.askFriendsDialogCancel),
                ),
                TextButton(
                  onPressed: selectedFriends.isEmpty
                      ? null
                      : () => Navigator.pop(context, true),
                  child: Text(context.lang.askFriendsDialogConfirm),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && selectedFriends.isNotEmpty) {
      for (final contactId in selectedFriends) {
        await insertAndSendAskAboutUserMessage(contactId, user.announcedUserId);
      }
      
      await twonlyDB.userDiscoveryDao.updateAnnouncedUser(
        user.announcedUserId,
        const UserDiscoveryAnnouncedUsersCompanion(
          wasAskedFriends: Value(true),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (announcedUsers.isEmpty) return Container();
    return Column(
      children: [
        const SizedBox(height: 20),
        HeadLineComp(
          context.lang.friendSuggestionsTitle,
        ),
        ...announcedUsers.entries.map((
          announcedUser,
        ) {
          final user = announcedUser.key;
          final friends = announcedUser.value;

          final friendsList = buildFriendsListText(context, friends);

          return Padding(
            key: ValueKey(user.announcedUserId),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const AvatarIcon(
                  fontSize: 17,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        substringBy(user.username!, 25),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<List<Group>>(
                        stream: twonlyDB.groupsDao
                            .watchNonDirectGroupsForMember(
                              user.announcedUserId,
                            ),
                        builder: (context, snapshot) {
                          var text = friendsList;
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            text += formattedText(
                              context,
                              context.lang.friendSuggestionsGroupMemberIn(
                                joinWithAnd(
                                  snapshot.data!
                                      .map((g) => '*${g.groupName}*')
                                      .toList(),
                                  context.lang.andWord,
                                ),
                              ),
                            );
                          }
                          return RichText(
                            text: TextSpan(
                              children: text,
                              style: TextStyle(
                                fontSize: 11,
                                color: context.color.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!user.wasAskedFriends) ...[
                          SizedBox(
                            height: 28,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.only(
                                  right: 8,
                                  left: 4,
                                ),
                              ).merge(secondaryGreyButtonStyle(context)),
                              onPressed: () => _askFriends(context, user, friends),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: FaIcon(
                                      FontAwesomeIcons.circleQuestion,
                                      size: 12,
                                    ),
                                  ),
                                  Text(
                                    context.lang.friendSuggestionsAskFriend,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        SizedBox(
                          height: 26,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.only(
                                right: 8,
                                left: 4,
                              ),
                            ).merge(secondaryGreyButtonStyle(context)),
                            onPressed: () =>
                                _requestAnnouncedUser(context, user),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: FaIcon(
                                    FontAwesomeIcons.userPlus,
                                    size: 12,
                                  ),
                                ),
                                Text(
                                  context.lang.friendSuggestionsRequest,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _hideAnnouncedUser(user.announcedUserId),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
