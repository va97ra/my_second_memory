import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/calendar_view.dart';
import 'calendar_screen.dart';

/// Листание календаря: стрелками и смахиванием, вбок и вверх-вниз, и кнопкой
/// «сегодня» на странице месяца.
///
/// Пока страница уезжает, [outgoingMonth] держит ту, что уходит; между
/// листаниями он `null`.
mixin CalendarPageTurning on ConsumerState<CalendarScreen>, TickerProvider {
  late final AnimationController pageTurn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  DateTime? outgoingMonth;
  Axis turnAxis = Axis.horizontal;

  /// `1` — следующая страница, `-1` — предыдущая.
  int turnDirection = 1;

  CalendarView get view;
  set view(CalendarView value);

  /// Идёт переход масштаба: листание его не перебивает.
  bool get isZooming;

  bool get isTurningPage => pageTurn.isAnimating;

  void disposePageTurn() => pageTurn.dispose();

  void changeMonth(int offset) => _turnTo(
        view.step(offset),
        axis: Axis.horizontal,
        direction: offset.sign,
      );

  void changeYear(int offset) => _turnTo(
        view.stepYear(offset),
        axis: Axis.vertical,
        direction: offset.sign,
      );

  void goToToday() {
    final target = view.zoomInto(DateTime.now());
    _turnTo(
      target,
      axis: Axis.horizontal,
      direction: target.month.isAfter(view.month) ? 1 : -1,
    );
  }

  void _turnTo(
    CalendarView target, {
    required Axis axis,
    required int direction,
  }) {
    if (pageTurn.isAnimating || isZooming || target == view) return;

    final outgoing = view.month;
    setState(() {
      outgoingMonth = outgoing;
      view = target;
      turnAxis = axis;
      turnDirection = direction;
    });

    pageTurn.forward(from: 0).whenComplete(() {
      if (!mounted || outgoingMonth != outgoing) return;
      setState(() => outgoingMonth = null);
      pageTurn.value = 0;
    });
  }
}
