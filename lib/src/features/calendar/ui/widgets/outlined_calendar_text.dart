import 'package:flutter/material.dart';

/// Текст с обводкой: читается поверх любой заливки ячейки.
class OutlinedCalendarText extends StatelessWidget {
  const OutlinedCalendarText({super.key, required this.text});

  final String text;

  /// Кегль до масштаба шрифта системы.
  static const fontSize = 7.5;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontFamily: 'Manrope',
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      height: 1,
    );

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: baseStyle.copyWith(
        color: Colors.white,
        shadows: const [
          Shadow(color: Colors.black, offset: Offset(-0.7, 0)),
          Shadow(color: Colors.black, offset: Offset(0.7, 0)),
          Shadow(color: Colors.black, offset: Offset(0, -0.7)),
          Shadow(color: Colors.black, offset: Offset(0, 0.7)),
        ],
      ),
    );
  }
}
