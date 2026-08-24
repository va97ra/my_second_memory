import 'package:flutter/material.dart';

/// Терракотовая полоса на миниатюре темы: она одна в обеих темах.
class ThemePreviewBar extends StatelessWidget {
  const ThemePreviewBar({super.key, this.raised = false});

  /// Приподнятая полоса лежит поверх листа и отбрасывает тень.
  final bool raised;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFC97655),
            Color(0xFFC2492E),
            Color(0xFF8E3520),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: raised
            ? const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 2,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
    );
  }
}
