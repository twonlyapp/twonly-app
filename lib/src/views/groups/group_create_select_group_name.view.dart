import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/group.services.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/user_context_menu.component.dart';

class GroupCreateSelectGroupNameView extends StatefulWidget {
  const GroupCreateSelectGroupNameView({
    required this.selectedUsers,
    super.key,
  });

  final List<Contact> selectedUsers;

  @override
  State<GroupCreateSelectGroupNameView> createState() =>
      _GroupCreateSelectGroupNameViewState();
}

class _GroupCreateSelectGroupNameViewState
    extends State<GroupCreateSelectGroupNameView> {
  final TextEditingController textFieldGroupName = TextEditingController();

  bool _isLoading = false;

  Future<void> _createNewGroup() async {
    setState(() {
      _isLoading = true;
    });

    final wasSuccess =
        await createNewGroup(textFieldGroupName.text, widget.selectedUsers);
    if (wasSuccess) {
      // POP
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.lang.selectGroupName),
        ),
        floatingActionButton: FilledButton.icon(
          onPressed: (textFieldGroupName.text.isEmpty || _isLoading)
              ? null
              : _createNewGroup,
          label: Text(context.lang.createGroup),
          icon: _isLoading
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 1,
                  ),
                )
              : const FaIcon(FontAwesomeIcons.penToSquare),
        ),
        body: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.only(bottom: 40, left: 10, top: 20, right: 10),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    onChanged: (_) async {
                      setState(() {});
                    },
                    autofocus: true,
                    controller: textFieldGroupName,
                    decoration: getInputDecoration(
                      context,
                      context.lang.groupNameInput,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: Text(context.lang.groupMembers),
                ),
                Expanded(
                  child: ListView.builder(
                    restorationId: 'new_message_users_list',
                    itemCount: widget.selectedUsers.length,
                    itemBuilder: (context, i) {
                      final user = widget.selectedUsers[i];
                      return UserContextMenu(
                        key: ValueKey(user.userId),
                        contact: user,
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(getContactDisplayName(user)),
                              FlameCounterWidget(
                                contactId: user.userId,
                                prefix: true,
                              ),
                            ],
                          ),
                          leading: AvatarIcon(
                            contactId: user.userId,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
