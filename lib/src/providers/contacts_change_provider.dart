import 'package:flutter/foundation.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/messages_model.dart';

// This provider will update the UI on changes in the contact list
class ContactChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  List<Contact> _allContacts = [];
  final Map<int, DbMessage> _lastMessagesGroupedByUser = <int, DbMessage>{};

  int get newContactRequests => _allContacts
      .where((contact) => !contact.accepted && contact.requested)
      .length;
  List<Contact> get allContacts => _allContacts;

  void update() async {
    _allContacts = await DbContacts.getUsers();
    for (Contact contact in _allContacts) {
      DbMessage? last = await DbMessages.getLastMessagesForPreviewForUser(
          contact.userId.toInt());
      if (last != null) {
        _lastMessagesGroupedByUser[last.otherUserId] = last;
      }
    }
    notifyListeners();
  }

  /// Makes `Counter` readable inside the devtools by listing all of its properties
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('count', newContactRequests));
  }
}
