import 'package:flutter/material.dart';

/// Шкала выезжает, когда карточку понесли, и не ловит палец, пока её нет.
class FeedDayRailAppearing extends StatelessWidget {
  const FeedDayRailAppearing({
    super.key,
    required this.shown,
    required this.child,
  });

  static const _duration = Duration(milliseconds: 140);

  final bool shown;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !shown,
      child: AnimatedOpacity(
        opacity: shown ? 1 : 0,
        duration: _duration,
        child: AnimatedSlide(
          offset: shown ? Offset.zero : const Offset(0.3, 0),
          duration: _duration,
          curve: Curves.easeOutCubic,
          child: child,
        ),
      ),
    );
  }
}
