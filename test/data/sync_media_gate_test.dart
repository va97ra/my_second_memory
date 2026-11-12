import 'dart:typed_data';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sync_test_support.dart';

/// Облако, которое считает, сколько раз листали бакет вложений.
class _CountingMediaRemote extends SyncRemote {
  var listings = 0;

  @override
  Future<Set<String>> listMediaNames() {
    listings++;
    return super.listMediaNames();
  }
}

/// Сверка вложений листает весь бакет. Она идёт, только когда есть что
/// сверять: изменился набор ссылок или прошлая сверка что-то не довезла.
void main() {
  final cipher = AppCipher.fromKeyBytes(List.filled(32, 9));
  final date = DateTime.utc(2026, 11, 12, 9);

  late _CountingMediaRemote remote;
  late FakeMediaStorage storage;
  late CloudSnapshot snapshot;
  late List<MemoryItem> local;

  MemoryItem withPhoto(String id, String photo) =>
      memoryItem(id, id, date).copyWith(imagePaths: [photo]);

  Future<void> run() => sync(
        remote: remote,
        cipher: cipher,
        tombstones: MemoryTombstoneStore(),
        memoryItems: local,
        replaceMemoryItems: (items) async => local = items,
        shifts: const [],
        replaceShifts: (_) async {},
        accounts: const [],
        replaceAccounts: (_) async {},
        snapshot: snapshot,
        media: MediaSyncEngine(
          remote: remote,
          storage: storage,
          vault: cipher,
          atRest: null,
        ),
      );

  setUp(() async {
    remote = _CountingMediaRemote();
    storage = FakeMediaStorage({
      'image_a.jpg': Uint8List.fromList([1])
    });
    snapshot = CloudSnapshot();
    local = [withPhoto('a', 'image_a.jpg')];
    await run();
  });

  test('a run with nothing new does not list the bucket', () async {
    expect(remote.listings, 1);

    await run();

    expect(remote.listings, 1);
  });

  test('a new photo is checked', () async {
    storage.files['image_b.jpg'] = Uint8List.fromList([2]);
    local = [...local, withPhoto('b', 'image_b.jpg')];

    await run();

    expect(remote.listings, 2);
    expect(remote.storedMedia.keys, contains('image_b.jpg'));
  });

  test('a photo still missing everywhere is looked for again', () async {
    local = [...local, withPhoto('c', 'image_lost.jpg')];
    await run();
    final listings = remote.listings;

    await run();

    expect(remote.listings, listings + 1);
  });

  test('a fresh start checks the photos once', () async {
    snapshot = CloudSnapshot();

    await run();

    expect(remote.listings, 2);
  });
}
