import 'package:flutter/material.dart';
import 'day_timeline_handle.dart';

class DayTimelineHandles extends StatelessWidget {
  const DayTimelineHandles(
      {super.key,
      required this.onGrabStart,
      required this.onGrabEnd,
      required this.onDragStart,
      required this.onDragEnd});
  final VoidCallback onGrabStart;
  final VoidCallback onGrabEnd;
  final ValueChanged<double> onDragStart;
  final ValueChanged<double> onDragEnd;
  @override
  Widget build(BuildContext context) =>
      Stack(clipBehavior: Clip.none, children: [
        Positioned(
            top: -7,
            left: 6,
            child: DayTimelineHandle(onGrab: onGrabStart, onDrag: onDragStart)),
        Positioned(
            bottom: -7,
            right: 6,
            child: DayTimelineHandle(onGrab: onGrabEnd, onDrag: onDragEnd)),
      ]);
}
