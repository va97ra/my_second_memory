import 'package:flutter/material.dart';

import 'day_timeline_drag.dart';
import 'day_timeline_frame.dart';
import 'day_timeline_geometry.dart';

/// Новая рамка: живёт, пока её не открыли или не заменили другой.
class DayTimelineDraftFrame extends StatefulWidget {
  const DayTimelineDraftFrame({
    super.key,
    required this.start,
    required this.onCreate,
  });

  final int start;
  final void Function(int start, int end) onCreate;

  @override
  State<DayTimelineDraftFrame> createState() => _DayTimelineDraftFrameState();
}

class _DayTimelineDraftFrameState extends State<DayTimelineDraftFrame> {
  late int _start = widget.start;
  late int _end = widget.start + 60;

  void _carry(int anchor, double travelled) {
    final length = _end - _start;
    final moved = dayTimelineCarriedStart(anchor, travelled, length: length);
    setState(() {
      _start = moved;
      _end = moved + length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DayTimelineFrame(
      start: _start,
      end: _end,
      showFlags: true,
      showRange: true,
      onDragStartEdge: (anchor, travelled) => setState(
        () => _start = dayTimelineDraggedStart(anchor, travelled, end: _end),
      ),
      onDragEndEdge: (anchor, travelled) => setState(
        () => _end = dayTimelineDraggedEnd(anchor, travelled, start: _start),
      ),
      onRelease: () {},
      child: DayTimelineDrag(
        minutes: _start,
        onDrag: _carry,
        onRelease: () {},
        onTap: () => widget.onCreate(_start, _end),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.primary, width: 2),
          ),
        ),
      ),
    );
  }
}
