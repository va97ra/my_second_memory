import 'package:flutter/material.dart';
import 'day_timeline_geometry.dart';
import 'day_timeline_handles.dart';

/// An unsaved range owns its drag state until it is opened or replaced.
class DayTimelineDraftFrame extends StatefulWidget {
  const DayTimelineDraftFrame(
      {super.key, required this.start, required this.onCreate});
  final int start;
  final void Function(int start, int end) onCreate;
  @override
  State<DayTimelineDraftFrame> createState() => _DayTimelineDraftFrameState();
}

class _DayTimelineDraftFrameState extends State<DayTimelineDraftFrame> {
  late int _start = widget.start;
  late int _end = widget.start + 60;
  int? _grabbed;
  void _dragStart(double travelled) {
    final anchor = _grabbed;
    if (anchor == null) return;
    final moved = dayTimelineMinutesAt(dayTimelineOffsetOf(anchor) + travelled);
    if (moved < _end) setState(() => _start = moved);
  }

  void _dragEnd(double travelled) {
    final anchor = _grabbed;
    if (anchor == null) return;
    final moved = dayTimelineMinutesAt(dayTimelineOffsetOf(anchor) + travelled);
    if (moved > _start) setState(() => _end = moved);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final start = _start;
    final end = _end;
    return Positioned(
      top: dayTimelineOffsetOf(start),
      left: dayTimelineGutterWidth,
      right: 8,
      height: dayTimelineOffsetOf(end) - dayTimelineOffsetOf(start),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onCreate(start, end),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.primary, width: 2),
                ),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    // Слева на этой же высоте сидит верхняя точка: подпись
                    // начинается за ней, иначе цифры оказываются под кружком.
                    padding: const EdgeInsets.fromLTRB(38, 4, 8, 0),
                    child: Text(
                      formatDayTimelineRange(start, end),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
                child: DayTimelineHandles(
              onGrabStart: () => _grabbed = start,
              onGrabEnd: () => _grabbed = end,
              onDragStart: _dragStart,
              onDragEnd: _dragEnd,
            )),
          ],
        ),
      ),
    );
  }
}
