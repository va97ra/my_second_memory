import 'dart:convert';
import 'dart:io';

import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/settings/ui/error_journal_action.dart';
import 'package:ezhednevnik_v2/src/shared/state/error_journal_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late List<MethodCall> calls;
  const channel = MethodChannel('ezhednevnik_v2/downloads');

  setUp(() {
    directory = Directory.systemTemp.createTempSync('journal');
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return 'Загрузки/${call.arguments['fileName']}';
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    directory.deleteSync(recursive: true);
  });

  Future<void> tapSave(WidgetTester tester, ErrorJournal journal) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [errorJournalProvider.overrideWithValue(journal)],
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => saveErrorJournal(context, ref),
                child: const Text('save'),
              ),
            ),
          ),
        ),
      ),
    );
    // Журнал читается с диска по-настоящему: нажатие и его ожидание идут в
    // реальном времени, а не на поддельных часах теста.
    await tester.runAsync(() async {
      await tester.tap(find.text('save'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
  }

  testWidgets('журнал ложится в «Загрузки» текстовым файлом', (tester) async {
    final journal = ErrorJournal(directory: directory.path);
    await tester.runAsync(() => journal.record(
          StateError('сломалось'),
          StackTrace.empty,
          at: DateTime(2026, 11, 12, 21),
        ));

    await tapSave(tester, journal);

    expect(calls.single.method, 'saveBytes');
    final fileName = calls.single.arguments['fileName'] as String;
    expect(fileName, endsWith('.txt'));
    final text = utf8.decode(calls.single.arguments['bytes'] as List<int>);
    expect(text, contains('сломалось'));
    expect(find.text('Журнал ошибок сохранён в Загрузки'), findsOneWidget);
  });

  testWidgets('пустой журнал не сохраняется, а так и говорит', (tester) async {
    await tapSave(tester, ErrorJournal(directory: directory.path));

    expect(calls, isEmpty);
    expect(find.text('Ошибок не было — журнал пуст'), findsOneWidget);
  });
}
