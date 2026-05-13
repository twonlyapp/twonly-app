import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/emoji_picker.bottom.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/decorations/input_text.decoration.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';

class AddNewShortcutView extends StatefulWidget {
  const AddNewShortcutView({this.shortcut, super.key});
  final Shortcut? shortcut;
  @override
  State<AddNewShortcutView> createState() => _StartNewChatView();
}

class _StartNewChatView extends State<AddNewShortcutView> {
  List<Group> _groups = [];
  List<Group> _allGroups = [];
  final TextEditingController _searchGroupName = TextEditingController();
  late StreamSubscription<List<Group>> _groupSub;

  final HashSet<String> _selectedGroups = HashSet();
  String? shortcutEmoji;

  @override
  void initState() {
    super.initState();

    if (widget.shortcut != null) {
      shortcutEmoji = widget.shortcut!.emoji;
      twonlyDB.shortcutsDao.getShortcutMembers(widget.shortcut!.id).then((
        members,
      ) {
        if (mounted) {
          setState(() {
            for (final m in members) {
              _selectedGroups.add(m.groupId);
            }
          });
        }
      });
    }

    final stream = twonlyDB.groupsDao.watchGroupsForChatList();

    _groupSub = stream.listen((update) async {
      update.sort(
        (a, b) => a.groupName.compareTo(b.groupName),
      );
      setState(() {
        _allGroups = update;
      });
      await filterUsers();
    });
  }

  @override
  void dispose() {
    unawaited(_groupSub.cancel());
    super.dispose();
  }

  Future<void> filterUsers() async {
    if (_searchGroupName.value.text.isEmpty) {
      setState(() {
        _groups = _allGroups;
      });
      return;
    }
    final usersFiltered = _allGroups
        .where(
          (group) => group.groupName.toLowerCase().contains(
            _searchGroupName.value.text.toLowerCase(),
          ),
        )
        .toList();
    setState(() {
      _groups = usersFiltered;
    });
  }

  void toggleSelectedGroup(String groupId) {
    if (!_selectedGroups.contains(groupId)) {
      if (_selectedGroups.length > 256) {
        showSnackbar(context, context.lang.groupSizeLimitError(256));
        return;
      }
      _selectedGroups.add(groupId);
    } else {
      _selectedGroups.remove(groupId);
    }
    setState(() {});
  }

  Future<void> submitChanges() async {
    try {
      if (widget.shortcut != null) {
        await twonlyDB.shortcutsDao.updateShortcut(
          widget.shortcut!.id,
          shortcutEmoji!,
        );
        await twonlyDB.shortcutsDao.deleteShortcutMembers(widget.shortcut!.id);
        await twonlyDB.shortcutsDao.addShortcutMembers(
          widget.shortcut!.id,
          _selectedGroups.toList(),
        );
      } else {
        await twonlyDB.shortcutsDao.createShortcut(
          shortcutEmoji!,
        );
        final shortcutId = (await twonlyDB.shortcutsDao.getShortcutByEmoji(
          shortcutEmoji!,
        ))!.id;
        await twonlyDB.shortcutsDao.deleteShortcutMembers(shortcutId);
        await twonlyDB.shortcutsDao.addShortcutMembers(
          shortcutId,
          _selectedGroups.toList(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Log.error(e);
      if (mounted) {
        showSnackbar(context, context.lang.errorEmojiUsedOrInvalid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.shortcut == null
                ? context.lang.createShortcut
                : context.lang.editShortcut,
          ),
          actions: [
            if (widget.shortcut != null)
              IconButton(
                icon: const FaIcon(
                  FontAwesomeIcons.trashCan,
                  size: 18,
                  color: Colors.red,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.lang.deleteShortcut),
                      content: Text(context.lang.deleteShortcutBody),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(context.lang.cancel),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(context.lang.delete),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await twonlyDB.shortcutsDao.deleteShortcut(
                      widget.shortcut!.id,
                    );
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            TextButton(
              onPressed: () async {
                // ignore: inference_failure_on_function_invocation
                final result = await showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.black,
                  builder: (context) => const EmojiPickerBottom(),
                );
                if (result is EmojiLayerData) {
                  setState(() {
                    shortcutEmoji = result.text;
                  });
                }
              },
              child: Text(
                shortcutEmoji ?? context.lang.selectEmoji,
                style: TextStyle(
                  fontSize: shortcutEmoji == null ? 14 : 22,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: FilledButton.icon(
          onPressed: (_selectedGroups.isEmpty || shortcutEmoji == null)
              ? null
              : submitChanges,
          label: Text(
            widget.shortcut == null
                ? context.lang.createShortcut
                : context.lang.updateShortcut,
          ),
          icon: const FaIcon(FontAwesomeIcons.check),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 40,
              left: 10,
              top: 20,
              right: 10,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    onChanged: (_) async {
                      await filterUsers();
                    },
                    controller: _searchGroupName,
                    decoration: getInputDecoration(
                      context,
                      context.lang.shareImageSearchAllContacts,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    restorationId: 'new_message_users_list',
                    itemCount: _groups.length,
                    itemBuilder: (context, i) {
                      final group = _groups[i];
                      return ListTile(
                        key: ValueKey(group.groupId),
                        title: Row(
                          children: [
                            Text(substringBy(group.groupName, 12)),
                            FlameCounterWidget(
                              groupId: group.groupId,
                              prefix: true,
                            ),
                          ],
                        ),
                        leading: AvatarIcon(
                          group: group,
                          fontSize: 15,
                        ),
                        trailing: Checkbox(
                          value: _selectedGroups.contains(group.groupId),
                          side: WidgetStateBorderSide.resolveWith(
                            (states) {
                              if (states.contains(WidgetState.selected)) {
                                return const BorderSide(width: 0);
                              }
                              return BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              );
                            },
                          ),
                          onChanged: (value) {
                            toggleSelectedGroup(group.groupId);
                          },
                        ),
                        onTap: () {
                          toggleSelectedGroup(group.groupId);
                        },
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
