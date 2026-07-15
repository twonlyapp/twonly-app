import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';

class ChatReactionSelectionView extends StatefulWidget {
  const ChatReactionSelectionView({super.key});

  @override
  State<ChatReactionSelectionView> createState() =>
      _ChatReactionSelectionView();
}

class _ChatReactionSelectionView extends State<ChatReactionSelectionView> {
  List<String> _selectedEmojis = [];

  /// Cache the emoji keys list once to avoid repeated Map.keys.toList() calls.
  static final List<String> _allEmojis = EmojiAnimationComp.animatedIcons.keys
      .toList();

  List<String> _emojisFromSession() {
    final user = userService.currentUser;
    if (user.preSelectedEmojies != null) {
      return user.preSelectedEmojies!;
    }
    return _allEmojis.sublist(0, 6);
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
        showSnackbar(context, context.lang.settingsPreSelectedReactionsError);
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
            itemCount: _allEmojis.length,
            itemBuilder: (context, index) {
              final emoji = _allEmojis[index];
              final isSelected = _selectedEmojis.contains(emoji);
              return GestureDetector(
                onTap: () => _onEmojiSelected(emoji),
                child: Card(
                  color: isSelected
                      ? context.color.primary.withAlpha(150)
                      : context.color.surface,
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
