import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'theme_preview_notebook.dart';
import 'theme_preview_screen.dart';

/// Образец темы: как она выглядит, и подпись под ним.
///
/// Обложку рисует та миниатюра, которая теме подходит: блокнотная — дерево
/// с листом, экранная — сетку дней на тёмном фоне. Рамка, подпись и галочка
/// общие: выбор должен читаться одинаково, чем бы тема ни была внутри.
class ThemePreview extends StatelessWidget {
  const ThemePreview({
    super.key,
    required this.style,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final AppThemeStyle style;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenColors = screenColorsOf(style);

    return NotebookPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 0.82,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: screenColors == null
                    ? ThemePreviewNotebook(
                        dark: style == AppThemeStyle.notebookDark,
                      )
                    : ThemePreviewScreen(colors: screenColors),
              ),
            ),
            const SizedBox(height: 7),
            // Галочка стоит у края и подпись не двигает — так же, как в
            // выборе шрифта. Иначе подпись прыгает вбок при переключении.
            Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (selected)
                  Positioned(
                    right: 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
