import 'package:flutter/material.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/image_editor/data/data.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';

class Emojis extends StatefulWidget {
  const Emojis({super.key});

  @override
  createState() => _EmojisState();
}

class _EmojisState extends State<Emojis> {
  List<String> lastUsed = emojis;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    final user = await getUser();
    if (user == null) return;
    setState(() {
      lastUsed = user.lastUsedEditorEmojis ?? [];
      lastUsed.addAll(emojis);
    });
  }

  Future selectEmojis(String emoji) async {
    final user = await getUser();
    if (user == null) return;
    if (user.lastUsedEditorEmojis == null) {
      user.lastUsedEditorEmojis = [emoji];
    } else {
      if (user.lastUsedEditorEmojis!.contains(emoji)) {
        user.lastUsedEditorEmojis!.remove(emoji);
      }
      user.lastUsedEditorEmojis!.insert(0, emoji);
      if (user.lastUsedEditorEmojis!.length > 12) {
        user.lastUsedEditorEmojis = user.lastUsedEditorEmojis!.sublist(0, 12);
      }
      user.lastUsedEditorEmojis!.toSet().toList();
    }
    await updateUser(user);
    if (!context.mounted) return;
    Navigator.pop(
      context,
      EmojiLayerData(
        text: emoji,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(0.0),
        height: 400,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              blurRadius: 10.9,
              color: Color.fromRGBO(0, 0, 0, 0.1),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              height: 315,
              padding: const EdgeInsets.all(0.0),
              child: GridView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.vertical,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  mainAxisSpacing: 0.0,
                  maxCrossAxisExtent: 60.0,
                ),
                children: lastUsed.map((String emoji) {
                  return GridTile(
                      child: GestureDetector(
                    onTap: () {
                      selectEmojis(emoji);
                    },
                    child: Container(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.center,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 35),
                      ),
                    ),
                  ));
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}
