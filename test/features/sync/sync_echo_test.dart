import 'dart:async';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/sync/state/sync_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/sync_test_support.dart';
import '../../support/sync_controller_test_support.dart';

/// Облако, чьи сообщения об изменениях отправляет сам тест.
class _AnnouncingRemote extends SyncRemote {
  final changes = StreamController<SyncRemoteEntity?>.broadcast();
  var fetches = 0;

  @override
  Stream<SyncRemoteEntity?> watchChanges() => changes.stream;

  @override
  Future<List<SyncRemoteEntity>> fetchEntities({int afterRevision = 0}) {
    fetches++;
    return super.fetchEntities(afterRevision: afterRevision);
  }
}

class _KeyStore extends SyncKeyStore {
  @override
  Future<AppCipher?> read(String userId) async =>
      AppCipher.fromKeyBytes(List<int>.filled(32, 6));
}

/// Облако сообщает обо всех изменениях — и о тех, что отправило само это
/// устройство. Своё эхо прогона не запускает: новостей в нём нет.
void main() {
  final date = DateTime.utc(2026, 11, 12, 9);
  final record = memoryItem('record', 'Запись', date);

  testWidgets('an echo of our own upload does not start a run', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final remote = _AnnouncingRemote();
    final harness = SyncHarness(
      remote: remote,
      keyStore: _KeyStore(),
      tombstones: MemoryTombstoneStore(),
      data: SyncDataSources(
        readMemoryItems: () async => [record],
        replaceMemoryItems: (_) async {},
      ),
    );
    final controller = harness.controller;
    await controller.load();
    await tester.pump(const Duration(seconds: 1));
    expect(remote.storedEntities, hasLength(1));
    final fetchesAfterUpload = remote.fetches;

    remote.changes.add(remote.storedEntities.values.single);
    await tester.pump(const Duration(seconds: 1));

    expect(remote.fetches, fetchesAfterUpload);

    remote.changes.add(SyncRemoteEntity(
      kind: SyncEntityKind.memoryItem,
      entityId: 'from-phone',
      updatedAt: date.add(const Duration(minutes: 1)),
      deletedAt: date.add(const Duration(minutes: 1)),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(remote.fetches, fetchesAfterUpload + 1);
    harness.dispose();
    await remote.changes.close();
  });

  testWidgets('a hidden app does not sync by the clock', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final remote = _AnnouncingRemote();
    final harness = SyncHarness(
      remote: remote,
      keyStore: _KeyStore(),
      tombstones: MemoryTombstoneStore(),
      data: SyncDataSources(
        readMemoryItems: () async => [record],
        replaceMemoryItems: (_) async {},
      ),
    );
    final controller = harness.controller;
    await controller.load();
    await tester.pump(const Duration(seconds: 1));
    final fetchesBefore = remote.fetches;

    controller.appHidden();
    remote.changes.add(null);
    await tester.pump(const Duration(minutes: 5));

    expect(remote.fetches, fetchesBefore);

    controller.appShown();
    await tester.pump(const Duration(minutes: 2, seconds: 1));

    expect(remote.fetches, greaterThan(fetchesBefore));
    harness.dispose();
    await remote.changes.close();
  });
}
