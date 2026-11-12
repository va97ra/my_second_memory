import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'day_timeline_geometry.dart';
import 'day_timeline_handle.dart';
import 'day_timeline_range_label.dart';

/// Место рамки на шкале: и новой, и записи. Содержимое лежит посередине, а сверху
/// и снизу оставлено поле под флажки.
///
/// Поле обязательно: Flutter не отдаёт касания за границу виджета, и всё, что
/// просто нарисовано снаружи, пальцем не поймать.
class DayTimelineFrame extends StatelessWidget {
  const DayTimelineFrame({
    super.key,
    required this.start,
    required this.end,
    required this.showFlags,
    required this.showRange,
    required this.onDragStartEdge,
    required this.onDragEndEdge,
    required this.onRelease,
    required this.child,
    this.indent = 0,
  });

  final int start;
  final int end;
  final double indent;
  final bool showFlags;

  /// Показывать ли время подписью над рамкой.
  final bool showRange;
  final void Function(int anchor, double travelled) onDragStartEdge;
  final void Function(int anchor, double travelled) onDragEndEdge;
  final VoidCallback onRelease;
  final Widget child;

  static const _flagInset = 14.0;
  static const _rangeHeight = 22.0;

  @override
  Widget build(BuildContext context) {
    final top = dayTimelineOffsetOf(start);
    final bottom = dayTimelineOffsetOf(end);
    final above = math.min(DayTimelineHandle.reach, top);
    final below = math.min(
      DayTimelineHandle.reach,
      24 * dayTimelineHourHeight - bottom,
    );

    return Positioned(
      top: top - above,
      left: dayTimelineGutterWidth + indent,
      right: 8,
      height: bottom - top + above + below,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
              top: above, bottom: below, left: 0, right: 0, child: child),
          if (showRange)
            Positioned(
              top: math.max(0, above - _rangeHeight - 2),
              left: 4,
              child: IgnorePointer(
                child: DayTimelineRangeLabel(
                  text: formatDayTimelineRange(start, end),
                ),
              ),
            ),
          if (showFlags) ...[
            Positioned(
              top: 0,
              right: _flagInset,
              child: DayTimelineHandle(
                isTop: true,
                outside: above,
                minutes: start,
                onDrag: onDragStartEdge,
                onRelease: onRelease,
              ),
            ),
            Positioned(
              bottom: 0,
              right: _flagInset,
              child: DayTimelineHandle(
                isTop: false,
                outside: below,
                minutes: end,
                onDrag: onDragEndEdge,
                onRelease: onRelease,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
