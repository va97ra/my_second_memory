import 'package:ezhednevnik_v2/src/shared/ui/chrome/app_page_app_bar.dart';
import 'package:ezhednevnik_v2/src/shared/ui/chrome/main_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Кнопка подсказки встаёт слева, рядом со стрелкой «назад». Заголовок при
/// этом обязан остаться посередине: иначе одна и та же страница с подсказкой
/// и без неё выглядит по-разному, а шапки перестают быть одинаковыми.
void main() {
  const hint = 'Что здесь можно сделать.';

  /// Короткий нарочно: в тестах каждая буква — квадрат в размер шрифта, и
  /// обычное слово занимает вдвое больше места, чем настоящим шрифтом.
  const title = 'Дни';

  double titleOffset(WidgetTester tester, Finder header) {
    final headerBox = tester.getRect(header);
    final titleBox = tester.getRect(find.text(title));
    return titleBox.center.dx - headerBox.center.dx;
  }

  testWidgets('the page header keeps its title centred with a hint',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final hintText in [null, hint]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          home: Scaffold(
            body: MainPageHeader(
              title: title,
              backLocation: '/calendar',
              hint: hintText,
              trailing: const Icon(Icons.filter_list_rounded),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        titleOffset(tester, find.byType(MainPageHeader)).abs(),
        lessThan(1),
        reason: 'подсказка: $hintText',
      );
    }
  });

  testWidgets('the app bar keeps its title centred with a hint',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final hintText in [null, hint]) {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          home: Scaffold(
            appBar: AppPageAppBar(
              title: const Text(title),
              fallbackLocation: '/settings',
              hint: hintText,
              actions: const [Icon(Icons.more_vert_rounded)],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        titleOffset(tester, find.byType(AppBar)).abs(),
        lessThan(1),
        reason: 'подсказка: $hintText',
      );
    }
  });
}
