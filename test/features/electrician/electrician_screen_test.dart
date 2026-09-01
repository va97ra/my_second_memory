import 'package:ezhednevnik_v2/src/features/electrician/electrician.dart';
import 'package:ezhednevnik_v2/src/features/electrician/ui/widgets/electrician_art_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/widget_test_harness.dart';

void main() {
  useTestEnvironment();

  Future<void> pumpGuide(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(
      testProviderScope(
        child: const MaterialApp(
          locale: Locale('ru'),
          supportedLocales: [Locale('ru')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(body: ElectricianScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('разделы показаны плитками, пустые названы пустыми',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpGuide(tester);

    expect(find.text('Словарь'), findsOneWidget);
    expect(find.text('Безопасность'), findsOneWidget);
    expect(find.text('Справочник'), findsOneWidget);
    // Пустых разделов не осталось: у каждой плитки есть счёт.
    expect(find.text('Раздел ещё не наполнен'), findsNothing);
    expect(find.text('19 карточек'), findsOneWidget);
    expect(find.text('23 карточек'), findsOneWidget);
  });

  testWidgets('карточка отвечает на три вопроса и называет документ',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpGuide(tester);

    await tester.tap(find.text('Словарь'));
    await tester.pumpAndSettle();
    // Список длинный, поэтому до нужной карточки добираются поиском.
    await tester.enterText(
      find.byKey(const ValueKey('electrician_search')),
      'УЗО',
    );
    await tester.pumpAndSettle();
    // Слово стоит и в поле поиска, поэтому карточку ищут по строке списка.
    final card = find.widgetWithText(ListTile, 'УЗО');
    expect(card, findsOneWidget);

    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('Что это'), findsOneWidget);
    expect(find.text('Для чего'), findsOneWidget);
    expect(find.text('Что важно знать'), findsOneWidget);
    expect(find.textContaining('ГОСТ IEC 61008-1-2020'), findsOneWidget);
    // Содержание про аппарат защиты не сверено — экран говорит об этом.
    expect(
      find.text('Содержание не сверено по тексту документа'),
      findsOneWidget,
    );
  });

  testWidgets('определение единицы не требует пометки о сверке',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpGuide(tester);

    await tester.enterText(
      find.byKey(const ValueKey('electrician_search')),
      'мегаом',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ом'));
    await tester.pumpAndSettle();
    expect(find.textContaining('ГОСТ 8.417-2024'), findsOneWidget);
    expect(
      find.text('Содержание не сверено по тексту документа'),
      findsNothing,
    );
  });

  testWidgets('тема засчитывается только после верных ответов',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpGuide(tester);

    await tester.tap(find.text('Обучение'));
    await tester.pumpAndSettle();
    expect(find.text('0 %'), findsOneWidget);
    // Темы идут уровнями, как в задании. Дальние уровни лежат ниже сгиба,
    // поэтому проверяется первый и то, что заголовок уровня не один.
    expect(find.text('УРОВЕНЬ 1'), findsOneWidget);
    expect(find.textContaining('УРОВЕНЬ '), findsWidgets);

    await tester.tap(find.text('Что такое электрический ток'));
    await tester.pumpAndSettle();

    // Лист темы длинный, поэтому до каждого варианта его прокручивают.
    Future<void> answer(String option) async {
      final target = find.text(option);
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    // Неверный ответ объясняет ошибку и не засчитывает тему.
    await answer('Напряжение');
    expect(find.text('Неправильно'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await answer('Ток');
    expect(find.text('Правильно'), findsOneWidget);

    await answer('Он не течёт');
    final done = find.text('Тема пройдена');
    await tester.ensureVisible(done);
    await tester.pumpAndSettle();
    await tester.tap(done);
    await tester.pumpAndSettle();

    // Одна тема из двадцати трёх — четыре процента.
    expect(find.text('4 %'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('диагностика ведёт по дереву и доводит до вывода',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpGuide(tester);

    await tester.tap(find.text('Диагностика'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отключается автомат'));
    await tester.pumpAndSettle();

    // Сперва сказано, что сделать, и только потом — что получилось.
    expect(find.text('Что сделать'), findsOneWidget);
    expect(
      find.textContaining('Выньте из розеток линии все вилки'),
      findsOneWidget,
    );
    expect(find.text('Что делает автомат?'), findsOneWidget);
    // Кнопки названы исходом, а не «да» и «нет».
    expect(find.text('Да'), findsNothing);
    expect(find.text('Держит, не выключается'), findsOneWidget);

    await tester.tap(find.text('Сразу выключается'));
    await tester.pumpAndSettle();
    expect(find.text('Короткое замыкание в проводке'), findsOneWidget);
    expect(
      find.textContaining('нужна работа со снятием напряжения'),
      findsOneWidget,
    );

    // Ответ можно отменить и пойти другой веткой.
    await tester.tap(find.byIcon(Icons.undo_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Держит, не выключается'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Когда работают несколько сразу'));
    await tester.pumpAndSettle();
    expect(find.text('Перегрузка суммой нагрузки'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('у инструмента есть рисунок, и он открывается во весь экран',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpGuide(tester);

    await tester.tap(find.text('Инструменты'));
    await tester.pumpAndSettle();
    expect(find.byType(ElectricianArtView), findsWidgets);

    await tester.tap(find.text('Отвёртка'));
    await tester.pumpAndSettle();
    expect(find.byType(ElectricianArtView), findsWidgets);

    // Последний рисунок — тот, что в открытом листе; первые лежат в
    // списке позади него.
    await tester.tap(find.byType(ElectricianArtView).last);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('поиск идёт по всем разделам сразу и по синонимам',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpGuide(tester);

    await tester.enterText(
      find.byKey(const ValueKey('electrician_search')),
      'утечка',
    );
    await tester.pumpAndSettle();
    expect(find.text('УЗО'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('electrician_search')),
      'плакаты',
    );
    await tester.pumpAndSettle();
    expect(find.text('Подготовка рабочего места'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('electrician_search')),
      'такого слова нет',
    );
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });
}
