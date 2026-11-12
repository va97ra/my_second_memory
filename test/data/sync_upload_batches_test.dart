import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sync_test_support.dart';

/// Облако, которое обрывает одну отправку из нескольких.
class _DroppingRemote extends SyncRemote {
  _DroppingRemote({required this.failingCall});

  final int failingCall;
  var _calls = 0;

  @override
  Future<void> applyEntities(List<SyncRemoteEntity> entities) async {
    if (++_calls == failingCall) throw StateError('connection dropped');
    await super.applyEntities(entities);
  }
}

/// О6: изменения уходят пачками по 200. Первая заливка большого дневника не
/// упирается в один вызов, а оборванная пачка не заставляет слать заново то,
/// что уже в облаке.
void main() {
  final cipher = AppCipher.fromKeyBytes(List.filled(32, 8));
  final date = DateTime.utc(2026, 11, 12, 9);
  final diary = [
    for (var index = 0; index < 450; index++)
      memoryItem('record-$index', 'Запись $index', date),
  ];

  Future<void> run(SyncRemote remote, CloudSnapshot snapshot) => sync(
        remote: remote,
        cipher: cipher,
        tombstones: MemoryTombstoneStore(),
        memoryItems: diary,
        shifts: const [],
        replaceShifts: (_) async {},
        accounts: const [],
        replaceAccounts: (_) async {},
        snapshot: snapshot,
      );

  test('450 changes go in batches of 200', () async {
    final remote = SyncRemote();

    await run(remote, CloudSnapshot());

    expect(remote.appliedBatches, [200, 200, 50]);
    expect(remote.storedEntities, hasLength(450));
  });

  test('after a dropped batch only the rest is sent again', () async {
    final remote = _DroppingRemote(failingCall: 3);
    final snapshot = CloudSnapshot();

    await expectLater(run(remote, snapshot), throwsStateError);
    expect(remote.storedEntities, hasLength(400));

    await run(remote, snapshot);

    expect(remote.appliedBatches.last, 50);
    expect(remote.storedEntities, hasLength(450));
  });
}
