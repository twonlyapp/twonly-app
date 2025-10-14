import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

class ChatReactionSelectionView extends StatefulWidget {
  const ChatReactionSelectionView({super.key});

  @override
  State<ChatReactionSelectionView> createState() =>
      _ChatReactionSelectionView();
}

class _ChatReactionSelectionView extends State<ChatReactionSelectionView> {
  List<String> selectedEmojis = [];

  @override
  Future<void> initState() async {
    super.initState();
    await initAsync();
  }

  Future<void> initAsync() async {
    final user = await getUser();
    if (user != null && user.preSelectedEmojies != null) {
      selectedEmojis = user.preSelectedEmojies!;
    } else {
      selectedEmojis = EmojiAnimation.animatedIcons.keys.toList().sublist(0, 6);
    }
    setState(() {});
  }

  Future<void> _onEmojiSelected(String emoji) async {
    if (selectedEmojis.contains(emoji)) {
      selectedEmojis.remove(emoji);
    } else {
      if (selectedEmojis.length < 12) {
        selectedEmojis.add(emoji);
        await updateUserdata((user) {
          user.preSelectedEmojies = selectedEmojis;
          return user;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Reactions'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // Number of columns
        ),
        itemCount: EmojiAnimation.animatedIcons.keys.length,
        itemBuilder: (context, index) {
          final emoji = EmojiAnimation.animatedIcons.keys.elementAt(index);
          return GestureDetector(
            onTap: () async {
              await _onEmojiSelected(emoji);
            },
            child: Card(
              color: selectedEmojis.contains(emoji)
                  ? context.color.primary.withAlpha(150)
                  : context.color.surface,
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: EmojiAnimation(
                    emoji: emoji,
                    // repeat: selectedEmojis.contains(emoji),
                  ),
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
          onPressed: () async {
            selectedEmojis =
                EmojiAnimation.animatedIcons.keys.toList().sublist(0, 6);
            setState(() {});
            await updateUserdata((user) {
              user.preSelectedEmojies = selectedEmojis;
              return user;
            });
          },
          child: const Icon(Icons.settings_backup_restore_rounded),
        ),
      ),
    );
  }
}
