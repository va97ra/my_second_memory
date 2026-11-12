import 'dart:io';

import 'package:ez_data/ez_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Необработанные ошибки ложатся в местный журнал, а он не растёт без края.
void main() {
  late Directory directory;

  setUp(() => directory = Directory.systemTemp.createTempSync('journal'));
  tearDown(() => directory.deleteSync(recursive: true));

  test('errors are written one after another', () async {
    final journal = ErrorJournal(directory: directory.path);

    await journal.record(
      StateError('первая'),
      StackTrace.current,
      at: DateTime(2026, 11, 12, 9),
    );
    await journal.record(
      const FormatException('вторая'),
      null,
      at: DateTime(2026, 11, 12, 10),
    );

    final text = await journal.read();
    expect(text, contains('=== 2026-11-12T09:00:00.000 ==='));
    expect(text, contains('StateError'));
    expect(text, contains('первая'));
    expect(text.indexOf('первая'), lessThan(text.indexOf('вторая')));
  });

  test('a long message is cut, the journal keeps only recent entries',
      () async {
    final journal = ErrorJournal(directory: directory.path, maxBytes: 4000);

    for (var index = 0; index < 40; index++) {
      await journal.record(StateError('ошибка $index ${'x' * 1000}'), null);
    }

    final text = await journal.read();
    expect(text.length, lessThanOrEqualTo(4000 * 2));
    expect(text, contains('ошибка 39'));
    expect(text, isNot(contains('ошибка 0 ')));
    expect(text, isNot(contains('x' * 400)));
    expect(text, startsWith('=== '));
  });

  test('an empty journal reads as empty', () async {
    expect(await ErrorJournal(directory: directory.path).read(), isEmpty);
  });
}
