import 'dart:collection';
import 'package:flutter/foundation.dart';

class DownloadChangeProvider with ChangeNotifier, DiagnosticableTreeMixin {
  final HashSet<List<int>> _currentlyDownloading = HashSet<List<int>>();

  HashSet<List<int>> get currentlyDownloading => _currentlyDownloading;

  void update(List<int> token, bool add) {
    if (add) {
      _currentlyDownloading.add(token);
    } else {
      _currentlyDownloading.remove(token);
    }
  }
}
