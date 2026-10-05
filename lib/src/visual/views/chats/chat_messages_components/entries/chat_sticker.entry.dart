import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/sticker_preview.dialog.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';

class ChatStickerEntry extends StatelessWidget {
  const ChatStickerEntry({
    required this.message,
    required this.sticker,
    super.key,
  });

  final Message message;
  final StickerData sticker;

  @override
  Widget build(BuildContext context) {
    const maxEdge = 190.0;
    final maxDimension = sticker.width > sticker.height
        ? sticker.width
        : sticker.height;
    final fittedScale = maxEdge / maxDimension.clamp(1, 300).toDouble();
    final width = (sticker.width * fittedScale).clamp(48.0, maxEdge);
    final height = (sticker.height * fittedScale).clamp(48.0, maxEdge);
    return Semantics(
      button: true,
      label: context.lang.sticker,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showStickerPreview(context, sticker),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: SizedBox(
                width: width,
                height: height,
                child: Image.memory(
                  Uint8List.fromList(sticker.webp),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.broken_image_outlined,
                    color: context.color.onSurfaceVariant,
                    size: 44,
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                child: FriendlyMessageTime(
                  message: message,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
