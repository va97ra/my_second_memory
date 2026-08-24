import 'package:flutter/material.dart';

/// Лист бумаги на миниатюре темы.
class ThemePreviewPaper extends StatelessWidget {
  const ThemePreviewPaper({
    super.key,
    required this.color,
    required this.texture,
    required this.ink,
    this.height,
    this.bordered = true,
  });

  final Color color;
  final String texture;
  final Color ink;

  /// Null — лист занимает всё оставшееся место.
  final double? height;

  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        image: DecorationImage(
          image: AssetImage(texture),
          fit: BoxFit.cover,
          opacity: 0.42,
        ),
        borderRadius: BorderRadius.circular(4),
        border:
            bordered ? Border.all(color: ink.withValues(alpha: 0.25)) : null,
      ),
    );
  }
}
