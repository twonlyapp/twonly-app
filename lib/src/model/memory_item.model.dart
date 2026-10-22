import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';

class MemoryItem {
  MemoryItem({
    required this.mediaService,
    required this.messages,
    this.sender,
  });
  final List<StoredMessage> messages;
  final MediaFileService mediaService;
  final Contact? sender;

  static Future<Map<String, MemoryItem>> convertFromMessages(
    List<StoredMessage> messages,
  ) async {
    final items = <String, MemoryItem>{};
    for (final message in messages) {
      if (message.mediaId == null) continue;

      final mediaService = await MediaFileService.fromMediaId(message.mediaId!);
      if (mediaService == null) continue;

      if (!mediaService.imagePreviewAvailable) {
        continue;
      }

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
