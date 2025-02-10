import 'package:flutter/foundation.dart';

// This provider will update the UI on changes in the contact list
class SendNextMediaTo with ChangeNotifier, DiagnosticableTreeMixin {
  int? _sendNextMediaToUserId;

  int? get sendNextMediaToUserId => _sendNextMediaToUserId;
  void updateSendNextMediaTo(int? userId) {
    _sendNextMediaToUserId = userId;
    notifyListeners();
  }
}
