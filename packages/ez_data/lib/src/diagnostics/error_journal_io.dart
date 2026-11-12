import 'dart:io';

import 'package:ez_core/ez_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'error_journal_entry.dart';

/// Местный журнал необработанных ошибок.
///
/// Лежит файлом в служебном каталоге приложения и никуда не уезжает:
/// приложение local-first, телеметрии в нём нет. Журнал ограничен по
/// размеру — переполнившись, он забывает старую половину.
class ErrorJournal {
  ErrorJournal({String? directory, this.maxBytes = 256 * 1024})
      : _directory = directory;

  static const fileName = 'error_journal.log';

  final String? _directory;
  final int maxBytes;
  final _writes = SequentialTaskQueue();

  Future<void> record(Object error, StackTrace? stack, {DateTime? at}) {
    return _writes.add(() async {
      try {
        final file = await _file();
        await file.writeAsString(
          errorJournalEntry(error, stack, at ?? DateTime.now()),
          mode: FileMode.append,
          flush: true,
        );
        if (await file.length() > maxBytes) await _forgetOlderHalf(file);
      } on Object catch (failure) {
        // Сообщить об ошибке журнала некуда, кроме консоли.
        debugPrint('Error journal is unavailable: $failure');
      }
    });
  }

  /// Весь журнал, старое сверху; пустая строка — ошибок не было.
  Future<String> read() async {
    final file = await _file();
    return await file.exists() ? file.readAsString() : '';
  }

  Future<File> _file() async {
    final directory =
        _directory ?? (await getApplicationSupportDirectory()).path;
    return File(p.join(directory, fileName));
  }

  /// Оставляет последнюю половину, начиная с целой записи.
  Future<void> _forgetOlderHalf(File file) async {
    final text = await file.readAsString();
    final cut = text.indexOf('=== ', text.length ~/ 2);
    await file.writeAsString(cut < 0 ? '' : text.substring(cut), flush: true);
  }
}
