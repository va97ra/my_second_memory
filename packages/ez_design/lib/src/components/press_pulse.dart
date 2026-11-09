import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Отклик на палец: вещь мягко сжимается и отпускается. Один на всё приложение.
///
/// Короткое нажатие проигрывается целиком: иначе от быстрого тапа отклика бы не
/// осталось. Сжатие зависит от размера: маленькая кнопка уходит заметно, а широкая
/// на те же несколько пикселей, а не на треть экрана.
class PressPulse extends StatefulWidget {
  const PressPulse({super.key, required this.child, this.pressed});

  /// Сколько длится короткое нажатие: сжатие и возврат.
  static const duration = Duration(milliseconds: 180);

  /// Нажатие, о котором сообщают снаружи: так кнопки Material знают его сами.
  /// Null — виджет слушает палец сам.
  final bool? pressed;
  final Widget child;

  @override
  State<PressPulse> createState() => _PressPulseState();
}

class _PressPulseState extends State<PressPulse>
    with SingleTickerProviderStateMixin {
  static const _maxDepth = 0.06;
  static const _pixels = 10.0;

  /// Палец ушёл дальше этого — значит, листают, а не нажимают.
  static const _swipeSlop = 18.0;

  /// Столько палец лежит, прежде чем вещь начнёт сжиматься: за это время видно,
  /// листают её или нажимают. Тап не теряется, отпускание проигрывает сжатие само.
  static const _holdOff = Duration(milliseconds: 40);

  /// Касание, которое уже досталось какой-то вещи. О пальце сообщают от самой
  /// глубокой вещи к внешней, поэтому кнопка на листе забирает нажатие себе, а
  /// лист под ней стоит.
  static int? _claimedPointer;

  /// Касание, за которым следит эта вещь. Снято — значит, листают, и отпускание
  /// пальца к ней уже не относится.
  int? _pointer;
  Timer? _holdOffTimer;

  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: PressPulse.duration * 0.5,
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _press, curve: Curves.easeOutCubic);

  double _depth = _maxDepth;
  bool _held = false;
  Offset _downAt = Offset.zero;

  @override
  void didUpdateWidget(PressPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pressed = widget.pressed;
    if (pressed == null || pressed == oldWidget.pressed) return;
    pressed ? _down() : _release();
  }

  @override
  void dispose() {
    _holdOffTimer?.cancel();
    _press.dispose();
    super.dispose();
  }

  // Палец может подняться, когда виджета уже нет: листок унесли, и на его месте
  // другое дерево. Сообщение о пальце приходит всё равно.
  void _prepare() {
    final side = context.size?.longestSide ?? 0;
    _depth = side <= 0 ? _maxDepth : math.min(_maxDepth, _pixels / side);
    _held = true;
  }

  void _down() {
    if (!mounted) return;
    _prepare();
    _press.forward();
  }

  void _pointerDown(PointerDownEvent event) {
    if (!mounted || _claimedPointer == event.pointer) return;
    _claimedPointer = event.pointer;
    _pointer = event.pointer;
    _downAt = event.position;
    _prepare();
    _holdOffTimer = Timer(_holdOff, () => _press.forward());
  }

  void _pointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    if ((event.position - _downAt).distance > _swipeSlop) _cancel();
  }

  void _pointerUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _holdOffTimer?.cancel();
    _release();
  }

  void _pointerCancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) _cancel();
  }

  Future<void> _release() async {
    if (!mounted) return;
    _held = false;
    try {
      await _press.forward().orCancel;
      if (mounted && !_held) await _press.reverse().orCancel;
    } on TickerCanceled {
      // Виджет ушёл с экрана посреди нажатия: доигрывать некому.
    }
  }

  void _cancel() {
    _pointer = null;
    _holdOffTimer?.cancel();
    if (!mounted) return;
    _held = false;
    _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scaled = AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Transform.scale(
        key: const ValueKey('press_pulse'),
        scale: 1 - _curve.value * _depth,
        child: child,
      ),
    );
    if (widget.pressed != null) return scaled;
    return Listener(
      onPointerDown: _pointerDown,
      onPointerMove: _pointerMove,
      onPointerUp: _pointerUp,
      onPointerCancel: _pointerCancel,
      child: scaled,
    );
  }
}

/// Содержимое кнопки Material сжимается при нажатии. Кнопки сообщают нажатие сами,
/// поэтому эффект подключается темой, и новые кнопки получают его без правок.
Widget _pulseContent(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) =>
    PressPulse(
      pressed: states.contains(WidgetState.pressed),
      child: child ?? const SizedBox.shrink(),
    );

ButtonStyle _withPulse(ButtonStyle? style) =>
    (style ?? const ButtonStyle()).copyWith(foregroundBuilder: _pulseContent);

/// Тема, в которой кнопки отвечают на палец сжатием.
ThemeData withPressPulse(ThemeData theme) => theme.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: _withPulse(theme.filledButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _withPulse(theme.outlinedButtonTheme.style),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _withPulse(theme.textButtonTheme.style),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _withPulse(theme.elevatedButtonTheme.style),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _withPulse(theme.iconButtonTheme.style),
      ),
    );
