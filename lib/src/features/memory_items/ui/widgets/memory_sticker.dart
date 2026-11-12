import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../navigation/page_turn_navigation.dart';
import '../../state/memory_item_commands.dart';
import '../../state/memory_item_selectors.dart';
import 'memory_sticker_face.dart';
import 'memory_sticker_menu.dart';
import 'memory_sticker_strip.dart';
import 'sticker_carry.dart';
import 'sticker_edge_scroll.dart';

export 'memory_sticker_strip.dart' show StickerStamp;

/// Запись в виде квадратной карточки: в ленте и в записках одна и та же.
///
/// Получает идентификатор и читает запись сама. Нажатие открывает редактор,
/// квадратик в углу отмечает выполненной. Долгое нажатие приподнимает карточку:
/// отпустили на месте — меню, понесли — перенос на другой день или другое место
/// в дне.
class MemorySticker extends ConsumerStatefulWidget {
  const MemorySticker({
    super.key,
    required this.itemId,
    required this.stamp,
    this.openQuery = '',
    this.carry,
  });

  final String itemId;
  final StickerStamp stamp;

  /// Что дописать к адресу редактора: откуда открыли.
  final String openQuery;

  /// Куда сообщать, что карточку несут. Нет — нести нельзя: у записок дат нет,
  /// нести их некуда.
  final StickerCarry? carry;

  @override
  ConsumerState<MemorySticker> createState() => _MemoryStickerState();
}

class _MemoryStickerState extends ConsumerState<MemorySticker>
    with AutomaticKeepAliveClientMixin {
  final _edgeScroll = StickerEdgeScroll();
  Offset _liftedAt = Offset.zero;
  bool _carrying = false;

  /// Несомую карточку список не выгружает, даже когда она уехала за экран: без
  /// неё перенос оборвался бы, Draggable сообщает только смонтированному виджету.
  @override
  bool get wantKeepAlive => _carrying;

  void _setCarrying(bool value) {
    _carrying = value;
    updateKeepAlive();
  }

  @override
  void dispose() {
    _edgeScroll.stop();
    final carry = widget.carry;
    if (_carrying && carry != null) {
      // Запись исчезла, пока её несли. Пока дерево разбирается, сообщать нельзя.
      WidgetsBinding.instance.addPostFrameCallback((_) => carry.end());
    }
    super.dispose();
  }

  Future<void> _open(MemoryItem item) async {
    // Карточка успевает вернуться на место: переворот снимает страницу в картинку.
    await Future<void>.delayed(PressPulse.duration);
    if (!mounted) return;
    await context.pageTurnPush(
      '/memory/item/${Uri.encodeComponent(item.id)}${widget.openQuery}',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final item = ref.watch(memoryItemByIdProvider(widget.itemId));
    if (item == null) return const SizedBox.shrink();

    final sticker = MemoryStickerFace(
      key: ValueKey('memory_sticker_${item.id}'),
      item: item,
      stamp: widget.stamp,
      onOpen: () => _open(item),
      onToggleDone: () => toggleMemoryDone(ref, item),
    );
    final carry = widget.carry;
    if (carry == null) {
      return GestureDetector(
        onLongPress: () => showMemoryStickerMenu(context, ref, item),
        child: sticker,
      );
    }
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != item.id,
      onAcceptWithDetails: (details) {
        final moved = ref.read(memoryItemByIdProvider(details.data));
        if (moved != null) dropMemoryOn(ref, moved, item);
      },
      builder: (context, candidates, _) => AnimatedScale(
        scale: candidates.isEmpty ? 1 : 1.05,
        duration: const Duration(milliseconds: 120),
        child: LayoutBuilder(
          builder: (context, constraints) => _carried(
            item,
            sticker,
            constraints.biggest,
            carry,
          ),
        ),
      ),
    );
  }

  Widget _carried(
    MemoryItem item,
    Widget sticker,
    Size size,
    StickerCarry carry,
  ) {
    return LongPressDraggable<String>(
      data: item.id,
      delay: const Duration(milliseconds: 350),
      feedback: SizedBox.fromSize(
        size: size,
        // Над шкалой карточка бледнеет: за ней день, который выбирают.
        child: ValueListenableBuilder<bool>(
          valueListenable: carry.overRail,
          builder: (context, overRail, face) => AnimatedOpacity(
            opacity: overRail ? 0.3 : 1,
            duration: const Duration(milliseconds: 120),
            child: face,
          ),
          child: Transform.scale(
            scale: 1.06,
            child: Material(
              type: MaterialType.transparency,
              child:
                  MemoryStickerFace(item: item, stamp: widget.stamp, lifted: true),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: sticker),
      onDragStarted: () {
        final box = context.findRenderObject();
        if (box is RenderBox) _liftedAt = box.localToGlobal(Offset.zero);
        _setCarrying(true);
        carry.begin(item.memoryDate);
      },
      onDragUpdate: (details) {
        carry.move(details.globalPosition);
        if (carry.overRail.value) {
          _edgeScroll.stop();
        } else {
          _edgeScroll.update(context, details.globalPosition);
        }
      },
      onDragEnd: (details) {
        _edgeScroll.stop();
        _setCarrying(false);
        carry.end();
        if (!details.wasAccepted &&
            (details.offset - _liftedAt).distance < StickerCarry.slop &&
            mounted) {
          showMemoryStickerMenu(context, ref, item);
        }
      },
      child: sticker,
    );
  }
}
