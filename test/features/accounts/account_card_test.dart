import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/accounts/state/accounts_controller.dart';
import 'package:ezhednevnik_v2/src/features/accounts/ui/account_editor_screen.dart';
import 'package:ezhednevnik_v2/src/features/accounts/ui/widgets/account_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/backup_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final account = AccountItem(
    id: 'mail',
    serviceName: 'Почта',
    login: 'user',
    password: 'secret',
    email: 'user@mail.test',
    website: 'https://mail.test',
    note: 'Заметка',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  Widget grid(FakeAccountRepository repository) => ProviderScope(
        overrides: [accountRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('ru'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                AccountGrid(accountIds: ['mail']),
              ],
            ),
          ),
        ),
      );

  test('на телефоне две карточки в ряду, на широком экране больше', () {
    expect(accountCardColumns(320), 2);
    expect(accountCardColumns(411), 2);
    expect(accountCardColumns(1280), 5);
  });

  test('цвет карточки переживает запись и его можно снять', () {
    final tinted = account.copyWith(tintHue: 200);
    expect(AccountItem.fromJson(tinted.toJson()).tintHue, 200);
    expect(tinted.copyWith(clearTintHue: true).tintHue, isNull);
    expect(account.toJson().containsKey('tintHue'), isFalse);
  });

  const copyTooltips = [
    'Скопировать логин',
    'Скопировать почту',
    'Скопировать пароль',
    'Скопировать сайт',
    'Скопировать заметку',
  ];

  testWidgets('на карточке кнопок копирования нет, значения видны',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(grid(FakeAccountRepository([account])));
    await tester.pumpAndSettle();

    for (final tooltip in copyTooltips) {
      expect(find.byTooltip(tooltip), findsNothing);
    }
    expect(find.text('user@mail.test'), findsOneWidget);
    expect(find.text('secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  Widget editor(FakeAccountRepository repository) => ProviderScope(
        overrides: [accountRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          locale: Locale('ru'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: _EditorOnceLoaded(),
        ),
      );

  for (final width in [320.0, 360.0, 600.0, 840.0]) {
    testWidgets('в открытом аккаунте каждое поле копируется на ширине $width',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      String? clipboard;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(editor(FakeAccountRepository([account])));
      await tester.pumpAndSettle();

      for (final (index, value) in const [
        'user',
        'user@mail.test',
        'secret',
        'https://mail.test',
        'Заметка',
      ].indexed) {
        await tester.tap(find.byTooltip(copyTooltips[index]));
        await tester.pump();
        expect(clipboard, value);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('у пустого поля кнопки копирования нет', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(editor(
      FakeAccountRepository([account.copyWith(website: '')]),
    ));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Скопировать сайт'), findsNothing);
    expect(find.byTooltip('Скопировать логин'), findsOneWidget);
  });

  testWidgets('нажатие на букву открывает полоску, выбранный цвет сохраняется',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = FakeAccountRepository([account]);

    await tester.pumpWidget(grid(repository));
    await tester.pumpAndSettle();
    expect(find.text('Почта'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('account_color_mail')));
    await tester.pumpAndSettle();
    final strip = find.byKey(const ValueKey('account_tint_strip'));
    expect(strip, findsOneWidget);
    expect(find.text('Почта'), findsNothing);

    await tester.tap(strip);
    await tester.pumpAndSettle();
    expect(strip, findsNothing);
    expect(find.text('Почта'), findsOneWidget);
    expect(repository.accounts.single.tintHue, isNotNull);

    await tester.tap(find.byKey(const ValueKey('account_color_mail')));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getTopLeft(strip) + const Offset(3, 12));
    await tester.pumpAndSettle();
    expect(repository.accounts.single.tintHue, isNull);
    expect(tester.takeException(), isNull);
  });
}

/// Редактор читает аккаунт один раз при открытии, поэтому ждёт загрузки списка.
class _EditorOnceLoaded extends ConsumerWidget {
  const _EditorOnceLoaded();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loaded = ref.watch(accountByIdProvider('mail')) != null;
    return loaded
        ? const AccountEditorScreen(accountId: 'mail')
        : const SizedBox.shrink();
  }
}
