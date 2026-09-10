import 'package:flutter/material.dart';

import '../../themes/screen/screen_theme_colors.dart';
import '../notebook_pressable.dart';
import '../screen_glass_surface.dart';
import 'nav_bar_item.dart';

/// One shell tool rendered as a separate plate of thick glass.
///
/// The shell deliberately keeps [NotebookPressable] instead of Material ink:
/// an ink splash is composited on the panel and briefly hides its backdrop.
class ScreenToolGlassButton extends StatefulWidget {
  const ScreenToolGlassButton({
    required this.item,
    required this.colors,
    required this.tint,
    required this.selected,
    required this.onTap,
    required this.iconSide,
    super.key,
  });

  final NavBarItem item;
  final ScreenThemeColors colors;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;
  final double iconSide;

  @override
  State<ScreenToolGlassButton> createState() => _ScreenToolGlassButtonState();
}

class _ScreenToolGlassButtonState extends State<ScreenToolGlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selectedTint = Color.alphaBlend(
      widget.tint.withValues(alpha: widget.selected ? 0.38 : 0.10),
      widget.colors.panel,
    );
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.item.label,
      child: Tooltip(
        message: widget.item.label,
        child: NotebookPressable(
          onTap: widget.onTap,
          playClick: false,
          pressedOffset: 0,
          onHighlightChanged: (pressed) {
            if (mounted) setState(() => _pressed = pressed);
          },
          child: ScreenGlassSurface(
            colors: widget.colors,
            opacity: widget.colors.isDark ? 0.46 : 0.30,
            tint: selectedTint,
            pressed: _pressed,
            illuminated: _pressed,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: widget.iconSide,
                    height: widget.iconSide,
                    decoration: BoxDecoration(
                      color: widget.tint.withValues(
                        alpha: widget.selected ? 0.28 : 0.16,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.item.icon,
                      size: widget.iconSide * 0.55,
                      color: widget.tint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: widget.selected
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color:
                              widget.selected ? widget.tint : widget.colors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
