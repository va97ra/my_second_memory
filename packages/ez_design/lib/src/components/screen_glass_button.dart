import 'package:flutter/material.dart';

import '../themes/screen/screen_visuals.dart';
import 'screen_glass_surface.dart';

/// Pressable thick glass used by screen themes.
class ScreenGlassButton extends StatefulWidget {
  const ScreenGlassButton({
    required this.opacity,
    required this.onPressed,
    required this.child,
    this.tint,
    this.selected = false,
    this.semanticLabel,
    this.onHighlightChanged,
    this.painterKey,
    this.lampKey,
    super.key,
  });

  final double opacity;
  final Color? tint;
  final bool selected;
  final String? semanticLabel;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onHighlightChanged;
  final Key? painterKey;
  final Key? lampKey;
  final Widget child;

  @override
  State<ScreenGlassButton> createState() => _ScreenGlassButtonState();
}

class _ScreenGlassButtonState extends State<ScreenGlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = ScreenVisuals.maybeOf(context)!.colors;
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.52,
        child: Listener(
          onPointerDown: enabled ? (_) => _setPressed(true) : null,
          onPointerUp: enabled ? (_) => _setPressed(false) : null,
          onPointerCancel: enabled ? (_) => _setPressed(false) : null,
          child: ScreenGlassSurface(
            colors: colors,
            opacity: widget.opacity,
            tint: widget.tint,
            pressed: _pressed,
            illuminated: _pressed,
            painterKey: widget.painterKey,
            lampKey: widget.lampKey,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onPressed,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    setState(() => _pressed = value);
    widget.onHighlightChanged?.call(value);
  }
}
