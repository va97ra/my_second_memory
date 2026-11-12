import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'sync_card.dart';
import 'sync_submit_block.dart';

/// Облако подключено: когда синхронизировались в прошлый раз и что дальше.
class SyncConnectedCard extends StatelessWidget {
  const SyncConnectedCard({
    super.key,
    required this.email,
    required this.syncing,
    required this.lastSyncedAt,
    required this.lastResult,
    required this.errorText,
    required this.onSyncNow,
    required this.onSignOut,
  });

  final String? email;
  final bool syncing;
  final DateTime? lastSyncedAt;
  final SyncRunResult? lastResult;
  final String? errorText;
  final VoidCallback onSyncNow;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return SyncCard(
      icon: syncing ? Icons.sync_rounded : Icons.cloud_done_rounded,
      title: syncing ? strings.syncInProgress : strings.syncReady,
      children: [
        if (email != null) Text(email!),
        const SizedBox(height: 8),
        Text(_lastSyncLabel(context, strings)),
        SyncSubmitBlock(
          errorText: errorText,
          buttonKey: const ValueKey('sync_now'),
          onPressed: syncing ? null : onSyncNow,
          icon: Icons.sync_rounded,
          label: strings.syncNow,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            key: const ValueKey('sync_sign_out'),
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: Text(strings.syncSignOut),
          ),
        ),
      ],
    );
  }

  /// Время прошлой синхронизации, а рядом — сколько записей пришло и ушло.
  ///
  /// Вложения считаются отдельно и показываются, только когда они ездили:
  /// пустая строка «файлов 0» — это шум, а не сведения.
  String _lastSyncLabel(BuildContext context, AppStrings strings) {
    final time = lastSyncedAt;
    if (time == null) return strings.syncNever;
    final value = TimeOfDay.fromDateTime(time).format(context);
    final result = lastResult;
    if (result == null) return value;
    final line = '$value · ↓${result.downloaded} ↑${result.uploaded}';
    final media = result.mediaDownloaded + result.mediaUploaded;
    if (media == 0 && result.mediaFailed == 0) return line;
    final files = '${strings.syncFiles} '
        '↓${result.mediaDownloaded} ↑${result.mediaUploaded}';
    return result.mediaFailed == 0
        ? '$line · $files'
        : '$line · $files · ${strings.syncFilesLeft(result.mediaFailed)}';
  }
}
