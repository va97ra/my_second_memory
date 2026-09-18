import 'package:flutter/material.dart';

/// Кружок на краю выбранной таблички.
///
/// Копит смещение за весь жест и отдаёт его целиком: за один шаг палец
/// проходит два-три пикселя, а до следующей четверти часа их нужно
/// шестнадцать. По приростам поодиночке край не сдвинулся бы никогда.
class DayTimelineHandle extends StatefulWidget {
  const DayTimelineHandle(
      {super.key, required this.onGrab, required this.onDrag});

  final VoidCallback onGrab;
  final void Function(double travelled) onDrag;

  @override
  State<DayTimelineHandle> createState() => _DayTimelineHandleState();
}

class _DayTimelineHandleState extends State<DayTimelineHandle> {
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
