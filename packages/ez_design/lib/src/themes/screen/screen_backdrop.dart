import 'package:flutter/widgets.dart';

import 'screen_theme_colors.dart';

/// Задник экранной темы: картинка под всем приложением.
///
/// Живёт **выше `MaterialApp`**, а не внутри страницы и не внутри оболочки.
/// Внутри страницы он обрезался бы её краями, а рисунок у него как раз по
/// краям кадра. Внутри оболочки он пересобирался бы на каждом переходе:
/// оболочка следит за адресом, и картинка на кадр мигала.
///
/// Отсюда и требование к цветам: тема передаётся значениями, а не берётся из
/// `Theme.of` — выше `MaterialApp` темы ещё нет.
///
/// [colors] равен null в блокнотных темах: там фон — бумага под страницей, и
/// рисует её сама страница вместе со своей разлиновкой.
class ScreenBackdrop extends StatelessWidget {
  const ScreenBackdrop({required this.colors, required this.child, super.key});

  final ScreenThemeColors? colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = this.colors;
    if (colors == null) return child;

    final backdrop = colors.backdrop;
    return DecoratedBox(
      decoration: BoxDecoration(
        // Переход держит экран, пока изображение не декодировано, и закрывает
        // края, если кадр не совпал с формой окна. Тема без задника обходится
        // им одним.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.backgroundStart, colors.backgroundEnd],
        ),
        image: backdrop == null
            ? null
            : DecorationImage(
                image: AssetImage(backdrop),
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
      ),
      child: child,
    );
  }
}
