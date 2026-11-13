import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/security/state/security_provider.dart';
import 'package:ezhednevnik_v2/src/features/sync/state/sync_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'provider_test_support.dart';

/// Контроллер синхронизации, как в приложении, но облако, ключи, отметки
/// удалений и локальные данные — тестовые.
class SyncHarness {
  SyncHarness({
    required SyncRemoteStore? remote,
    required SyncKeyStore keyStore,
    required SyncTombstoneStore tombstones,
    required SyncDataSources data,
    bool localDataAvailable = true,
  }) : container = testContainer(overrides: [
          syncRemoteStoreProvider.overrideWithValue(remote),
          syncKeyStoreProvider.overrideWithValue(keyStore),
          syncTombstoneStoreProvider.overrideWithValue(tombstones),
          syncDataSourcesProvider.overrideWithValue(data),
        ]) {
    this.localDataAvailable = localDataAvailable;
  }

  final ProviderContainer container;

  SyncController get controller =>
      container.read(syncControllerProvider.notifier);

  /// Замок данных на устройстве: закрыт PIN — синхронизация ждёт, пока его
  /// откроют.
  set localDataAvailable(bool available) {
    container.read(securitySessionProvider.notifier).state = available
        ? const SecuritySessionState()
        : const SecuritySessionState(hasPin: true);
  }

  /// Закрывает контроллер раньше конца теста: его таймеры не должны пережить
  /// тест.
  void dispose() => container.dispose();
}
