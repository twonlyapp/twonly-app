import 'package:flutter/foundation.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/messages_model.dart';

/// This provider does always contains the latest messages send or received
/// for every contact.
class MessagesChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  final Map<int, DbMessage> _lastMessage = <int, DbMessage>{};
  final Map<int, int> _changeCounter = <int, int>{};

  Map<int, DbMessage> get lastMessage => _lastMessage;
  Map<int, int> get changeCounter => _changeCounter;

  void updateLastMessageFor(int targetUserId) async {
    DbMessage? last =
        await DbMessages.getLastMessagesForPreviewForUser(targetUserId);
    if (last != null) {
      _lastMessage[last.otherUserId] = last;
    }
    if (!changeCounter.containsKey(targetUserId)) {
      changeCounter[targetUserId] = 0;
    }
    changeCounter[targetUserId] = changeCounter[targetUserId]! + 1;
    notifyListeners();
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
    notifyListeners();
  }
}
