import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../themes/notebook/notebook_visuals.dart';
import '../themes/screen/screen_visuals.dart';

/// Нажатие без волны: клавиша уходит вниз и на миг притеняется.
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
    this.pressedOffset = 2,
    this.playClick = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final double pressedOffset;
  final bool playClick;

  @override
  State<NotebookPressable> createState() => _NotebookPressableState();
}

class _NotebookPressableState extends State<NotebookPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  void _activate() {
    if (widget.playClick) SystemSound.play(SystemSoundType.click);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    // На тёмном стекле чёрное притенение не видно: нажатие там подсвечивают,
    // а не гасят.
    final dark = NotebookVisuals.maybeOf(context) == null &&
        (ScreenVisuals.maybeOf(context)?.colors.isDark ?? false);
    final pressedTint = dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _activate : null,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(
            0,
            _pressed ? widget.pressedOffset : 0,
            0,
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            color: _pressed ? pressedTint : Colors.transparent,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
