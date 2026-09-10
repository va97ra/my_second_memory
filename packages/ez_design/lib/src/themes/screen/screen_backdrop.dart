import 'package:flutter/material.dart';

import 'screen_visuals.dart';

/// Задник экранной темы под всем приложением.
///
/// Кладётся выше `Scaffold`, а не внутрь страницы, нарочно: рисунок у задника
/// по краям кадра — как раз там, где стоят панели инструментов и навигации.
/// Нарисованный только под страницей, он оставался бы виден лишь в просветах
/// между карточками, а светящаяся рамка уходила под панели целиком.
///
/// В блокнотных темах виджет ничего не делает: там фон — бумага под страницей,
/// и рисует её сама страница вместе со своей разлиновкой.
class ScreenBackdrop extends StatelessWidget {
  const ScreenBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenVisuals.maybeOf(context);
    if (screen == null) return child;

    return DecoratedBox(
      decoration: BoxDecoration(
        // Заливка под изображением держит экран, пока оно не декодировано, и
        // закрывает края, если кадр не совпал с формой окна.
        color: screen.colors.backgroundStart,
        image: DecorationImage(
          image: AssetImage(screen.colors.backdrop),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
      child: child,
    );
  }
}
