import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../memory_items/memory_items.dart';
import 'day_timeline_geometry.dart';

/// Шкала дня: сутки по вертикали, дела — табличками от начала до конца.
///
/// Нажатие на пустое место ставит рамку в час длиной. У неё две ручки —
/// ими задают, с какого и по какое время идёт дело. Нажатие на саму рамку
/// открывает редактор с готовым отрезком.
///
/// У существующей таблички нажатие открывает запись, а долгое — даёт те же
/// ручки, чтобы растянуть её прямо на шкале.
class DayTimeline extends ConsumerStatefulWidget {
  const DayTimeline({
    super.key,
    required this.items,
    required this.onCreate,
  });

  final List<MemoryItem> items;

  /// Открыть редактор новой записи на выбранном отрезке.
  final void Function(int startMinutes, int endMinutes) onCreate;

  @override
  ConsumerState<DayTimeline> createState() => _DayTimelineState();
}

class _DayTimelineState extends ConsumerState<DayTimeline> {
  final ScrollController _scroll = ScrollController();

  /// Рамка, поставленная нажатием. Держится на шкале, пока её не откроют
  /// в редакторе или не поставят другую.
  int? _draftStart;
  int? _draftEnd;

  /// Табличка с показанными ручками. Выбор снимается нажатием мимо.
  String? _selectedId;

  bool _scrolledToStart = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blocks = layOutDayTimeline(widget.items);
    _scrollToFirstBlockOnce(blocks);

    return SingleChildScrollView(
      controller: _scroll,
      child: SizedBox(
        height: 24 * dayTimelineHourHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: HourRulesPainter(context)),
            ),
            Positioned.fill(child: _gestureLayer()),
            for (final block in blocks) _block(block),
            if (_draftStart != null) _draftFrame(),
          ],
        ),
      ),
    );
  }

  /// Шкала открывается на первом деле дня, а не на полуночи.
  void _scrollToFirstBlockOnce(List<DayTimelineBlock> blocks) {
    if (_scrolledToStart) return;
    _scrolledToStart = true;
    final first = blocks.isEmpty ? 8 * 60 : blocks.first.start;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = dayTimelineOffsetOf(first) - dayTimelineHourHeight;
      _scroll.jumpTo(target.clamp(0, _scroll.position.maxScrollExtent));
    });
  }

  Widget _gestureLayer() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) => _putDraftAt(details.localPosition.dy),
    );
  }

  /// Нажали по пустому месту — там встаёт рамка длиной в час.
  ///
  /// Час, а не четверть: рамку ставят, чтобы её потом растянуть, и слишком
  /// низкая полоска не даёт ухватиться ни за одну ручку.
  void _putDraftAt(double offset) {
    // У полуночи рамке некуда расти вниз, поэтому она отступает вверх.
    final start = dayTimelineMinutesAt(offset).clamp(0, 23 * 60);
    setState(() {
      _selectedId = null;
      _draftStart = start;
      _draftEnd = start + 60;
    });
  }

  Widget _draftFrame() {
    final colors = Theme.of(context).colorScheme;
    final start = _draftStart!;
    final end = _draftEnd!;
    return Positioned(
      top: dayTimelineOffsetOf(start),
      left: dayTimelineGutterWidth,
      right: 8,
      height: dayTimelineOffsetOf(end) - dayTimelineOffsetOf(start),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _draftStart = null;
            _draftEnd = null;
          });
          widget.onCreate(start, end);
        },
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
            Positioned(
              top: -7,
              left: 6,
              child: _Handle(
                onGrab: () => _grabbed = start,
                onDrag: _dragDraftStart,
              ),
            ),
            Positioned(
              bottom: -7,
              right: 6,
              child: _Handle(
                onGrab: () => _grabbed = end,
                onDrag: _dragDraftEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Время края в момент захвата ручки. От него считается всё перетаскивание.
  int? _grabbed;

  /// Верхняя ручка рамки: начало едет, конец стоит.
  void _dragDraftStart(double travelled) {
    final anchor = _grabbed;
    final end = _draftEnd;
    if (anchor == null || end == null) return;
    final moved = dayTimelineMinutesAt(dayTimelineOffsetOf(anchor) + travelled);
    if (moved >= end) return;
    setState(() => _draftStart = moved);
  }

  /// Нижняя ручка рамки: конец едет, начало стоит.
  void _dragDraftEnd(double travelled) {
    final anchor = _grabbed;
    final start = _draftStart;
    if (anchor == null || start == null) return;
    final moved = dayTimelineMinutesAt(dayTimelineOffsetOf(anchor) + travelled);
    if (moved <= start) return;
    setState(() => _draftEnd = moved);
  }

  Widget _block(DayTimelineBlock block) {
    final colors = Theme.of(context).colorScheme;
    final selected = block.item.id == _selectedId;
    final short = block.height < dayTimelineHourHeight / 2;

    return Positioned(
      top: block.top,
      left: dayTimelineGutterWidth + block.indent,
      right: 8,
      height: block.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.pageTurnPush(
          '/memory/item/${Uri.encodeComponent(block.item.id)}',
        ),
        onLongPress: () => setState(() => _selectedId = block.item.id),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? colors.primary : colors.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: notebookSurfaceShadow(
                    context,
                    NotebookSurfaceDepth.card,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, short ? 1 : 5, 8, 2),
                  child: Text(
                    block.item.title,
                    maxLines: short ? 1 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurface,
                      // На четверти часа подпись живёт одной мелкой строкой.
                      fontSize: short ? 11 : 13,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
            if (selected) ..._handles(block),
          ],
        ),
      ),
    );
  }

  List<Widget> _handles(DayTimelineBlock block) {
    return [
      Positioned(
        top: -7,
        left: 6,
        child: _Handle(
          onGrab: () => _grabbed = block.start,
          onDrag: (travelled) => _moveStart(block, travelled),
        ),
      ),
      Positioned(
        bottom: -7,
        right: 6,
        child: _Handle(
          onGrab: () => _grabbed = block.end,
          onDrag: (travelled) => _moveEnd(block, travelled),
        ),
      ),
    ];
  }

  /// Верхняя ручка: начало едет по шкале, конец стоит на месте.
  void _moveStart(DayTimelineBlock block, double travelled) {
    final anchor = _grabbed;
    if (anchor == null) return;
    final moved = dayTimelineMinutesAt(dayTimelineOffsetOf(anchor) + travelled);
    if (moved >= block.end || moved == block.start) return;
    _save(block.item.copyWith(timeMinutes: moved, endMinutes: block.end));
  }

  /// Нижняя ручка: конец едет, начало стоит.
  void _moveEnd(DayTimelineBlock block, double travelled) {
    final anchor = _grabbed;
    if (anchor == null) return;
    final moved = dayTimelineMinutesAt(dayTimelineOffsetOf(anchor) + travelled);
    if (moved <= block.start || moved == block.end) return;
    _save(block.item.copyWith(endMinutes: moved));
  }

  void _save(MemoryItem item) {
    ref.read(memoryItemsControllerProvider.notifier).update(item);
  }
}

/// Кружок на краю выбранной таблички.
///
/// Копит смещение за весь жест и отдаёт его целиком: за один шаг палец
/// проходит два-три пикселя, а до следующей четверти часа их нужно
/// шестнадцать. По приростам поодиночке край не сдвинулся бы никогда.
class _Handle extends StatefulWidget {
  const _Handle({required this.onGrab, required this.onDrag});

  final VoidCallback onGrab;
  final void Function(double travelled) onDrag;

  @override
  State<_Handle> createState() => _HandleState();
}

class _HandleState extends State<_Handle> {
  double _travelled = 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) {
        _travelled = 0;
        widget.onGrab();
      },
      onVerticalDragUpdate: (details) {
        _travelled += details.delta.dy;
        widget.onDrag(_travelled);
      },
      // Кружок мелкий, а палец нет: прозрачное поле вокруг ловит промах.
      child: SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: colors.surface, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Часы слева и линии, по которым читается время.
class HourRulesPainter extends CustomPainter {
  HourRulesPainter(BuildContext context)
      : _line = Theme.of(context).colorScheme.outlineVariant,
        _text = Theme.of(context).colorScheme.onSurfaceVariant;

  final Color _line;
  final Color _text;

  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()
      ..color = _line
      ..strokeWidth = 1;

    for (var hour = 0; hour <= 24; hour++) {
      final y = hour * dayTimelineHourHeight;
      canvas.drawLine(
        Offset(dayTimelineGutterWidth, y),
        Offset(size.width, y),
        rule,
      );
      if (hour == 24) break;
      final label = TextPainter(
        text: TextSpan(
          text: formatDayTimelineHour(hour),
          style: TextStyle(color: _text, fontSize: 11, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(8, y + 3));
    }
  }

  @override
  bool shouldRepaint(HourRulesPainter oldDelegate) =>
      oldDelegate._line != _line || oldDelegate._text != _text;
}
