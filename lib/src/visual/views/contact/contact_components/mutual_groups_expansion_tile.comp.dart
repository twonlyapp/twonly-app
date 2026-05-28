import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';

class MutualGroupsExpansionTileComp extends StatefulWidget {
  const MutualGroupsExpansionTileComp({
    required this.contact,
    super.key,
  });

  final Contact contact;

  @override
  State<MutualGroupsExpansionTileComp> createState() =>
      _MutualGroupsExpansionTileCompState();
}

class _MutualGroupsExpansionTileCompState
    extends State<MutualGroupsExpansionTileComp> {
  List<Group> _groups = [];
  late StreamSubscription<List<Group>> _streamGroups;
  bool? _hasInitializedExpanded;

  @override
  void initState() {
    super.initState();
    _streamGroups = twonlyDB.groupsDao
        .watchNonDirectGroupsForMember(widget.contact.userId)
        .listen((groupsList) {
          if (!mounted) return;
          setState(() {
            _groups = groupsList;
            _groups.sort((a, b) {
              return b.totalMediaCounter.compareTo(a.totalMediaCounter);
            });
            _hasInitializedExpanded ??= true;
          });
        });
  }

  @override
  void dispose() {
    _streamGroups.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasInitializedExpanded == null || _groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      key: PageStorageKey<String>('mutual_groups_${widget.contact.userId}'),
      shape: const RoundedRectangleBorder(),
      backgroundColor: context.color.surfaceContainer,
      collapsedShape: const RoundedRectangleBorder(),
      onExpansionChanged: (expanded) {
        setState(() {});
      },
      leading: Padding(
        padding: const EdgeInsets.only(left: 14, right: 14),
        child: SizedBox(
          width: 20,
          height: 20,
          child: FaIcon(
            FontAwesomeIcons.userGroup,
            size: 16,
            color: context.color.onSurfaceVariant,
          ),
        ),
      ),
      title: Text(
        context.lang.mutualGroupsTitle(_groups.length),
        style: TextStyle(
          color: context.color.onSurface,
        ),
      ),
      children: _groups.map((group) {
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: AvatarIcon(
            group: group,
            fontSize: 14,
          ),
          title: Text(
            group.groupName,
            style: TextStyle(
              color: context.color.onSurface,
              fontWeight: FontWeight.w400,
            ),
          ),
          onTap: () {
            context.push(Routes.chatsMessages(group.groupId));
          },
        );
      }).toList(),
    );
  }
}
