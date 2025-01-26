import 'package:flutter/foundation.dart';
import 'package:twonly/src/model/contacts_model.dart';

/// Mix-in [DiagnosticableTreeMixin] to have access to [debugFillProperties] for the devtool
// ignore: prefer_mixin
class NotifyProvider with ChangeNotifier, DiagnosticableTreeMixin {
  // The page index of the HomeView widget
  int _activePageIdx = 0;

  int _newContactRequests = 0;
  List<Contact> _allContacts = [];

  List<Contact> _sendingCurrentlyTo = [];

  int get newContactRequests => _newContactRequests;
  List<Contact> get allContacts => _allContacts;
  List<Contact> get sendingCurrentlyTo => _sendingCurrentlyTo;

  int get activePageIdx => _activePageIdx;

  void setActivePageIdx(int idx) {
    _activePageIdx = idx;
    notifyListeners();
  }

  void addSendingTo(List<Contact> users) {
    _sendingCurrentlyTo.addAll(users);
    notifyListeners();
  }

  void update() async {
    _allContacts = await DbContacts.getUsers();

    _newContactRequests = _allContacts
        .where((contact) => !contact.accepted && contact.requested)
        .length;
    print(_newContactRequests);
    notifyListeners();
  }

  /// Makes `Counter` readable inside the devtools by listing all of its properties
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('count', newContactRequests));
  }
}
