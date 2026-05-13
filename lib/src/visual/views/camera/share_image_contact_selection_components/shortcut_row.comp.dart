import 'dart:async';
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
  List<Shortcut> _shortcuts = [];
  late StreamSubscription<List<Shortcut>> shortcutSub;

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    shortcutSub = twonlyDB.shortcutsDao.watchAllShortcuts().listen((shortcuts) {
      if (_shortcuts.isEmpty) {
        shortcuts.sort((a, b) => b.usageCounter.compareTo(a.usageCounter));
        _shortcuts = shortcuts;
      } else {
        final map = {for (final s in shortcuts) s.id: s};
        final updated = <Shortcut>[];
        for (final old in _shortcuts) {
          if (map.containsKey(old.id)) {
            updated.add(map.remove(old.id)!);
          }
        }
        updated.addAll(map.values);
        _shortcuts = updated;
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(shortcutSub.cancel());
    super.dispose();
  }

  Future<void> _openCreateDialog() async {
    await context.navPush(const AddNewShortcutView());
  }

  Future<void> _applyShortcut(Shortcut shortcut) async {
    await twonlyDB.shortcutsDao.incrementUsage(shortcut.id);
    final members = await twonlyDB.shortcutsDao.getShortcutMembers(shortcut.id);
    for (final groupId in widget.selectedGroupIds.toList()) {
      widget.updateSelectedGroupIds(groupId, false);
    }
    for (final m in members) {
      widget.updateSelectedGroupIds(m.groupId, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          Row(
            children: [
              ActionChip(
                padding: EdgeInsets.zero,
                onPressed: _openCreateDialog,
                label: _shortcuts.isEmpty
                    ? Text(
                        context.lang.createShortcut,
                        style: const TextStyle(fontSize: 9),
                      )
                    : const Icon(Icons.add_reaction_outlined, size: 20),
                shape: const StadiumBorder(),
              ),
              for (final shortcut in _shortcuts)
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
      ),
    );
  }
}
