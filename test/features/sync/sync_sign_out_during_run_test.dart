import 'dart:async';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/sync/state/sync_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/sync_test_support.dart';
import '../../support/sync_controller_test_support.dart';

/// Облако, которое держит чтение, пока тест его не отпустит.
class _SlowRemote extends SyncRemote {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<List<SyncRemoteEntity>> fetchEntities({int afterRevision = 0}) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    return super.fetchEntities(afterRevision: afterRevision);
  }
}

class _KeyStore extends SyncKeyStore {
  @override
  Future<AppCipher?> read(String userId) async =>
      AppCipher.fromKeyBytes(List<int>.filled(32, 2));

  @override
  Future<void> delete(String userId) async {}
}

/// Б9: выход из аккаунта посреди прогона. Прогон не должен доработать на
/// уничтоженном ключе, а его ошибка — перезаписать состояние «вышел».
void main() {
  test('signing out during a run ends signed out, without an error', () async {
    SharedPreferences.setMockInitialValues({});
    final date = DateTime.utc(2026, 11, 12, 9);
    final remote = _SlowRemote();
    final harness = SyncHarness(
      remote: remote,
      keyStore: _KeyStore(),
      tombstones: MemoryTombstoneStore(),
      data: SyncDataSources(
        readMemoryItems: () async => [memoryItem('record', 'Запись', date)],
        replaceMemoryItems: (_) async {},
      ),
    );
    final controller = harness.controller;
    await controller.load();

    final run = controller.syncNow();
    await remote.started.future;
    final signOut = controller.signOut();
    remote.release.complete();
    await Future.wait([run, signOut]);

    expect(controller.state.status, SyncStatus.signedOut);
    expect(controller.state.error, isNull);
  });
}
