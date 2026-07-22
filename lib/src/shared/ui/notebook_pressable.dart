import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/notebook/notebook_visuals.dart';

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
    if (NotebookVisuals.maybeOf(context) == null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          child: widget.child,
        ),
      );
    }
    final enabled = widget.onTap != null;
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
            color: _pressed
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
