import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'theme_preview_bar.dart';
import 'theme_preview_paper.dart';

/// Как выглядит тема: обложка, лист и строка текста на нём.
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
    final colors = switch (style) {
      AppThemeStyle.notebookLight => const [
          Color(0xFFC98D57),
          Color(0xFFFFF0CD),
        ],
      AppThemeStyle.notebookDark => const [
          Color(0xFF1C1512),
          Color(0xFF3A332C),
        ],
    };
    final ink =
        style.isDark ? const Color(0xFFEDE6DA) : const Color(0xFF201712);
    final backgroundTexture =
        style.isDark ? NotebookAssets.darkWood : NotebookAssets.wood;
    final panelTexture =
        style.isDark ? NotebookAssets.darkPaper : NotebookAssets.paper;
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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    image: DecorationImage(
                      image: AssetImage(backgroundTexture),
                      fit: BoxFit.cover,
                      opacity: style.isDark ? 0.9 : 0.75,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Column(
                      children: [
                        ThemePreviewPaper(
                          color: colors.last,
                          texture: panelTexture,
                          ink: ink,
                          height: 15,
                          bordered: false,
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ThemePreviewPaper(
                            color: colors.last,
                            texture: panelTexture,
                            ink: ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const ThemePreviewBar(),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ThemePreviewPaper(
                            color: colors.last,
                            texture: panelTexture,
                            ink: ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const ThemePreviewBar(raised: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
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
