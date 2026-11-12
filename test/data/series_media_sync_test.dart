import 'dart:typed_data';

import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/recurrence_test_support.dart';
import '../support/sync_test_support.dart';

/// Б3: фото и голос повторяющейся записи живут в шаблоне серии и в правках
/// дат, а не в строках записей. Синхронизация должна их видеть.
void main() {
  final vault = AppCipher.fromKeyBytes(List.filled(32, 7));

  Future<void> run(SyncRemote remote, FakeMediaStorage storage) async {
    final (:series, :override) = seriesWithMedia();
    await sync(
      remote: remote,
      cipher: vault,
      tombstones: MemoryTombstoneStore(),
      shifts: const [],
      replaceShifts: (_) async {},
      accounts: const [],
      replaceAccounts: (_) async {},
      recurrenceSeries: [series],
      recurrenceExceptions: [override],
      media: MediaSyncEngine(
        remote: remote,
        storage: storage,
        vault: vault,
        atRest: null,
      ),
    );
  }

  test("a series photo and an occurrence's own photo reach the cloud",
      () async {
    final remote = SyncRemote();
    final storage = FakeMediaStorage({
      'image_series.jpg': Uint8List.fromList([1]),
      'image_override.jpg': Uint8List.fromList([2]),
    });

    await run(remote, storage);

    expect(
      remote.storedMedia.keys,
      unorderedEquals(['image_series.jpg', 'image_override.jpg']),
    );
  });

  test('a series photo in the cloud is not deleted as nobody\'s', () async {
    final remote = SyncRemote();
    remote.storedMedia['image_series.jpg'] = await vault.encryptBytes([1]);
    remote.storedMedia['image_override.jpg'] = await vault.encryptBytes([2]);

    await run(remote, FakeMediaStorage({}));

    expect(
      remote.storedMedia.keys,
      unorderedEquals(['image_series.jpg', 'image_override.jpg']),
    );
  });

  test('a device without the series photo downloads it', () async {
    final remote = SyncRemote();
    remote.storedMedia['image_series.jpg'] = await vault.encryptBytes([1]);
    final storage = FakeMediaStorage({});

    await run(remote, storage);

    expect(storage.files['image_series.jpg'], [1]);
  });
}
