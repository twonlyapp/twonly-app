import 'dart:collection';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/messages_model.dart';

/// Mix-in [DiagnosticableTreeMixin] to have access to [debugFillProperties] for the devtool
// ignore: prefer_mixin
class NotifyProvider with ChangeNotifier, DiagnosticableTreeMixin {
  // The page index of the HomeView widget
  int _activePageIdx = 0;

  List<Contact> _allContacts = [];
  final Map<int, DbMessage> _lastMessagesGroupedByUser = <int, DbMessage>{};

  final List<Int64> _sendingCurrentlyTo = [];

  int get newContactRequests => _allContacts
      .where((contact) => !contact.accepted && contact.requested)
      .length;
  List<Contact> get allContacts => _allContacts;
  Map<int, DbMessage> get lastMessagesGroupedByUser =>
      _lastMessagesGroupedByUser;
  HashSet<Int64> get sendingCurrentlyTo =>
      HashSet<Int64>.from(_sendingCurrentlyTo);

  int get activePageIdx => _activePageIdx;

  void setActivePageIdx(int idx) {
    _activePageIdx = idx;
    notifyListeners();
  }

  void addSendingTo(Int64 user) {
    _sendingCurrentlyTo.add(user);
    notifyListeners();
  }

  // removes the first occurrence of the user
  void removeSendingTo(Int64 user) {
    int index = _sendingCurrentlyTo.indexOf(user);
    if (index != -1) {
      _sendingCurrentlyTo.removeAt(index);
    }
    notifyListeners();
  }

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
