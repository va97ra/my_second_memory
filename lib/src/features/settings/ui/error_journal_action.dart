import 'dart:convert';
import 'dart:typed_data';

import 'package:ez_core/ez_core.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/files/save_user_file.dart';
import '../../../shared/state/error_journal_provider.dart';

/// Отдаёт человеку журнал ошибок текстовым файлом — чтобы переслать его
/// разработчику, не подключая телефон к компьютеру.
Future<void> saveErrorJournal(BuildContext context, WidgetRef ref) async {
  final strings = AppStrings.of(context);
  final messenger = ScaffoldMessenger.of(context);
  void show(String text) =>
      messenger.showSnackBar(SnackBar(content: Text(text)));

  try {
    final text = await ref.read(errorJournalProvider).read();
    if (text.trim().isEmpty) {
      show(strings.errorJournalEmpty);
      return;
    }
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final saved = await saveUserFile(
      fileName: 'ezhednevnik-errors-$stamp.txt',
      type: const XTypeGroup(
        label: 'TXT',
        extensions: ['txt'],
        mimeTypes: ['text/plain'],
      ),
      bytes: Uint8List.fromList(utf8.encode(text)),
    );
    switch (saved) {
      case SavedTo.downloads:
        show(strings.errorJournalSavedToDownloads);
      case SavedTo.chosenPlace:
        show(strings.errorJournalSaved);
      case SavedTo.nowhere:
        break;
    }
  } on Object {
    show(strings.errorJournalSaveFailed);
  }
}
