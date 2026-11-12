import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'day_timeline_drag.dart';

/// Флажок на краю рамки: торчит наружу, поэтому у самой узкой рамки верхний и
/// нижний не лезут друг на друга и за них есть за что взяться.
class DayTimelineHandle extends StatelessWidget {
  const DayTimelineHandle({
    super.key,
    required this.isTop,
    required this.outside,
    required this.minutes,
    required this.onDrag,
    required this.onRelease,
  });

  /// Поле, которое ловит палец: заметно шире и выше самого флажка.
  static const touchWidth = 84.0;

  /// Сколько поля лежит снаружи рамки, если место есть.
  static const reach = 34.0;
  static const _inside = 10.0;
  static const _flagWidth = 56.0;
  static const _flagHeight = 22.0;

  final bool isTop;

  /// Сколько места снаружи рамки: у края суток его нет, и флажок заходит внутрь.
  final double outside;
  final int minutes;
  final void Function(int anchor, double travelled) onDrag;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final height = (outside < _flagHeight ? _flagHeight : outside) + _inside;
    const corner = Radius.circular(8);

    return DayTimelineDrag(
      minutes: minutes,
      onDrag: onDrag,
      onRelease: onRelease,
      child: SizedBox(
        width: touchWidth,
        height: height,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: isTop ? _inside : 0,
            top: isTop ? 0 : _inside,
          ),
          child: Align(
            alignment: isTop ? Alignment.bottomCenter : Alignment.topCenter,
            child: Container(
              width: _flagWidth,
              height: _flagHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.vertical(
                  top: isTop ? corner : Radius.zero,
                  bottom: isTop ? Radius.zero : corner,
                ),
              ),
              child: Icon(
                Icons.drag_handle_rounded,
                size: 18,
                color: readableInkOn(color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
