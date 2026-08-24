import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'sync_card.dart';
import 'sync_error_text.dart';

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
        if (errorText != null) ...[
          const SizedBox(height: 12),
          SyncErrorText(errorText!),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            key: const ValueKey('sync_now'),
            onPressed: syncing ? null : onSyncNow,
            icon: const Icon(Icons.sync_rounded),
            label: Text(strings.syncNow),
          ),
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
  String _lastSyncLabel(BuildContext context, AppStrings strings) {
    final time = lastSyncedAt;
    if (time == null) return strings.syncNever;
    final value = TimeOfDay.fromDateTime(time).format(context);
    final result = lastResult;
    if (result == null) return value;
    return '$value · ↓${result.downloaded} ↑${result.uploaded}';
  }
}
