import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/ui/screen_chrome.dart';
import 'backup_actions.dart';
import 'widgets/backup_action_button.dart';
import 'widgets/backup_hint.dart';

/// Резервная копия: снять архив или восстановить данные из него.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      appBar: AppPageAppBar(
        fallbackLocation: '/settings',
        title: Text(strings.backup),
      ),
      body: WarmGradientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: _card(context, strings),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, AppStrings strings) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BackupHint(text: strings.backupDownloadsHint),
            const SizedBox(height: 10),
            BackupActionButton(
              icon: Icons.cloud_upload_rounded,
              color: colors.primary,
              title: strings.exportBackup,
              onPressed: _isBusy ? null : _export,
            ),
            const SizedBox(height: 10),
            BackupActionButton(
              icon: Icons.restore_page_rounded,
              color: const Color(0xFF16A34A),
              title: strings.importBackup,
              onPressed: _isBusy ? null : _import,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export() => _busy((actions) => actions.export());

  Future<void> _import() {
    return _busy((actions) async {
      if (await actions.confirmImport()) {
        await actions.import();
      }
    });
  }

  /// Пока идёт работа с архивом, обе кнопки заперты: вторая копия поверх
  /// первой ничего хорошего не даст.
  Future<void> _busy(Future<void> Function(BackupActions actions) run) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await run(BackupActions(context: context, ref: ref));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}
