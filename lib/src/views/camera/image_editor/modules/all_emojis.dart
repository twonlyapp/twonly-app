import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/image_editor/data/data.dart';
import 'package:twonly/src/views/camera/image_editor/data/layer.dart';

class Emojis extends StatefulWidget {
  const Emojis({super.key});

  @override
  State<Emojis> createState() => _EmojisState();
}

class _EmojisState extends State<Emojis> {
  List<String> lastUsed = emojis;

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    setState(() {
      lastUsed = gUser.lastUsedEditorEmojis ?? [];
      lastUsed.addAll(emojis);
    });
  }

  Future<void> selectEmojis(String emoji) async {
    await updateUserdata((user) {
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
      return user;
    });
    if (!mounted) return;
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
        padding: EdgeInsets.zero,
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
              padding: EdgeInsets.zero,
              child: GridView(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 60,
                ),
                children: lastUsed.map((String emoji) {
                  return GridTile(
                    child: GestureDetector(
                      onTap: () async {
                        await selectEmojis(emoji);
                      },
                      child: Container(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 35),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
