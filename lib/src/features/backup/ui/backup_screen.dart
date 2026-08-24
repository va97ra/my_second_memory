import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ez_core/ez_core.dart';
import '../../../app/app_shell.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../../accounts/state/accounts_controller.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';
import 'package:ez_data/ez_data.dart';

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
      activeDestinationId: 'settings',
      child: Scaffold(
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BackupHint(text: strings.backupDownloadsHint),
                          const SizedBox(height: 10),
                          _BackupActionButton(
                            icon: Icons.cloud_upload_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            title: strings.exportBackup,
                            onPressed: _isBusy ? null : _exportBackup,
                          ),
                          const SizedBox(height: 10),
                          _BackupActionButton(
                            icon: Icons.restore_page_rounded,
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
      recurrenceRepository: ref.read(recurrenceRepositoryProvider),
      recurrenceExceptionRepository:
          ref.read(recurrenceExceptionRepositoryProvider),
    );
  }

  Future<void> _exportBackup() async {
    final strings = AppStrings.of(context);
    setState(() => _isBusy = true);
    String? temporaryPath;
    try {
      final password = await _askPassword(
        strings.createBackupPassword,
        confirmPassword: true,
        submitLabel: strings.save,
      );
      if (password == null || password.isEmpty) {
        return;
      }
      final service = _service();
      final fileName =
          'ezhednevnik_v2_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.zip';
      temporaryPath = await service.createStreamingBackupFile(password);
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
        return;
      }

      if (temporaryPath != null) {
        await XFile(temporaryPath).saveTo(saveLocation.path);
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
    } on Object {
      if (mounted) {
        _showMessage(strings.backupCreateFailed);
      }
    } finally {
      if (temporaryPath != null) {
        try {
          await _service().deleteTemporaryBackup(temporaryPath);
        } on Object {
          // The system will eventually clear its temporary directory.
        }
      }
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
          ? await _askPassword(
              strings.enterBackupPassword,
              confirmPassword: false,
              submitLabel: strings.importBackup,
            )
          : null;
      if (_looksLikeZip(bytes) && (password == null || password.isEmpty)) {
        return;
      }
      final service = _service();
      final data = await service.parseBackupBytes(bytes, password: password);
      await service.restore(data);
      _reloadRestoredData();

      if (mounted) {
        _showMessage(strings.backupRestored);
      }
    } on BackupPasswordException {
      if (mounted) {
        _showMessage(strings.invalidBackupPassword);
      }
    } on FormatException {
      if (mounted) {
        _showMessage(strings.invalidBackupFile);
      }
    } on Object {
      if (mounted) {
        _showMessage(strings.backupRestoreFailed);
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

  void _reloadRestoredData() {
    ref.invalidate(memoryItemsControllerProvider);
    ref.invalidate(memoryItemsLoadProvider);
    ref.invalidate(shiftSchedulesControllerProvider);
    ref.invalidate(accountsControllerProvider);
    ref.invalidate(recurrenceExceptionControllerProvider);
    ref.invalidate(recurrenceSeriesControllerProvider);
    ref.invalidate(recurrenceLoadProvider);
  }

  Future<String?> _askPassword(
    String title, {
    required bool confirmPassword,
    required String submitLabel,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _BackupPasswordDialog(
        title: title,
        confirmPassword: confirmPassword,
        submitLabel: submitLabel,
      ),
    );
  }

  bool _looksLikeZip(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x50 &&
        bytes[1] == 0x4B &&
        bytes[2] == 0x03 &&
        bytes[3] == 0x04;
  }
}

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog({
    required this.title,
    required this.confirmPassword,
    required this.submitLabel,
  });

  final String title;
  final bool confirmPassword;
  final String submitLabel;

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscureText = true;
  String? _confirmationError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;
    if (widget.confirmPassword &&
        password != _confirmationController.text.trim()) {
      setState(() {
        _confirmationError = AppStrings.of(context).backupPasswordsDoNotMatch;
      });
      return;
    }
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final visibilityButton = IconButton(
      tooltip: _obscureText ? strings.showPassword : strings.hidePassword,
      onPressed: () => setState(() => _obscureText = !_obscureText),
      icon: Icon(
        _obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded,
      ),
    );

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const ValueKey('backup_password'),
              controller: _passwordController,
              autofocus: true,
              obscureText: _obscureText,
              textInputAction: widget.confirmPassword
                  ? TextInputAction.next
                  : TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: strings.backupPassword,
                helperText: strings.backupPasswordHint,
                helperMaxLines: 2,
                suffixIcon: visibilityButton,
              ),
              onChanged: (_) {
                if (_confirmationError != null) {
                  setState(() => _confirmationError = null);
                }
              },
              onSubmitted: widget.confirmPassword ? null : (_) => _submit(),
            ),
            if (widget.confirmPassword) ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('backup_password_confirmation'),
                controller: _confirmationController,
                obscureText: _obscureText,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: strings.repeatBackupPassword,
                  errorText: _confirmationError,
                ),
                onChanged: (_) {
                  if (_confirmationError != null) {
                    setState(() => _confirmationError = null);
                  }
                },
                onSubmitted: (_) => _submit(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
        FilledButton(
          key: const ValueKey('backup_password_submit'),
          onPressed: _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}

class _BackupHint extends StatelessWidget {
  const _BackupHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.download_done_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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
