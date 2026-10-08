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

void main() {
  useTestEnvironment();

  testWidgets('ключ сохраняется, проверяется и удаляется', (tester) async {
    final store = _MemoryKeyStore();
    final server = MockClient((request) async {
      if (request.url.path.endsWith('/oauth')) {
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
          body: Builder(
            builder: (context) => Column(
              children: [
                const JarvisSettingsSection(),
                TextButton(
                  onPressed: () => showGigaChatKeySheet(context),
                  child: const Text('open'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Не подключена'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gigachat_check')), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('gigachat_key')), ' КЛЮЧ ');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('gigachat_save')));
    await tester.pumpAndSettle();

    expect(store.value, 'КЛЮЧ');
    expect(find.text('GigaChat на связи.'), findsOneWidget);
    expect(find.textContaining('Подключена'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gigachat_remove')));
    await tester.pumpAndSettle();
    expect(store.value, isNull);
    expect(find.textContaining('Не подключена'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
