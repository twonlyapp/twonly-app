import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';

class ChatReactionSelectionView extends StatefulWidget {
  const ChatReactionSelectionView({super.key});

  @override
  State<ChatReactionSelectionView> createState() =>
      _ChatReactionSelectionView();
}

class _ChatReactionSelectionView extends State<ChatReactionSelectionView> {
  List<String> _selectedEmojis = [];

  List<String> _emojisFromSession() {
    final user = userService.currentUser;
    if (user.preSelectedEmojies != null) {
      return user.preSelectedEmojies!;
    }
    return EmojiAnimationComp.animatedIcons.keys.toList().sublist(0, 6);
  }

  @override
  void initState() {
    super.initState();
    _selectedEmojis = _emojisFromSession();
  }

  Future<void> _onEmojiSelected(String emoji) async {
    if (_selectedEmojis.contains(emoji)) {
      _selectedEmojis.remove(emoji);
    } else {
      if (_selectedEmojis.length < 12) {
        _selectedEmojis.add(emoji);
        await UserService.update((user) {
          user.preSelectedEmojies = _selectedEmojis;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.lang.settingsPreSelectedReactionsError),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, _) {
        _selectedEmojis = _emojisFromSession();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Reactions'),
          ),
          body: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
            ),
            itemCount: EmojiAnimationComp.animatedIcons.keys.length,
            itemBuilder: (context, index) {
              final emoji = EmojiAnimationComp.animatedIcons.keys.elementAt(
                index,
              );
              return GestureDetector(
                onTap: () => _onEmojiSelected(emoji),
                child: Card(
                  color: _selectedEmojis.contains(emoji)
                      ? context.color.primary.withAlpha(150)
                      : context.color.surface,
                  child: Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: EmojiAnimationComp(emoji: emoji),
                    ),
                  ),
                ),
              );
            },
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: FloatingActionButton(
              foregroundColor: Colors.white,
              onPressed: () => UserService.update(
                (u) => u.preSelectedEmojies = EmojiAnimationComp
                    .animatedIcons
                    .keys
                    .toList()
                    .sublist(0, 6),
              ),
              child: const Icon(Icons.settings_backup_restore_rounded),
            ),
          ),
        );
      },
    );
  }
}
