import 'package:flutter/material.dart';

/// Жест, которым на шкале тянут что угодно: край рамки или её целиком.
///
/// Запоминает, откуда взяли, и копит смещение за весь жест: за один шаг палец
/// проходит два-три пикселя, по приростам поодиночке точного времени не собрать.
class DayTimelineDrag extends StatefulWidget {
  const DayTimelineDrag({
    super.key,
    required this.minutes,
    required this.onDrag,
    required this.onRelease,
    required this.child,
    this.immediate = true,
    this.onTap,
    this.onLift,
    this.onCancel,
  });

  /// Время, которое берут: начало рамки или её край.
  final int minutes;
  final void Function(int anchor, double travelled) onDrag;
  final VoidCallback onRelease;
  final Widget child;

  /// Тянется ли сразу. Нет — только с удержания, иначе палец не сможет листать
  /// шкалу, начав с записи.
  final bool immediate;
  final VoidCallback? onTap;

  /// Вещь взяли удержанием.
  final VoidCallback? onLift;
  final VoidCallback? onCancel;

  @override
  State<DayTimelineDrag> createState() => _DayTimelineDragState();
}

class _DayTimelineDragState extends State<DayTimelineDrag> {
  int _anchor = 0;
  double _travelled = 0;

  void _grab() {
    _anchor = widget.minutes;
    _travelled = 0;
  }

  void _move(double travelled) {
    _travelled = travelled;
    widget.onDrag(_anchor, _travelled);
  }

  @override
  Widget build(BuildContext context) {
    final immediate = widget.immediate;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onVerticalDragStart: immediate ? (_) => _grab() : null,
      onVerticalDragUpdate:
          immediate ? (details) => _move(_travelled + details.delta.dy) : null,
      onVerticalDragEnd: immediate ? (_) => widget.onRelease() : null,
      onVerticalDragCancel: immediate ? widget.onCancel : null,
      // Удержание ловят и сразу тянущиеся вещи: иначе задержавшийся палец
      // отдаёт жест тому, что лежит под ними.
      onLongPressStart: (_) {
        _grab();
        widget.onLift?.call();
      },
      onLongPressMoveUpdate: (details) =>
          _move(details.localOffsetFromOrigin.dy),
      onLongPressEnd: (_) => widget.onRelease(),
      onLongPressCancel: widget.onCancel,
      child: widget.child,
    );
  }
}
