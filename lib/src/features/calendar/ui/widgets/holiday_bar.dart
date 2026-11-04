import 'package:ez_design/ez_design.dart';
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
  static const _thread = AppPalette.holidayThread;

  /// Сколько лента занимает снизу: нить, поля и значок.
  static const extent = 14.0;

  @override
  Widget build(BuildContext context) {
    final bar = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppPalette.violetDeep,
            AppPalette.violet,
            AppPalette.violetDeep,
          ],
        ),
        border: Border(top: BorderSide(color: _thread, width: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(3, 2, 3, 2.5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.celebration_rounded,
              size: 8,
              color: _thread,
            ),
            const SizedBox(width: 2.5),
            Flexible(
              // Слово сжимается, но не обрезается: «Праз…» на ленте не
              // говорит ничего. В узкой ячейке и при крупном шрифте
              // системы места хватает не всегда.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  locale == 'ru' ? 'Праздник' : 'Holiday',
                  maxLines: 1,
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
            ),
          ],
        ),
      ),
    );

    if (!isMuted) return bar;
    return Opacity(opacity: 0.5, child: bar);
  }
}
