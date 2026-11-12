import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sync_test_support.dart';

/// О5: облако дочитывается по курсору. Прогон без изменений не скачивает
/// дневник заново, а правка и удаление с другого устройства доходят.
void main() {
  final cipher = AppCipher.fromKeyBytes(List.filled(32, 4));
  final date = DateTime.utc(2026, 11, 12, 9);

  late SyncRemote remote;
  late List<MemoryItem> local;
  late CloudSnapshot snapshot;

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
      );

  /// Другое устройство отправляет правку в облако напрямую.
  Future<void> otherDevice(SyncRemoteEntity change) =>
      remote.applyEntities([change]);

  setUp(() async {
    remote = SyncRemote();
    snapshot = CloudSnapshot();
    local = [
      for (var index = 0; index < 50; index++)
        memoryItem('record-$index', 'Запись $index', date),
    ];
    // Первый прогон заливает дневник, второй один раз дочитывает собственную
    // заливку: ревизии своих строк устройство узнаёт только из облака.
    await run();
    await run();
  });

  test('a run without changes reads nothing from the cloud', () async {
    expect(remote.fetchedRows, [0, 50]);

    await run();

    expect(remote.fetchedRows.last, 0);
  });

  test('a fresh start reads the whole cloud once', () async {
    snapshot = CloudSnapshot();

    await run();

    expect(remote.fetchedRows.last, 50);
  });

  test('an edit from another device arrives', () async {
    final edited = local[3].copyWith(
      body: 'Правка с телефона',
      updatedAt: date.add(const Duration(minutes: 1)),
    );
    await otherDevice(await encodedMemoryItem(cipher, edited));

    await run();

    expect(remote.fetchedRows.last, 1);
    expect(
      local.singleWhere((item) => item.id == edited.id).body,
      'Правка с телефона',
    );
  });

  test('a deletion from another device arrives', () async {
    await otherDevice(SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: 'record-7',
      updatedAt: date.add(const Duration(minutes: 1)),
      deletedAt: date.add(const Duration(minutes: 1)),
    ));

    await run();

    expect(local.map((item) => item.id), isNot(contains('record-7')));
    expect(local, hasLength(49));
  });
}
