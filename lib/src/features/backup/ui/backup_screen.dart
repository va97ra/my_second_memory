import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_strings.dart';
import '../../../shared/ui/app_shell.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';
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
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(strings.backup),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFBF3E8),
                Color(0xFFF7ECDB),
                Color(0xFFFCF7EF),
              ],
            ),
          ),
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
    );
  }

  Future<void> _exportBackup() async {
    final strings = AppStrings.of(context);
    setState(() => _isBusy = true);
    try {
      final backupJson = await _service().createBackupJson();
      final saveLocation = await getSaveLocation(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
        suggestedName:
            'ezhednevnik_v2_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json',
      );
      if (saveLocation == null) {
        return;
      }

      await XFile.fromData(
        utf8.encode(backupJson),
        mimeType: 'application/json',
        name: saveLocation.path.split(RegExp(r'[\\/]')).last,
      ).saveTo(saveLocation.path);

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
          XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
      );
      if (file == null) {
        return;
      }

      final data = await _service().parseBackupJson(await file.readAsString());
      await ref
          .read(memoryItemsControllerProvider.notifier)
          .replaceAll(data.memoryItems);
      await ref
          .read(shiftSchedulesControllerProvider.notifier)
          .replaceAll(data.shiftSchedules);

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
