import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/camera/add_new_shortcut.view.dart';

class ShortcutRowComp extends StatefulWidget {
  const ShortcutRowComp({
    required this.selectedGroupIds,
    required this.updateSelectedGroupIds,
    super.key,
  });

  final HashSet<String> selectedGroupIds;
  final void Function(String, bool) updateSelectedGroupIds;

  @override
  State<ShortcutRowComp> createState() => _ShortcutRowCompState();
}

class _ShortcutRowCompState extends State<ShortcutRowComp> {
  Future<void> _openCreateDialog() async {
    await context.navPush(const AddNewShortcutView());
  }

  Future<void> _applyShortcut(Shortcut shortcut) async {
    await twonlyDB.shortcutsDao.incrementUsage(shortcut.id);
    final members = await twonlyDB.shortcutsDao.getShortcutMembers(shortcut.id);
    for (final m in members) {
      widget.updateSelectedGroupIds(m.groupId, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: StreamBuilder<List<Shortcut>>(
        stream: twonlyDB.shortcutsDao.watchAllShortcuts(),
        builder: (context, snapshot) {
          final shortcuts = snapshot.data ?? [];
          return ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Row(
                children: [
                  ActionChip(
                    padding: EdgeInsets.zero,
                    onPressed: _openCreateDialog,
                    label: shortcuts.isEmpty
                        ? Text(
                            context.lang.createShortcut,
                            style: const TextStyle(fontSize: 9),
                          )
                        : const Icon(Icons.add_reaction_outlined, size: 20),
                    shape: const StadiumBorder(),
                  ),
                  for (final shortcut in shortcuts)
                    GestureDetector(
                      onLongPress: () {
                        context.navPush(AddNewShortcutView(shortcut: shortcut));
                      },
                      child: ActionChip(
                        padding: EdgeInsets.zero,
                        onPressed: () => _applyShortcut(shortcut),
                        label: Text(
                          shortcut.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        shape: const StadiumBorder(),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
