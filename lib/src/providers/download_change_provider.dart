import 'dart:collection';
import 'package:flutter/foundation.dart';

class DownloadChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  final HashSet<String> _currentlyDownloading = HashSet<String>();

  HashSet<String> get currentlyDownloading => _currentlyDownloading;

  void update(List<int> token, bool add) {
    debugPrint("Downloading: $add : $token");

    if (add) {
      _currentlyDownloading.add(token.toString());
    } else {
      _currentlyDownloading.remove(token.toString());
    }
    debugPrint("Downloading: $add : ${_currentlyDownloading.toList()}");
    notifyListeners();
  }
}
