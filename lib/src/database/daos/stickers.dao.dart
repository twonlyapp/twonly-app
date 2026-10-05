import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/stickers.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

part 'stickers.dao.g.dart';

@DriftAccessor(tables: [Stickers])
class StickersDao extends DatabaseAccessor<TwonlyDB> with _$StickersDaoMixin {
  // ignore: matching_super_parameters
  StickersDao(super.db);

  Stream<List<LocalSticker>> watchAll() {
    return (select(stickers)..orderBy([
          (sticker) => OrderingTerm.desc(sticker.usageCount),
          (sticker) => OrderingTerm.desc(sticker.lastUsedAt),
          (sticker) => OrderingTerm.desc(sticker.createdAt),
        ]))
        .watch();
  }

  Future<LocalSticker?> getByHash(String contentHash) {
    return (select(stickers)
          ..where((sticker) => sticker.contentHash.equals(contentHash)))
        .getSingleOrNull();
  }

  /// Saves verified sticker bytes. The digest is always recomputed here so a
  /// malformed received message can never create a duplicate under a false id.
  Future<bool> save({
    required Uint8List webp,
    required int width,
    required int height,
    String? expectedHash,
  }) async {
    if (webp.isEmpty || webp.length > 128 * 1024) {
      throw ArgumentError.value(webp.length, 'webp', 'invalid sticker size');
    }
    if (width < 1 || width > 300 || height < 1 || height > 300) {
      throw ArgumentError('invalid sticker dimensions: ${width}x$height');
    }
    final contentHash = hex.encode(sha256.convert(webp).bytes);
    if (expectedHash != null && expectedHash != contentHash) {
      throw ArgumentError('sticker digest does not match its bytes');
    }
    final now = DateTime.now();
    return transaction(() async {
      if (await getByHash(contentHash) != null) return false;
      await into(stickers).insert(
        StickersCompanion.insert(
          contentHash: contentHash,
          webp: webp,
          width: width,
          height: height,
          createdAt: Value(now),
          lastUsedAt: Value(now),
        ),
      );
      return true;
    });
  }

  Future<void> recordUse(String contentHash) async {
    await customUpdate(
      'UPDATE stickers SET usage_count = usage_count + 1, '
      'last_used_at = ? WHERE content_hash = ?',
      variables: [
        Variable<DateTime>(DateTime.now()),
        Variable<String>(contentHash),
      ],
      updates: {stickers},
    );
  }

  Future<void> remove(String contentHash) {
    return (delete(
      stickers,
    )..where((sticker) => sticker.contentHash.equals(contentHash))).go();
  }
}
