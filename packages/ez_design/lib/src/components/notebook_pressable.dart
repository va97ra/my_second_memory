import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'press_pulse.dart';

/// Нажатие без волны: клавиша мягко сжимается и на миг притеняется.
///
/// Материаловская волна здесь не годится. Она рисуется на ближайшем материале
/// выше по дереву — а это материал `Scaffold` во весь экран, — и на стеклянных
/// темах светлая волна проступает сквозь стекло, закрывая задник заливкой.
/// Блокнот обходился без неё с самого начала; теперь так же ведут себя все
/// темы, меняется только цвет притенения: тёмный на светлом, светлый на
/// тёмном.
class NotebookPressable extends StatefulWidget {
  const NotebookPressable({
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.pulse = true,
    this.playClick = true,
    this.onHighlightChanged,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  /// Сжиматься ли самому. Выключают, когда сжимается вещь снаружи: плитка дня,
  /// листок целиком.
  final bool pulse;
  final bool playClick;
  final ValueChanged<bool>? onHighlightChanged;

  @override
  State<NotebookPressable> createState() => _NotebookPressableState();
}

class _NotebookPressableState extends State<NotebookPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
    widget.onHighlightChanged?.call(value);
  }

  void _activate() {
    if (widget.playClick) SystemSound.play(SystemSoundType.click);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final pressedTint = Colors.black.withValues(alpha: 0.08);
    return Semantics(
      button: true,
      enabled: enabled,
      child: _pulsed(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _activate : null,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            foregroundDecoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              color: _pressed ? pressedTint : Colors.transparent,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }

  Widget _pulsed(Widget child) =>
      widget.pulse ? PressPulse(child: child) : child;
}
