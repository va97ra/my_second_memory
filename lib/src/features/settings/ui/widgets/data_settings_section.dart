import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../sync/sync.dart';
import '../error_journal_action.dart';
import 'settings_chevron.dart';
import 'settings_section.dart';
import 'settings_tile.dart';

/// Защита и данные: PIN, облако, резервная копия, архив.
class DataSettingsSection extends ConsumerWidget {
  const DataSettingsSection({super.key, required this.isRu});

  final bool isRu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    // Без адреса облака синхронизации нет вовсе, и плитки для неё тоже.
    final syncEnabled = ref.watch(syncBackendConfigProvider).isConfigured;

    return SettingsSection(
      title: isRu ? 'Защита и данные' : 'Security and data',
      children: [
        SettingsTile(
          icon: Icons.lock_rounded,
          color: AppPalette.indigo,
          title: strings.pinSecurity,
          trailing: const SettingsChevron(),
          onTap: () => context.pageTurnGo('/security'),
        ),
        if (syncEnabled) _syncTile(context, strings, ref),
        SettingsTile(
          icon: Icons.cloud_upload_rounded,
          color: AppPalette.turquoise,
          title: strings.backup,
          subtitle: strings.backupSubtitle,
          trailing: const SettingsChevron(),
          onTap: () => context.pageTurnGo('/settings/backup'),
        ),
        SettingsTile(
          icon: Icons.inventory_2_rounded,
          color: AppPalette.violet,
          title: strings.memoryArchive,
          trailing: const SettingsChevron(),
          onTap: () => context.pageTurnGo('/memory'),
        ),
        SettingsTile(
          icon: Icons.bug_report_rounded,
          color: AppPalette.amber,
          title: strings.errorJournal,
          subtitle: strings.errorJournalSubtitle,
          onTap: () => saveErrorJournal(context, ref),
        ),
      ],
    );
  }

  Widget _syncTile(BuildContext context, AppStrings strings, WidgetRef ref) {
    final state = ref.watch(syncControllerProvider);
    final syncing = state.status == SyncStatus.syncing;

    return SettingsTile(
      icon: syncing ? Icons.sync_rounded : Icons.cloud_sync_rounded,
      color: AppPalette.cyan,
      title: strings.synchronization,
      subtitle: _subtitle(strings, state),
      trailing: syncing
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const SettingsChevron(),
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
