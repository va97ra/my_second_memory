import 'package:flutter/widgets.dart';

/// Поле снизу ровно под выехавшую клавиатуру.
///
/// Клавиатура приезжает не рывком, а десятком кадров, и на каждом кадре у неё
/// новая высота. Кто высоту читает, тот на каждом кадре и пересобирается —
/// поэтому чтение живёт здесь, отдельно от содержимого. Пересобирается один
/// этот виджет, а поля, кнопки и списки внутри остаются теми же и только
/// сдвигаются вверх.
class KeyboardInsetPadding extends StatelessWidget {
  const KeyboardInsetPadding({
    required this.child,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// Собственные поля содержимого. Клавиатура прибавляется к нижнему.
  final EdgeInsets padding;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding +
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    );
  }
}
