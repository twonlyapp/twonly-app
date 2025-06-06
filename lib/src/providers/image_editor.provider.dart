import 'package:flutter/foundation.dart';

class ImageEditorProvider with ChangeNotifier, DiagnosticableTreeMixin {
  bool _someTextViewIsAlreadyEditing = false;
  bool get someTextViewIsAlreadyEditing => _someTextViewIsAlreadyEditing;

  Future<void> updateSomeTextViewIsAlreadyEditing(bool update) async {
    _someTextViewIsAlreadyEditing = update;
    notifyListeners();
  }
}
