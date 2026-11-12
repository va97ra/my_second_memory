import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'day_timeline_card.dart';
import 'day_timeline_drag.dart';
import 'day_timeline_frame.dart';
import 'day_timeline_geometry.dart';

/// Запись на шкале. Пока её тянут, двигается только картинка: в хранилище она
/// попадает один раз, когда палец отпустили, а не на каждую минуту по дороге.
class DayTimelineEntry extends StatefulWidget {
  const DayTimelineEntry({
    super.key,
    required this.block,
    required this.selected,
    required this.onSelect,
    required this.onOpen,
    required this.onSave,
  });

  final DayTimelineBlock block;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpen;
  final ValueChanged<MemoryItem> onSave;

  @override
  State<DayTimelineEntry> createState() => _DayTimelineEntryState();
}

class _DayTimelineEntryState extends State<DayTimelineEntry> {
  DayTimelineBlock? _preview;

  DayTimelineBlock get _shown => _preview ?? widget.block;

  void _show(int start, int end) => setState(
        () => _preview = widget.block.movedTo(start, end),
      );

  void _carry(int anchor, double travelled) {
    final length = _shown.end - _shown.start;
    final moved = dayTimelineCarriedStart(anchor, travelled, length: length);
    _show(moved, moved + length);
  }

  void _commit() {
    final shown = _preview;
    final block = widget.block;
    if (shown != null &&
        (shown.start != block.start || shown.end != block.end)) {
      widget.onSave(
        block.item.copyWith(timeMinutes: shown.start, endMinutes: shown.end),
      );
    }
    setState(() => _preview = null);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    return DayTimelineFrame(
      start: shown.start,
      end: shown.end,
      indent: widget.block.indent,
      showFlags: widget.selected,
      showRange: _preview != null,
      onDragStartEdge: (anchor, travelled) => _show(
        dayTimelineDraggedStart(anchor, travelled, end: shown.end),
        shown.end,
      ),
      onDragEndEdge: (anchor, travelled) => _show(
        shown.start,
        dayTimelineDraggedEnd(anchor, travelled, start: shown.start),
      ),
      onRelease: _commit,
      child: DayTimelineDrag(
        minutes: shown.start,
        // Выбранную запись тянут сразу, остальные — с удержания: иначе с них
        // нельзя было бы начать листать шкалу.
        immediate: widget.selected,
        onDrag: _carry,
        onRelease: _commit,
        // Первое нажатие поднимает запись наверх и даёт флажки, второе открывает.
        onTap: widget.selected ? widget.onOpen : widget.onSelect,
        onLift: widget.onSelect,
        onCancel: () => setState(() => _preview = null),
        child: DayTimelineCard(block: shown, selected: widget.selected),
      ),
    );
  }
}
