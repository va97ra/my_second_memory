import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../sync/sync.dart';
import 'settings_section.dart';
import 'settings_tile.dart';

/// Данные и планирование: графики смен, архив, облако, резервная копия.
class DataSettingsSection extends ConsumerWidget {
  const DataSettingsSection({super.key, required this.isRu});

  final bool isRu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    // Без адреса облака синхронизации нет вовсе, и строки для неё тоже.
    final syncEnabled = ref.watch(syncBackendConfigProvider).isConfigured;

    return SettingsSection(
      title: isRu ? 'Данные и планирование' : 'Data and planning',
      children: [
        SettingsTile(
          icon: Icons.work_history_rounded,
          title: strings.shiftSchedules,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.pageTurnGo('/settings/shifts'),
        ),
        SettingsTile(
          icon: Icons.inventory_2_rounded,
          title: strings.memoryArchive,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.pageTurnGo('/memory'),
        ),
        if (syncEnabled) _syncTile(context, strings, ref),
        SettingsTile(
          icon: Icons.cloud_upload_rounded,
          title: strings.backup,
          subtitle: strings.backupSubtitle,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.pageTurnGo('/settings/backup'),
        ),
      ],
    );
  }

  Widget _syncTile(BuildContext context, AppStrings strings, WidgetRef ref) {
    final state = ref.watch(syncControllerProvider);
    final syncing = state.status == SyncStatus.syncing;

    return SettingsTile(
      icon: syncing ? Icons.sync_rounded : Icons.cloud_sync_rounded,
      title: strings.synchronization,
      subtitle: _subtitle(strings, state),
      trailing: syncing
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: () => context.pageTurnGo('/settings/sync'),
    );
  }

  String _subtitle(AppStrings strings, SyncState state) {
    return switch (state.status) {
      SyncStatus.ready => strings.syncReady,
      SyncStatus.syncing => strings.syncInProgress,
      SyncStatus.unconfigured => strings.syncNotConfigured,
      SyncStatus.needsVault => strings.syncVaultPassword,
      SyncStatus.error => state.error ?? strings.synchronizationSubtitle,
      _ => strings.synchronizationSubtitle,
    };
  }
}
