import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../calendar/calendar.dart' show calendarTodayColor;
import '../../../memory_items/memory_items.dart';
import '../feed_labels.dart';
import 'feed_day_rail_bubble.dart';
import 'feed_day_rail_edge.dart';
import 'feed_day_rail_strip.dart';
import 'feed_day_scale.dart';

/// Шкала дней у правого края. Появляется, только пока карточку несут: на неё можно
/// бросить запись на любой день, даже если в ленте такого дня нет.
class FeedDayRail extends ConsumerStatefulWidget {
  const FeedDayRail({super.key, required this.carry});

  final StickerCarry carry;

  @override
  ConsumerState<FeedDayRail> createState() => _FeedDayRailState();
}

class _FeedDayRailState extends ConsumerState<FeedDayRail>
    with SingleTickerProviderStateMixin {
  static const _width = 56.0;
  static const _cell = 36.0;
  static const _bubbleHeight = 40.0;

  late final FeedDayRailEdge _edge;
  FeedDayScale? _scale;
  bool _shown = false;
  bool _over = false;
  double _y = 0;
  double _height = 0;
  int _index = 0;

  double get _railWidth => MediaQuery.textScalerOf(context).scale(_width);

  @override
  void initState() {
    super.initState();
    _edge = FeedDayRailEdge(this, _scrollBy);
    widget.carry.pointer.addListener(_onPointer);
  }

  @override
  void dispose() {
    widget.carry.pointer.removeListener(_onPointer);
    _edge.dispose();
    super.dispose();
  }

  void _onPointer() {
    final pointer = widget.carry.pointer.value;
    final box = context.findRenderObject();
    if (pointer == null || box is! RenderBox) return _hide();
    if (!_shown) _scale = _newScale(box);
    final scale = _scale!;
    final local = box.globalToLocal(pointer);
    final over = local.dx >= box.size.width - _railWidth &&
        local.dy >= 0 &&
        local.dy <= box.size.height;
    final repaint = !_shown || over || over != _over;
    widget.carry.overRail.value = over;
    _y = local.dy;
    _height = box.size.height;
    _edge.update(
      over: over,
      depth: FeedDayRailEdge.depthAt(_y, _height, scale.cellExtent),
    );
    final index = scale.indexAt(_y);
    if (over && index != _index && !_edge.isRunning) {
      HapticFeedback.selectionClick();
    }
    _index = index;
    if (repaint) {
      setState(() {
        _shown = true;
        _over = over;
      });
    }
  }

  FeedDayScale _newScale(RenderBox box) {
    final cell = MediaQuery.textScalerOf(context).scale(_cell);
    final low = cell * (FeedDayRailEdge.share + 0.5);
    final high = math.max(low, box.size.height - low);
    _edge.reset();
    return FeedDayScale(
      ownDay: widget.carry.day!,
      // Свой день не ставим в край: там он уезжал бы из-под пальца.
      ownY: box.globalToLocal(widget.carry.liftedAt!).dy.clamp(low, high),
      cellExtent: cell,
    );
  }

  void _hide() {
    _edge.stop();
    if (_shown) {
      setState(() {
        _shown = false;
        _over = false;
      });
    }
  }

  void _scrollBy(double days) {
    final scale = _scale!;
    setState(() {
      scale.shift += days * scale.cellExtent;
      _index = scale.indexAt(_y);
    });
  }

  void _drop(DragTargetDetails<String> details) {
    final item = ref.read(memoryItemByIdProvider(details.data));
    final scale = _scale;
    if (item != null && scale != null) {
      moveMemoryToDay(ref, item, scale.dayOf(_index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale;
    if (scale == null) return const SizedBox.shrink();
    final width = _railWidth;
    final todayColor = calendarTodayColor(context);

    return Stack(
      children: [
        Positioned(
          key: const ValueKey('feed_day_rail'),
          top: 0,
          bottom: 0,
          right: 0,
          width: width,
          child: _Appearing(
            shown: _shown,
            child: DragTarget<String>(
              onAcceptWithDetails: _drop,
              builder: (context, candidates, _) => FeedDayRailStrip(
                scale: scale,
                activeIndex: _over ? _index : null,
                todayColor: todayColor,
              ),
            ),
          ),
        ),
        if (_over)
          Positioned(
            left: 8,
            right: width + 8,
            top: (_y - _bubbleHeight / 2)
                .clamp(0.0, math.max(0.0, _height - _bubbleHeight)),
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.centerRight,
                child: FeedDayRailBubble(
                  label: feedFullDayLabel(context, scale.dayOf(_index)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Шкала выезжает, когда карточку понесли, и не ловит палец, пока её нет.
class _Appearing extends StatelessWidget {
  const _Appearing({required this.shown, required this.child});

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
