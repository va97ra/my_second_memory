import 'dart:typed_data';

import 'package:ez_core/ez_core.dart';
import 'package:ez_data/ez_data.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/backup_file_rules.dart';
import '../state/backup_providers.dart';
import 'widgets/backup_password_dialog.dart';

/// Снятие и восстановление резервной копии.
///
/// Каждый шаг, который спрашивает человека — пароль, место сохранения, файл —
/// живёт здесь; сама копия собирается и разбирается в [BackupService].
class BackupActions {
  const BackupActions({required this.context, required this.ref});

  final BuildContext context;
  final WidgetRef ref;

  BackupService get _service => ref.read(backupServiceProvider);

  Future<void> export() async {
    final strings = AppStrings.of(context);
    final password = await askBackupPassword(
      context,
      title: strings.createBackupPassword,
      confirmPassword: true,
      submitLabel: strings.save,
    );
    if (password == null || password.isEmpty) return;

    String? temporaryPath;
    try {
      final fileName = backupFileName(DateTime.now());
      // Крупная копия пишется во временный файл, чтобы не держать её в памяти
      // целиком; мелкая приходит байтами.
      temporaryPath = await _service.createStreamingBackupFile(password);
      final bytes = temporaryPath == null
          ? await _service.createEncryptedBackupZip(password)
          : null;

      final saved = temporaryPath == null
          ? await BackupFileSaver.saveToDownloads(
              fileName: fileName,
              bytes: bytes!,
            )
          : await BackupFileSaver.saveFileToDownloads(
              fileName: fileName,
              sourcePath: temporaryPath,
            );
      if (saved != null) {
        _show(strings.backupSavedToDownloads);
        return;
      }
      // Папки «Загрузки» может не быть — тогда место выбирают руками.
      await _saveWhereAsked(fileName, temporaryPath, bytes);
    } on Object {
      _show(strings.backupCreateFailed);
    } finally {
      await _deleteTemporary(temporaryPath);
    }
  }

  Future<void> _saveWhereAsked(
    String fileName,
    String? temporaryPath,
    Uint8List? bytes,
  ) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'ZIP', extensions: ['zip']),
      ],
      suggestedName: fileName,
    );
    if (location == null) return;

    if (temporaryPath != null) {
      await XFile(temporaryPath).saveTo(location.path);
    } else {
      await XFile.fromData(
        bytes!,
        mimeType: 'application/zip',
        name: location.path.split(RegExp(r'[\\/]')).last,
      ).saveTo(location.path);
    }
    if (context.mounted) {
      _show(AppStrings.of(context).backupCreated);
    }
  }

  Future<void> _deleteTemporary(String? temporaryPath) async {
    if (temporaryPath == null) return;
    try {
      await _service.deleteTemporaryBackup(temporaryPath);
    } on Object {
      // Систему временных файлов приберёт за нами.
    }
  }

  /// Восстановление стирает то, что лежит сейчас, поэтому его подтверждают.
  Future<bool> confirmImport() async {
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
    return confirmed ?? false;
  }

  Future<void> import() async {
    final strings = AppStrings.of(context);
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(label: 'Backup', extensions: ['zip', 'json']),
        ],
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final encrypted = looksLikeZip(bytes);
      String? password;
      if (encrypted) {
        if (!context.mounted) return;
        password = await askBackupPassword(
          context,
          title: strings.enterBackupPassword,
          confirmPassword: false,
          submitLabel: strings.importBackup,
        );
        if (password == null || password.isEmpty) return;
      }

      final data = await _service.parseBackupBytes(bytes, password: password);
      await _service.restore(data);
      reloadRestoredData(ref);
      _show(strings.backupRestored);
    } on BackupPasswordException {
      _show(strings.invalidBackupPassword);
    } on FormatException {
      _show(strings.invalidBackupFile);
    } on Object {
      _show(strings.backupRestoreFailed);
    }
  }

  void _show(String text) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
