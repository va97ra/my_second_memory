import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../../../shared/ui/memory_card/memory_card_attachment_icons.dart';
import '../../../../shared/ui/memory_card/memory_card_image_thumbnail.dart';
import '../../../../shared/ui/memory_card/memory_card_ruled_background.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';
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

  /// Табличка, которую сейчас несут пальцем, и её новое начало.
  ///
  /// Длительность при переносе не меняется: двигают дело целиком, а не его
  /// край. Пока палец в пути, положение живёт здесь и в запись не пишется.
  String? _movingId;
  int? _movedStart;

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

  /// Табличка едет за пальцем целиком, упираясь в границы суток.
  void _carry(DayTimelineBlock block, double travelled) {
    if (_movingId != block.item.id) return;
    final length = block.end - block.start;
    final moved = dayTimelineMinutesAt(block.top + travelled)
        .clamp(0, 24 * 60 - length);
    if (moved == _movedStart) return;
    setState(() => _movedStart = moved);
  }

  /// Палец отпустили — новое время записывается один раз, а не по дороге.
  void _dropCarried(DayTimelineBlock block) {
    final moved = _movedStart;
    setState(() {
      _movingId = null;
      _movedStart = null;
    });
    if (moved == null || moved == block.start) return;
    final length = block.end - block.start;
    _save(
      block.item.copyWith(timeMinutes: moved, endMinutes: moved + length),
    );
  }

  Widget _block(DayTimelineBlock block) {
    final selected = block.item.id == _selectedId;
    final short = block.height < dayTimelineHourHeight / 2;
    final carried = block.item.id == _movingId ? _movedStart : null;
    final top = carried == null
        ? block.top
        : dayTimelineOffsetOf(carried);

    return Positioned(
      top: top,
      left: dayTimelineGutterWidth + block.indent,
      right: 8,
      height: block.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.pageTurnPush(
          '/memory/item/${Uri.encodeComponent(block.item.id)}',
        ),
        // Долгое нажатие выбирает табличку, а если палец пошёл — несёт её.
        onLongPressStart: (_) => setState(() {
          _selectedId = block.item.id;
          _movingId = block.item.id;
          _movedStart = block.start;
        }),
        onLongPressMoveUpdate: (details) =>
            _carry(block, details.localOffsetFromOrigin.dy),
        onLongPressEnd: (_) => _dropCarried(block),
        onLongPressCancel: () => setState(() {
          _movingId = null;
          _movedStart = null;
        }),
        // Табличка — отдельный листок и на тёмном блокноте остаётся светлой,
        // как карточки в ленте. Тёмная на тёмной шкале читалась мрачно.
        child: NotebookPaperIsland(
          child: Builder(
            builder: (context) {
              final colors = Theme.of(context).colorScheme;
              return Stack(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: _blockBody(context, block, short: short),
                ),
              ),
            ),
            if (selected) ..._handles(block),
          ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Нутро таблички: цветной корешок вида и содержимое записи.
  ///
  /// [context] обязательно из-под островка бумаги: иначе тема возьмётся
  /// тёмная, и по светлой табличке пойдёт светлый текст.
  Widget _blockBody(
    BuildContext context,
    DayTimelineBlock block, {
    required bool short,
  }) {
    final colors = Theme.of(context).colorScheme;
    final item = block.item;
    final notebook = NotebookVisuals.maybeOf(context);
    // Рваный край откусывает часть корешка, поэтому ширину ему добавляют.
    final tearInset = notebook == null ? 0.0 : TornPaperShapeBorder.tearDepth;
    // Миниатюра просит высоты: на четверти часа ей не поместиться, там
    // о фотографии говорит значок.
    final tall = block.height >= 2 * dayTimelineHourHeight / 3;
    final hasImages = item.imagePaths.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NotebookLeatherSurface(
          color: memoryTypeColor(item.type),
          child: SizedBox(width: 10 + tearInset),
        ),
        Expanded(
          child: MemoryCardRuledBackground(
            lineHeight: short ? 12 : 16,
            child: Padding(
            padding: EdgeInsets.fromLTRB(7, short ? 1 : 5, 7, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tall && hasImages) ...[
                  SizedBox(
                    height: 44,
                    child: MemoryCardImageThumbnail(
                      paths: item.imagePaths,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    item.title,
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
                if (!(tall && hasImages) ||
                    item.audioPath != null ||
                    item.remindAt != null) ...[
                  const SizedBox(width: 4),
                  MemoryCardAttachmentIcons(
                    imageCount: tall && hasImages ? 0 : item.imagePaths.length,
                    hasAudio: item.audioPath != null,
                    hasReminder: item.remindAt != null,
                  ),
                ],
              ],
            ),
            ),
          ),
        ),
      ],
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
      // Точка ловит и удержание: иначе задержавшийся на ней палец отдаёт жест
      // табличке, и та уезжает целиком вместо того, чтобы растянуться.
      onLongPressStart: (_) => widget.onGrab(),
      onLongPressMoveUpdate: (details) =>
          widget.onDrag(details.localOffsetFromOrigin.dy),
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
