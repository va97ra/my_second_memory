import 'package:flutter/material.dart';


/// Полоса праздника поверх ячейки дня.
class HolidayBar extends StatelessWidget {
  const HolidayBar({super.key, required this.locale, required this.isMuted});

  final String locale;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFD97706).withValues(
      alpha: isMuted ? 0.5 : 1,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: Text(
          locale == 'ru' ? 'Праздник' : 'Holiday',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: Colors.white,
            fontSize: 7.2,
            fontWeight: FontWeight.w900,
            height: 1,
            shadows: [
              Shadow(color: Colors.black, offset: Offset(-0.6, 0)),
              Shadow(color: Colors.black, offset: Offset(0.6, 0)),
              Shadow(color: Colors.black, offset: Offset(0, 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
