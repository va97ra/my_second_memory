import 'package:flutter/material.dart';

/// Праздничная лента по нижнему краю ячейки дня.
///
/// Лежит вплотную к низу: скруглять её нечем — углы ей обрезает сама ячейка.
class HolidayBar extends StatelessWidget {
  const HolidayBar({super.key, required this.locale, required this.isMuted});

  final String locale;
  final bool isMuted;

  /// Золотая нить по верхнему краю — она отделяет ленту от бумаги и от
  /// цветной заливки смены под ней.
  static const _thread = Color(0xFFF7CE5B);

  @override
  Widget build(BuildContext context) {
    final bar = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFAF1B12), Color(0xFFE0670C), Color(0xFFAF1B12)],
        ),
        border: Border(top: BorderSide(color: _thread, width: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(3, 2, 3, 2.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration_rounded, size: 8, color: _thread),
            const SizedBox(width: 2.5),
            Flexible(
              child: Text(
                locale == 'ru' ? 'Праздник' : 'Holiday',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: Colors.white,
                  fontSize: 7.2,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                  height: 1,
                  shadows: [
                    Shadow(color: Colors.black54, offset: Offset(0, 0.6)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!isMuted) return bar;
    return Opacity(opacity: 0.5, child: bar);
  }
}
