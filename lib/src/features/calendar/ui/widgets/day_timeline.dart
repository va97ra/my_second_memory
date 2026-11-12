import 'dart:math' as math;

import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../memory_items/memory_items.dart';
import 'day_timeline_geometry.dart';

import 'day_timeline_draft_frame.dart';
import 'day_timeline_entry.dart';
import 'day_timeline_hour_rules.dart';

/// Scrollable day scale. Draft and record gestures belong to their widgets.
class DayTimeline extends ConsumerStatefulWidget {
  const DayTimeline({super.key, required this.items, required this.onCreate});
  final List<MemoryItem> items;
  final void Function(int startMinutes, int endMinutes) onCreate;
  @override
  ConsumerState<DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends ConsumerState<DayTimeline> {
  late final ScrollController _scroll =
      ScrollController(initialScrollOffset: _startOffset());
  int? _draftStart;
  Key? _draftKey;
  String? _selectedId;
  double _startOffset() {
    final blocks = layOutDayTimeline(widget.items);
    final first = blocks.isEmpty ? 8 * 60 : blocks.first.start;
    return math.max(0, dayTimelineOffsetOf(first) - dayTimelineHourHeight);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = layOutDayTimeline(widget.items);
    // Выбранная запись лежит поверх остальных: иначе наехавшая соседка закрыла
    // бы и её саму, и флажки.
    final stacked = [
      for (final block in blocks)
        if (block.item.id != _selectedId) block,
      for (final block in blocks)
        if (block.item.id == _selectedId) block,
    ];

    return NotebookPaperFill(
      child: SingleChildScrollView(
        controller: _scroll,
        child: SizedBox(
          height: 24 * dayTimelineHourHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: HourRulesPainter(context)),
              ),
              Positioned.fill(
                  child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTapUp: (details) => setState(() {
                  _selectedId = null;
                  _draftStart = dayTimelineMinutesAt(details.localPosition.dy)
                      .clamp(0, 23 * 60);
                  _draftKey = UniqueKey();
                }),
              )),
              for (final block in stacked)
                DayTimelineEntry(
                  key: ValueKey(block.item.id),
                  block: block,
                  selected: block.item.id == _selectedId,
                  onSelect: () => setState(() {
                    _selectedId = block.item.id;
                    _draftStart = null;
                  }),
                  onOpen: () => context.pageTurnPush(
                      '/memory/item/${Uri.encodeComponent(block.item.id)}'),
                  onSave: (item) => ref
                      .read(memoryItemsControllerProvider.notifier)
                      .update(item),
                ),
              if (_draftStart != null)
                DayTimelineDraftFrame(
                  key: _draftKey,
                  start: _draftStart!,
                  onCreate: (start, end) {
                    setState(() => _draftStart = null);
                    widget.onCreate(start, end);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
