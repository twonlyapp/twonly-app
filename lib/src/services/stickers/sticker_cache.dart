import 'dart:typed_data';

import 'package:twonly/core/bridge/database/stickers.dart';
import 'package:twonly/core/database/app/stickers/table.dart';
import 'package:twonly/src/utils/database/database_watch.dart';

/// Sticker watches send bytes only for hashes not previously delivered.
Stream<List<LocalSticker>> watchCachedStickers() {
  final images = <String, Uint8List>{};
  return watchRustDatabase(
    (control) => watchStickers(control: control).map((snapshot) {
      final current = snapshot.items.map((item) => item.contentHash).toSet();
      images.removeWhere((hash, _) => !current.contains(hash));
      for (final asset in snapshot.assets) {
        images[asset.contentHash] = asset.webp;
      }
      return [
        for (final item in snapshot.items)
          LocalSticker(metadata: item, webp: images[item.contentHash]!),
      ];
    }),
  );
}
