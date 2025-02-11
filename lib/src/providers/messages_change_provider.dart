import 'package:flutter/foundation.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/utils/misc.dart';

/// This provider does always contains the latest messages send or received
/// for every contact.
class MessagesChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  final Map<int, DbMessage> _lastMessage = <int, DbMessage>{};
  final Map<int, List<DbMessage>> _allMessagesFromUser =
      <int, List<DbMessage>>{};
  final Map<int, int> _changeCounter = <int, int>{};
  final Map<int, int> _flamesCounter = <int, int>{};

  Map<int, DbMessage> get lastMessage => _lastMessage;
  Map<int, List<DbMessage>> get allMessagesFromUser => _allMessagesFromUser;
  Map<int, int> get changeCounter => _changeCounter;
  Map<int, int> get flamesCounter => _flamesCounter;

  Future updateLastMessageFor(int targetUserId, int? messageId) async {
    DbMessage? last =
        await DbMessages.getLastMessagesForPreviewForUser(targetUserId);
    if (last != null) {
      _lastMessage[last.otherUserId] = last;
    }
    flamesCounter[targetUserId] = await getFlamesForOtherUser(targetUserId);
    // notifyListeners();

    if (messageId == null || _allMessagesFromUser[targetUserId] == null) {
      loadMessagesForUser(targetUserId, force: true);
    } else {
      DbMessage? msg = await DbMessages.getMessageById(messageId);
      if (msg != null) {
        int index = _allMessagesFromUser[targetUserId]!
            .indexWhere((x) => x.messageId == messageId);
        if (index == -1) {
          _allMessagesFromUser[targetUserId]!.insert(0, msg);
        } else {
          _allMessagesFromUser[targetUserId]![index] = msg;
        }
      }
      _allMessagesFromUser[targetUserId] = allMessagesFromUser[targetUserId]!;
      notifyListeners();
    }
  }

  Future loadMessagesForUser(int targetUserId, {bool force = false}) async {
    if (!force && _allMessagesFromUser[targetUserId] != null) return;
    _allMessagesFromUser[targetUserId] =
        await DbMessages.getAllMessagesForUser(targetUserId);
    notifyListeners();
  }

  void init({bool afterPaused = false}) async {
    // load everything from the database
    List<Contact> allContacts = await DbContacts.getUsers();
    for (Contact contact in allContacts) {
      DbMessage? last = await DbMessages.getLastMessagesForPreviewForUser(
          contact.userId.toInt());
      if (last != null) {
        _lastMessage[last.otherUserId] = last;
      }
      flamesCounter[contact.userId.toInt()] =
          await getFlamesForOtherUser(contact.userId.toInt());
    }
    notifyListeners();
    if (afterPaused) {
      for (int targetUserId in _allMessagesFromUser.keys) {
        loadMessagesForUser(targetUserId, force: true);
      }
    }
  }
}
