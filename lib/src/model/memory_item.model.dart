import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';

class MemoryItem {
  MemoryItem({
    required this.mediaService,
    required this.messages,
  });
  final List<Message> messages;
  final MediaFileService mediaService;

  static Future<Map<String, MemoryItem>> convertFromMessages(
    List<Message> messages,
  ) async {
    final items = <String, MemoryItem>{};
    for (final message in messages) {
      if (message.mediaId == null) continue;

      final mediaService = await MediaFileService.fromMediaId(message.mediaId!);
      if (mediaService == null) continue;

      items
          .putIfAbsent(
            message.mediaId!,
            () => MemoryItem(
              mediaService: mediaService,
              messages: [],
            ),
          )
          .messages
          .add(message);
    }
    return items;
  }
}
