import 'package:flutter/material.dart';

import 'package:ez_design/ez_design.dart';

Future<AppThemeStyle?> showThemePickerSheet({
  required BuildContext context,
  required AppThemeStyle selected,
  required bool isRu,
}) {
  return showModalBottomSheet<AppThemeStyle>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isRu ? 'Выберите оформление' : 'Choose appearance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final style in AppThemeStyle.values) ...[
                    Expanded(
                      child: _ThemePreview(
                        style: style,
                        selected: style == selected,
                        label: switch (style) {
                          AppThemeStyle.notebookLight =>
                            isRu ? 'Светлый' : 'Light',
                          AppThemeStyle.notebookDark =>
                            isRu ? 'Тёмный' : 'Dark',
                        },
                        onTap: () => Navigator.of(context).pop(style),
                      ),
                    ),
                    if (style != AppThemeStyle.values.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
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
                        Container(
                          height: 15,
                          decoration: BoxDecoration(
                            color: colors.last,
                            image: DecorationImage(
                              image: AssetImage(panelTexture),
                              fit: BoxFit.cover,
                              opacity: 0.42,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.last,
                              image: DecorationImage(
                                image: AssetImage(panelTexture),
                                fit: BoxFit.cover,
                                opacity: 0.42,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: ink.withValues(alpha: 0.25)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 16,
                          decoration: BoxDecoration(
                            // Terracotta belongs to both notebooks.
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFC97655),
                                Color(0xFFC2492E),
                                Color(0xFF8E3520),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.last,
                              image: DecorationImage(
                                image: AssetImage(panelTexture),
                                fit: BoxFit.cover,
                                opacity: 0.42,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: ink.withValues(alpha: 0.25)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
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
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 2,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
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
