import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart';
import 'package:twonly/src/visual/elements/better_text.element.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/common.dart';

VacationData? vacationDataOf(StoredMessage message) {
  final bytes = message.additionalMessageData;
  if (bytes == null) return null;
  try {
    final data = AdditionalMessageData.fromBuffer(bytes);
    return data.hasVacation() ? data.vacation : null;
  } catch (_) {
    return null;
  }
}

/// The entry's text: when the vacation lasts, or that it ended early. The
/// window ends at the midnight after the last vacation day, so that day is
/// shown.
String? vacationEntryText(BuildContext context, StoredMessage message) {
  final vacation = vacationDataOf(message);
  if (vacation == null) return null;
  final endsAtMs = vacation.endsAtMs.toInt();
  if (endsAtMs <= message.createdAtSeconds * 1000) {
    return context.lang.chatEntryVacationEnded;
  }
  final lastDay = DateTime.fromMillisecondsSinceEpoch(endsAtMs - 1);
  final date = DateFormat.MMMEd(
    Localizations.localeOf(context).toString(),
  ).format(lastDay);
  return context.lang.chatEntryVacationStarted(date);
}

class ChatVacationEntry extends StatelessWidget {
  const ChatVacationEntry({
    required this.message,
    required this.borderRadius,
    required this.info,
    super.key,
  });

  final StoredMessage message;
  final BorderRadiusGeometry borderRadius;
  final BubbleInfo info;

  @override
  Widget build(BuildContext context) {
    final text = vacationEntryText(context, message);
    if (text == null) return const SizedBox.shrink();
    final icon = vacationIconOrDefault(vacationDataOf(message)?.icon);

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.8,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: info.color,
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: FittedBox(child: EmojiAnimationComp(emoji: icon)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: BetterText(
              text: text,
              textColor: info.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
