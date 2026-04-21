import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/daos/user_discovery.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/utils.api.dart';
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
  final names = friends.map((f) => '*${getContactDisplayName(f.$1)}*').toList();

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
  }

  Future<void> _hideAnnouncedUser(int userId) async {
    await twonlyDB.userDiscoveryDao.updateAnnouncedUser(
      userId,
      const UserDiscoveryAnnouncedUsersCompanion(
        isHidden: Value(true),
      ),
    );
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

          return ListTile(
            key: ValueKey(user.announcedUserId),
            contentPadding: EdgeInsets.zero,
            title: Text(substringBy(user.username!, 25)),
            subtitle: StreamBuilder(
              stream: twonlyDB.groupsDao.watchNonDirectGroupsForMember(
                user.announcedUserId,
              ),
              builder: (context, snapshot) {
                var text = friendsList;
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  text += formattedText(
                    context,
                    context.lang.friendSuggestionsGroupMemberIn(
                      joinWithAnd(
                        snapshot.data!.map((g) => '*${g.groupName}*').toList(),
                        context.lang.andWord,
                      ),
                    ),
                  );
                }
                return RichText(
                  text: TextSpan(
                    children: text,
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),

            leading: const AvatarIcon(
              fontSize: 17,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 26,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.only(right: 8, left: 4),
                    ).merge(secondaryGreyButtonStyle(context)),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: FaIcon(FontAwesomeIcons.userPlus, size: 12),
                        ),
                        Text(
                          context.lang.friendSuggestionsRequest,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    onPressed: () => _requestAnnouncedUser(context, user),
                  ),
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
          );
        }),
      ],
    );
  }
}
