import 'package:flutter/foundation.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/messages_model.dart';

/// This provider does always contains the latest messages send or received
/// for every contact.
class MessagesChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  final Map<int, DbMessage> _lastMessage = <int, DbMessage>{};
  Map<int, DbMessage> get lastMessage => _lastMessage;

  void updateLastMessageFor(int targetUserId) async {
    DbMessage? last =
        await DbMessages.getLastMessagesForPreviewForUser(targetUserId);
    if (last != null) {
      _lastMessage[last.otherUserId] = last;
    }
  }

  void init() async {
    // load everything from the database
    List<Contact> allContacts = await DbContacts.getUsers();
    for (Contact contact in allContacts) {
      DbMessage? last = await DbMessages.getLastMessagesForPreviewForUser(
          contact.userId.toInt());
      if (last != null) {
        _lastMessage[last.otherUserId] = last;
      }
    }
  }
}
