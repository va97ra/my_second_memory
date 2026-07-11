import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../accounts/state/accounts_controller.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';
import '../data/backup_file_saver.dart';
import '../data/backup_service.dart';

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

    return AppShell(
      currentIndex: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(fallbackLocation: '/settings'),
          title: Text(strings.backup),
        ),
        body: ColoredBox(
          color: const Color(0x12A66F3F),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD6E2EF)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BackupHint(text: strings.backupDownloadsHint),
                          const SizedBox(height: 10),
                          _BackupActionButton(
                            icon: Icons.upload_file_outlined,
                            color: const Color(0xFF2563EB),
                            title: strings.exportBackup,
                            onPressed: _isBusy ? null : _exportBackup,
                          ),
                          const SizedBox(height: 10),
                          _BackupActionButton(
                            icon: Icons.restore_page_outlined,
                            color: const Color(0xFF16A34A),
                            title: strings.importBackup,
                            onPressed: _isBusy ? null : _confirmImportBackup,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BackupService _service() {
    return BackupService(
      memoryRepository: ref.read(memoryRepositoryProvider),
      shiftScheduleRepository: ref.read(shiftScheduleRepositoryProvider),
      accountRepository: ref.read(accountRepositoryProvider),
    );
  }

  Future<void> _exportBackup() async {
    final strings = AppStrings.of(context);
    setState(() => _isBusy = true);
    try {
      final password = await _askPassword(strings.createBackupPassword);
      if (password == null || password.isEmpty) {
        return;
      }
      final service = _service();
      final fileName =
          'ezhednevnik_v2_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.zip';
      final temporaryPath = await service.createStreamingBackupFile(password);
      final backupBytes = temporaryPath == null
          ? await service.createEncryptedBackupZip(password)
          : null;
      final downloadsPath = temporaryPath == null
          ? await BackupFileSaver.saveToDownloads(
              fileName: fileName,
              bytes: backupBytes!,
            )
          : await BackupFileSaver.saveFileToDownloads(
              fileName: fileName,
              sourcePath: temporaryPath,
            );
      if (downloadsPath != null) {
        if (temporaryPath != null) {
          await service.deleteTemporaryBackup(temporaryPath);
        }
        if (mounted) {
          _showMessage(strings.backupSavedToDownloads);
        }
        return;
      }
      final saveLocation = await getSaveLocation(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'ZIP', extensions: ['zip']),
        ],
        suggestedName: fileName,
      );
      if (saveLocation == null) {
        if (temporaryPath != null) {
          await service.deleteTemporaryBackup(temporaryPath);
        }
        return;
      }

      if (temporaryPath != null) {
        await XFile(temporaryPath).saveTo(saveLocation.path);
        await service.deleteTemporaryBackup(temporaryPath);
      } else {
        await XFile.fromData(
          backupBytes!,
          mimeType: 'application/zip',
          name: saveLocation.path.split(RegExp(r'[\\/]')).last,
        ).saveTo(saveLocation.path);
      }

      if (mounted) {
        _showMessage(strings.backupCreated);
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _confirmImportBackup() async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.restoreBackupQuestion),
        content: Text(strings.restoreBackupWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.importBackup),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _importBackup();
    }
  }

  Future<void> _importBackup() async {
    final strings = AppStrings.of(context);
    setState(() => _isBusy = true);
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Backup', extensions: ['zip', 'json']),
        ],
      );
      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      final password = _looksLikeZip(bytes)
          ? await _askPassword(strings.enterBackupPassword)
          : null;
      if (_looksLikeZip(bytes) && (password == null || password.isEmpty)) {
        return;
      }
      final data = await _service().parseBackupBytes(bytes, password: password);
      await ref
          .read(memoryItemsControllerProvider.notifier)
          .replaceAll(data.memoryItems);
      await ref
          .read(shiftSchedulesControllerProvider.notifier)
          .replaceAll(data.shiftSchedules);
      await ref
          .read(accountsControllerProvider.notifier)
          .replaceAll(data.accounts);

      if (mounted) {
        _showMessage(strings.backupRestored);
      }
    } on FormatException {
      if (mounted) {
        _showMessage(strings.invalidBackupFile);
      }
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<String?> _askPassword(String title) async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: InputDecoration(
            labelText: strings.backupPassword,
            helperText: strings.backupPasswordHint,
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(strings.save),
          ),
        ],
      ),
    );
    controller.dispose();
    return result?.trim();
  }

  bool _looksLikeZip(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;
  }
}

class _BackupHint extends StatelessWidget {
  const _BackupHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE).withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            const Icon(
              Icons.download_done_outlined,
              color: Color(0xFF2563EB),
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF334155),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupActionButton extends StatelessWidget {
  const _BackupActionButton({
    required this.icon,
    required this.color,
    required this.title,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: FilledButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
