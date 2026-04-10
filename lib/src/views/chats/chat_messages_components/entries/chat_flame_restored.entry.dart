import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/better_text.dart';

class ChatFlameRestoredEntry extends StatelessWidget {
  const ChatFlameRestoredEntry({
    required this.message,
    super.key,
  });

  final Message message;

  @override
  Widget build(BuildContext context) {
    AdditionalMessageData? data;

    if (message.additionalMessageData != null) {
      try {
        data = AdditionalMessageData.fromBuffer(
          message.additionalMessageData!,
        );
      } catch (e) {
        data = null;
      }
    }

    if (data == null || !data.hasRestoredFlameCounter()) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 10),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BetterText(
        text: context.lang.chatEntryFlameRestored(
          data.restoredFlameCounter.toInt(),
        ),
        textColor: isDarkMode(context) ? Colors.black : Colors.black,
      ),
    );
  }
}
