import 'package:flutter/material.dart';
import 'package:twonly/src/components/animate_icon.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

class ChatReactionSelectionView extends StatefulWidget {
  const ChatReactionSelectionView({super.key});

  @override
  State<ChatReactionSelectionView> createState() =>
      _ChatReactionSelectionView();
}

class _ChatReactionSelectionView extends State<ChatReactionSelectionView> {
  List<String> selectedEmojis = [];

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    var user = await getUser();
    if (user != null && user.preSelectedEmojies != null) {
      selectedEmojis = user.preSelectedEmojies!;
    } else {
      selectedEmojis = EmojiAnimation.animatedIcons.keys.toList().sublist(0, 6);
    }
    setState(() {});
  }

  void _onEmojiSelected(String emoji) async {
    if (selectedEmojis.contains(emoji)) {
      selectedEmojis.remove(emoji);
    } else {
      if (selectedEmojis.length < 6) {
        selectedEmojis.add(emoji);
        var user = await getUser();
        if (user != null) {
          user.preSelectedEmojies = selectedEmojis;
          await updateUser(user);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.lang.settingsPreSelectedReactionsError),
            duration: Duration(seconds: 3),
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
        title: Text('Select Reactions'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // Number of columns
          childAspectRatio: 1.0, // Aspect ratio of each item
        ),
        itemCount: EmojiAnimation.animatedIcons.keys.length,
        itemBuilder: (context, index) {
          String emoji = EmojiAnimation.animatedIcons.keys.elementAt(index);
          return GestureDetector(
            onTap: () {
              _onEmojiSelected(emoji);
            },
            child: Card(
              color: selectedEmojis.contains(emoji)
                  ? context.color.primary.withAlpha(150)
                  : context.color.surface,
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: EmojiAnimation(emoji: emoji),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
