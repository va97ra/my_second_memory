import 'package:flutter/material.dart';

/// Переход между страницами календаря: уходящая уезжает за край, приходящая
/// приходит с противоположного.
///
/// Пока уходящей нет, показывается только приходящая — так календарь стоит
/// между листаниями.
class CalendarPageTransition extends StatelessWidget {
  const CalendarPageTransition({
    super.key,
    required this.animation,
    required this.axis,
    required this.direction,
    required this.incoming,
    this.outgoing,
  });

  final Animation<double> animation;
  final Axis axis;

  /// `1` — следующая страница, `-1` — предыдущая.
  final int direction;

  final Widget incoming;
  final Widget? outgoing;

  @override
  Widget build(BuildContext context) {
    final outgoingPage = outgoing;
    if (outgoingPage == null) return ClipRect(child: incoming);

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = axis == Axis.horizontal;
          final extent =
              horizontal ? constraints.maxWidth : constraints.maxHeight;

          return AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final progress = Curves.easeOutCubic.transform(animation.value);
              Offset offsetFor(double value) =>
                  horizontal ? Offset(value, 0) : Offset(0, value);

              return Stack(
                fit: StackFit.expand,
                children: [
                  Transform.translate(
                    key: const ValueKey('calendar_page_outgoing'),
                    offset: offsetFor(-direction * extent * progress),
                    child: IgnorePointer(child: outgoingPage),
                  ),
                  Transform.translate(
                    key: const ValueKey('calendar_page_incoming'),
                    offset: offsetFor(direction * extent * (1 - progress)),
                    child: incoming,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
