import 'dart:convert';

import 'package:ez_core/ez_core.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_brain_providers.dart';
import 'package:ezhednevnik_v2/src/features/settings/ui/widgets/gigachat_key_sheet.dart';
import 'package:ezhednevnik_v2/src/features/settings/ui/widgets/jarvis_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/widget_test_harness.dart';

/// Защищённого хранилища в тестах нет — ключ живёт в памяти.
class _MemoryKeyStore extends GigaChatKeyStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> save(String authKey) async => value = authKey.trim();

  @override
  Future<void> delete() async => value = null;
}

/// GigaChat, который принимает ключ, отвергает его или недоступен.
enum _Server { accepts, rejects, offline }

const _realKey = 'Y2xpZW50LWlkOmNsaWVudC1zZWNyZXQ=';

void main() {
  useTestEnvironment();

  Future<_MemoryKeyStore> open(
    WidgetTester tester,
    _Server mode, {
    String? stored,
  }) async {
    final store = _MemoryKeyStore()..value = stored;
    final server = MockClient((request) async {
      if (mode == _Server.offline) throw http.ClientException('нет сети');
      if (request.url.path.endsWith('/oauth')) {
        if (mode == _Server.rejects) return http.Response('{}', 401);
        return http.Response(
            jsonEncode({'access_token': 'T', 'expires_at': 4102444800000}),
            200);
      }
      return http.Response.bytes(
        utf8.encode(jsonEncode({
          'choices': [
            {
              'message': {'role': 'assistant', 'content': 'Готов.'},
            },
          ],
        })),
        200,
      );
    });
    await tester.pumpWidget(testProviderScope(
      overrides: [
        gigaChatKeyStoreProvider.overrideWithValue(store),
        gigaChatClientProvider.overrideWith((ref) {
          final key = ref.watch(gigaChatKeyProvider).valueOrNull;
          return key == null
              ? null
              : GigaChatClient(authKey: key, connect: () async => server);
        }),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppStrings.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          // Раздел длиннее экрана теста: как и настоящие настройки, он
          // прокручивается, а кнопка открытия стоит над ним.
          body: Builder(
            builder: (context) => ListView(
              children: [
                TextButton(
                  onPressed: () => showGigaChatKeySheet(context),
                  child: const Text('open'),
                ),
                const JarvisSettingsSection(),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return store;
  }

  final field = find.byKey(const ValueKey('gigachat_key'));

  Future<void> enter(WidgetTester tester, String text) async {
    await tester.enterText(field, text);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('gigachat_save')));
    await tester.pumpAndSettle();
  }

  testWidgets('подтверждённый ключ прячет поле, удаление возвращает его',
      (tester) async {
    final store = await open(tester, _Server.accepts);
    expect(find.textContaining('Не подключена'), findsOneWidget);
    expect(find.byKey(const ValueKey('gigachat_check')), findsNothing);

    // Фраза — не ключ: сохранить нельзя, под полем сказано почему.
    await tester.enterText(
        field, 'какой день на этой неделе у меня самый свободный');
    await tester.pump();
    expect(find.text('Не похоже на ключ GigaChat'), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('gigachat_save')))
            .onPressed,
        isNull);

    await enter(tester, ' $_realKey ');
    expect(store.value, _realKey);
    expect(find.text('GigaChat на связи.'), findsOneWidget);
    expect(field, findsNothing, reason: 'сохранённый ключ не правят');
    expect(find.textContaining('Подключена'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gigachat_remove')));
    await tester.pumpAndSettle();
    expect(store.value, isNull);
    expect(field, findsOneWidget);
    expect(find.textContaining('Не подключена'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ключ, который Сбер не принял, не сохраняется', (tester) async {
    final store = await open(tester, _Server.rejects);
    await enter(tester, _realKey);
    expect(store.value, isNull);
    expect(field, findsOneWidget);
    expect(find.textContaining('Ключ GigaChat не подошёл'), findsOneWidget);
  });

  testWidgets('без связи ключ не подтверждён — и не сохраняется',
      (tester) async {
    final store = await open(tester, _Server.offline);
    await enter(tester, _realKey);
    expect(store.value, isNull);
    expect(field, findsOneWidget);
    expect(find.text('Нет связи с GigaChat.'), findsOneWidget);
  });

  testWidgets('в хранилище текст вместо ключа — видно причину и поле',
      (tester) async {
    // Так однажды вышло на телефоне: в поле ключа попала фраза.
    await open(tester, _Server.accepts,
        stored: 'какой день на этой неделе у меня самый свободный');
    expect(find.textContaining('сохранён не ключ'), findsOneWidget);
    expect(field, findsOneWidget);
  });
}
