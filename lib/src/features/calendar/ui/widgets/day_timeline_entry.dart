import 'package:flutter/material.dart';
import 'package:ez_domain/ez_domain.dart';
import 'day_timeline_geometry.dart';
import 'day_timeline_card.dart';
import 'day_timeline_handles.dart';

/// Owns the drag preview for one existing record; moving commits on release.
class DayTimelineEntry extends StatefulWidget {
  const DayTimelineEntry(
      {super.key,
      required this.block,
      required this.selected,
      required this.onSelect,
      required this.onOpen,
      required this.onSave});
  final DayTimelineBlock block;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpen;
  final ValueChanged<MemoryItem> onSave;
  @override
  State<DayTimelineEntry> createState() => _DayTimelineEntryState();
}

class _DayTimelineEntryState extends State<DayTimelineEntry> {
  int? _movedStart;
  int? _grabbed;

  void _carry(double travelled) {
    if (_movedStart == null) return;
    final block = widget.block;
    final length = block.end - block.start;
    final moved =
        dayTimelineMinutesAt(block.top + travelled).clamp(0, 24 * 60 - length);
    if (moved != _movedStart) setState(() => _movedStart = moved);
  }

  void _drop() {
    final moved = _movedStart;
    setState(() => _movedStart = null);
    final block = widget.block;
    if (moved == null || moved == block.start) return;
    widget.onSave(block.item.copyWith(
        timeMinutes: moved, endMinutes: moved + block.end - block.start));
  }

  void _moveStart(double travelled) {
    final anchor = _grabbed;
    if (anchor == null) return;
    final block = widget.block;
    final moved = dayTimelineMinutesAt(dayTimelineOffsetOf(anchor) + travelled);
    if (moved >= block.end || moved == block.start) return;
    widget
        .onSave(block.item.copyWith(timeMinutes: moved, endMinutes: block.end));
  }

  void _moveEnd(double travelled) {
    final anchor = _grabbed;
    if (anchor == null) return;
    final block = widget.block;
    final moved = dayTimelineMinutesAt(dayTimelineOffsetOf(anchor) + travelled);
    if (moved <= block.start || moved == block.end) return;
    widget.onSave(block.item.copyWith(endMinutes: moved));
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    return Positioned(
      top: _movedStart == null ? block.top : dayTimelineOffsetOf(_movedStart!),
      left: dayTimelineGutterWidth + block.indent,
      right: 8,
      height: block.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        onLongPressStart: (_) {
          widget.onSelect();
          setState(() => _movedStart = block.start);
        },
        onLongPressMoveUpdate: (details) =>
            _carry(details.localOffsetFromOrigin.dy),
        onLongPressEnd: (_) => _drop(),
        onLongPressCancel: () => setState(() => _movedStart = null),
        child: DayTimelineCard(
            block: block,
            selected: widget.selected,
            handles: DayTimelineHandles(
              onGrabStart: () => _grabbed = block.start,
              onGrabEnd: () => _grabbed = block.end,
              onDragStart: _moveStart,
              onDragEnd: _moveEnd,
            )),
      ),
    );
  }
}
