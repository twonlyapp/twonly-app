import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/twonly.db.dart';

void main() {
  late TwonlyDB database;

  setUp(() => database = TwonlyDB(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('identical stickers are deduplicated without resetting usage', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    final hash = sha256.convert(bytes).toString();
    expect(
      await database.stickersDao.save(webp: bytes, width: 30, height: 20),
      isTrue,
    );
    await database.stickersDao.recordUse(hash);
    expect(
      await database.stickersDao.save(webp: bytes, width: 30, height: 20),
      isFalse,
    );
    final stickers = await database.stickersDao.watchAll().first;
    expect(stickers, hasLength(1));
    expect(stickers.single.usageCount, 1);
  });

  test(
    'most used stickers come first and removal only removes the selected one',
    () async {
      final first = Uint8List.fromList([1]);
      final second = Uint8List.fromList([2]);
      final firstHash = sha256.convert(first).toString();
      final secondHash = sha256.convert(second).toString();
      await database.stickersDao.save(webp: first, width: 30, height: 20);
      await database.stickersDao.save(webp: second, width: 30, height: 20);
      await database.stickersDao.recordUse(secondHash);
      await database.stickersDao.recordUse(firstHash);
      await database.stickersDao.recordUse(firstHash);
      final stickers = await database.stickersDao.watchAll().first;
      expect(stickers.map((sticker) => sticker.contentHash), [
        firstHash,
        secondHash,
      ]);
      expect(stickers.map((sticker) => sticker.usageCount), [2, 1]);
      await database.stickersDao.remove(firstHash);
      expect(await database.stickersDao.getByHash(firstHash), isNull);
      expect((await database.stickersDao.getByHash(secondHash))?.usageCount, 1);
    },
  );

  test(
    'false digests and invalid bounds cannot enter the collection',
    () async {
      final bytes = Uint8List.fromList([1]);
      await expectLater(
        database.stickersDao.save(
          webp: bytes,
          width: 30,
          height: 20,
          expectedHash: 'incorrect',
        ),
        throwsArgumentError,
      );
      await expectLater(
        database.stickersDao.save(webp: bytes, width: 301, height: 20),
        throwsArgumentError,
      );
      expect(await database.stickersDao.watchAll().first, isEmpty);
    },
  );

  test('replacement preserves usage and collection timestamps', () async {
    final bytes = Uint8List.fromList([1]);
    final rotated = Uint8List.fromList([2]);
    final hash = sha256.convert(bytes).toString();
    final rotatedHash = sha256.convert(rotated).toString();
    await database.stickersDao.save(webp: bytes, width: 30, height: 20);
    await database.stickersDao.recordUse(hash);
    final original = (await database.stickersDao.getByHash(hash))!;
    final replacement = await database.stickersDao.replace(
      contentHash: hash,
      webp: rotated,
      width: 20,
      height: 30,
      expectedHash: rotatedHash,
    );
    expect(replacement.contentHash, rotatedHash);
    expect(replacement.webp, rotated);
    expect((replacement.width, replacement.height), (20, 30));
    expect(replacement.usageCount, original.usageCount);
    expect(replacement.createdAt, original.createdAt);
    expect(replacement.lastUsedAt, original.lastUsedAt);
    expect(await database.stickersDao.getByHash(hash), isNull);
    expect(await database.stickersDao.watchAll().first, hasLength(1));
  });

  test('replacement merges a duplicate and can keep the same digest', () async {
    final first = Uint8List.fromList([1]);
    final second = Uint8List.fromList([2]);
    final firstHash = sha256.convert(first).toString();
    final secondHash = sha256.convert(second).toString();
    await database.stickersDao.save(webp: first, width: 30, height: 20);
    await database.stickersDao.save(webp: second, width: 20, height: 30);
    await database.stickersDao.recordUse(firstHash);
    await database.stickersDao.recordUse(secondHash);
    await database.stickersDao.replace(
      contentHash: firstHash,
      webp: second,
      width: 20,
      height: 30,
      expectedHash: secondHash,
    );
    final unchanged = await database.stickersDao.replace(
      contentHash: secondHash,
      webp: second,
      width: 20,
      height: 30,
      expectedHash: secondHash,
    );
    expect(unchanged.usageCount, 2);
    expect(await database.stickersDao.watchAll().first, hasLength(1));
  });

  test('invalid replacement leaves the original intact', () async {
    final bytes = Uint8List.fromList([1]);
    final hash = sha256.convert(bytes).toString();
    await database.stickersDao.save(webp: bytes, width: 30, height: 20);
    await expectLater(
      database.stickersDao.replace(
        contentHash: hash,
        webp: Uint8List.fromList([2]),
        width: 20,
        height: 30,
        expectedHash: 'incorrect',
      ),
      throwsArgumentError,
    );
    expect((await database.stickersDao.getByHash(hash))?.webp, bytes);
    expect(await database.stickersDao.watchAll().first, hasLength(1));
  });
}
