import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Шкала едет сама, пока палец держат у её края: тем быстрее, чем ближе к краю и
/// чем дольше держат.
class FeedDayRailEdge {
  FeedDayRailEdge(TickerProvider vsync, this._onScroll) {
    _ticker = vsync.createTicker(_tick);
  }

  /// Край уже клетки: соседний день у верхнего ряда карточек должен успевать
  /// выбираться пальцем, а не уезжать.
  static const share = 0.75;

  /// На сколько дней шкала уехала за этот кадр.
  final ValueChanged<double> _onScroll;
  late final Ticker _ticker;
  double _depth = 0;
  bool _armed = false;
  Duration _last = Duration.zero;

  bool get isRunning => _ticker.isActive;

  /// Насколько палец зашёл в край: минус у верхнего, плюс у нижнего, ноль вне их.
  static double depthAt(double y, double height, double cell) {
    final zone = cell * share;
    if (y < zone) return -(zone - y) / zone;
    final bottom = height - zone;
    return y > bottom ? (y - bottom) / zone : 0;
  }

  /// Новая запись: край молчит, пока палец на шкале не побывает вне него. Иначе
  /// запись, поднятая у края, сразу погнала бы шкалу.
  void reset() {
    _armed = false;
    stop();
  }

  void update({required bool over, required double depth}) {
    if (over && depth == 0) _armed = true;
    _depth = over && _armed ? depth : 0;
    if (_depth != 0 && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (_depth == 0) {
      stop();
    }
  }

  void stop() {
    if (_ticker.isActive) _ticker.stop();
  }

  void dispose() => _ticker.dispose();

  void _tick(Duration elapsed) {
    final seconds = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final ramp = 1 + math.min(elapsed.inMilliseconds / 1000, 3);
    _onScroll(_depth.sign * (3 + 9 * _depth.abs()) * ramp * seconds);
  }
}
