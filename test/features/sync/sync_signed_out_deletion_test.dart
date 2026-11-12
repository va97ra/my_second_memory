import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/sync/state/sync_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/sync_test_support.dart';

/// Облако, в которое входят и из которого выходят по ходу теста.
class _AccountRemote extends SyncRemote {
  String? userId;

  @override
  String? get currentUserId => userId;
}

class _KeyStore extends SyncKeyStore {
  @override
  Future<AppCipher?> read(String userId) async =>
      AppCipher.fromKeyBytes(List<int>.filled(32, 3));
}

/// Б10: удаление, сделанное без входа в аккаунт, запоминается и после входа
/// уходит в облако — удалённая запись не возвращается.
void main() {
  test('a record deleted while signed out stays deleted after sign-in',
      () async {
    SharedPreferences.setMockInitialValues({});
    final cipher = AppCipher.fromKeyBytes(List<int>.filled(32, 3));
    final date = DateTime.utc(2026, 11, 12, 9);
    final deletedAt = date.add(const Duration(hours: 1));
    final remote = _AccountRemote();
    var local = <MemoryItem>[memoryItem('kept', 'Оставили', date)];
    final controller = SyncController(
      remote: remote,
      keyStore: _KeyStore(),
      tombstones: const SyncTombstoneStore(),
      data: SyncDataSources(
        readMemoryItems: () async => local,
        replaceMemoryItems: (items) async => local = items,
      ),
    );
    addTearDown(controller.dispose);
    await controller.load();
    expect(controller.state.status, SyncStatus.signedOut);

    // Запись удалили на устройстве, пока аккаунта не было; в облаке она
    // осталась с прошлой синхронизации.
    await controller.recordDeletion(
        SyncEntityKind.memoryItem, 'gone', deletedAt);
    remote.seed(await encodedMemoryItem(
      cipher,
      memoryItem('gone', 'Удалённая', date),
    ));

    remote.userId = 'user';
    await controller.signInWithGoogle();
    await controller.syncNow();

    expect(controller.state.status, SyncStatus.ready);
    expect(local.map((item) => item.id), ['kept']);
    expect(remote.storedEntities['memory_item:gone']!.isDeleted, isTrue);
  });
}
