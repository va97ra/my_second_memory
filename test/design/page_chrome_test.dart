import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Шапка страницы собирается из общих, а не пишется заново на каждой
/// странице — см. `docs/layout.md`. Проверяется по исходникам: свою шапку
/// видно только в коде, а на снимке экрана она выглядит почти так же, и
/// расхождение всплывает через полгода, когда общую шапку меняют.
void main() {
  /// Страницы, которым шапка не положена или положена своя. Каждая — с
  /// причиной в `docs/layout.md`; без причины список не растёт.
  const allowed = {
    // Инструменты названы кнопкой прямо над собой.
    'calculator_screen.dart',
    'converter_screen.dart',
    'finance_screen.dart',
    // Шапка из полос: два ряда не ложатся в один слотовый.
    'calendar_screen.dart',
    'home_feed_screen.dart',
    // Снимок во весь экран, шапка прозрачная поверх него.
    'memory_image_viewer_screen.dart',
    // Пустое место в панели: экран говорит, что здесь пусто.
    'empty_tool_screen.dart',
  };

  const sharedChrome = [
    'MainPageHeader(',
    'MainSliverAppBar(',
    'AppPageAppBar(',
    'MemoryEditorAppBar(',
  ];

  test('every screen wears one of the shared headers', () {
    final offenders = <String>[];

    for (final entity in Directory('lib/src').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('_screen.dart')) continue;
      // Экраны лежат в `ui/`, а не в `ui/widgets/`: там части экранов, и
      // шапки им не положено — см. `docs/architecture.md`.
      if (entity.uri.pathSegments.contains('widgets')) continue;
      final name = entity.uri.pathSegments.last;
      if (allowed.contains(name)) continue;

      final source = entity.readAsStringSync();
      final wearsShared = sharedChrome.any(source.contains);
      if (!wearsShared) {
        offenders.add('$name: шапки нет — возьмите общую или впишите причину');
      } else if (RegExp(r'[^a-zA-Z](AppBar|SliverAppBar)\(').hasMatch(source)) {
        offenders.add('$name: своя AppBar рядом с общей шапкой');
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
