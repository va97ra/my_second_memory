import 'dart:typed_data';

import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sync_test_support.dart';

/// Файл в облаке удаляется как ничей, только если слитые данные заведомо
/// полны: у каждой живой облачной строки, которая может держать файлы, есть
/// пара здесь. Иначе ошибка в другом месте стёрла бы чужие снимки навсегда.
void main() {
  final vault = AppCipher.fromKeyBytes(List.filled(32, 7));

  test('без подтверждённой полноты ничьи файлы остаются в облаке', () async {
    final remote = SyncRemote();
    remote.storedMedia['image_orphan.jpg'] = await vault.encryptBytes([2]);
    final storage = FakeMediaStorage({
      'image_new.jpg': Uint8List.fromList([1])
    });

    final result = await MediaSyncEngine(
      remote: remote,
      storage: storage,
      vault: vault,
      atRest: null,
    ).synchronize(const {'image_new.jpg'}, referencesComplete: false);

    // Своё дело прогон делает: недостающее уезжает.
    expect(result.mediaUploaded, 1);
    expect(
      remote.storedMedia.keys,
      unorderedEquals(['image_orphan.jpg', 'image_new.jpg']),
    );
  });

  test('живая облачная запись без пары здесь бережёт свои файлы', () async {
    final remote = SyncRemote();
    final date = DateTime.utc(2026, 11, 1);
    final gone = memoryItem('gone', 'Удалённая здесь', date)
        .copyWith(imagePaths: const ['image_gone.jpg']);
    remote.seed(await encodedMemoryItem(vault, gone));
    remote.storedMedia['image_gone.jpg'] = await vault.encryptBytes([3]);

    // Здесь запись удалена позже облачной правки: облако узнает об удалении
    // только из этого прогона, и до тех пор строка в нём ещё живая.
    final tombstones = MemoryTombstoneStore();
    await tombstones.markDeleted(
        'user', 'gone', date.add(const Duration(days: 1)));

    Future<void> run() => sync(
          remote: remote,
          cipher: vault,
          tombstones: tombstones,
          shifts: const [],
          replaceShifts: (_) async {},
          accounts: const [],
          replaceAccounts: (_) async {},
          media: MediaSyncEngine(
            remote: remote,
            storage: FakeMediaStorage({}),
            vault: vault,
            atRest: null,
          ),
        );

    await run();
    expect(remote.storedMedia.keys, ['image_gone.jpg']);

    // Следующий прогон видит строку удалённой — файл уже ничей на деле.
    await run();
    expect(remote.storedMedia.keys, isEmpty);
  });
}
