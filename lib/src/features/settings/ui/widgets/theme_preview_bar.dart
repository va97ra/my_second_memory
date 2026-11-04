import 'package:ez_design/ez_design.dart';
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
            AppPalette.magentaLight,
            AppPalette.magenta,
            AppPalette.magentaDeep,
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: raised
            ? const [
                BoxShadow(
                  color: AppPalette.shadow,
                  blurRadius: 2,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
    );
  }
}
