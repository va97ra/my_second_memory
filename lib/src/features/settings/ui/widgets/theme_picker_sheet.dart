import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_style.dart';
import '../../../../core/theme/notebook/notebook_assets.dart';
import '../../../../shared/ui/notebook_pressable.dart';

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
                          AppThemeStyle.light => isRu ? 'Светлая' : 'Light',
                          AppThemeStyle.dark => isRu ? 'Тёмная' : 'Dark',
                          AppThemeStyle.notebook =>
                            isRu ? 'Блокнот' : 'Notebook',
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
      AppThemeStyle.light => const [Color(0xFFF4F1EB), Color(0xFFFFFDF9)],
      AppThemeStyle.dark => const [Color(0xFF080706), Color(0xFF333632)],
      AppThemeStyle.notebook => const [Color(0xFFC98D57), Color(0xFFFFF1D2)],
    };
    final ink = style == AppThemeStyle.dark
        ? const Color(0xFFF5F2EC)
        : const Color(0xFF281A13);
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
                    image: style == AppThemeStyle.notebook
                        ? const DecorationImage(
                            image: AssetImage(NotebookAssets.wood),
                            fit: BoxFit.cover,
                            opacity: 0.75,
                          )
                        : null,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Column(
                      children: [
                        Container(
                          height: 15,
                          decoration: BoxDecoration(
                            color: colors.last,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.last,
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
                            color: style == AppThemeStyle.notebook
                                ? const Color(0xFFF0643F)
                                : ink.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: style == AppThemeStyle.notebook
                                ? const [
                                    BoxShadow(
                                      color: Color(0xFF7E2416),
                                      offset: Offset(0, 3),
                                    ),
                                  ]
                                : null,
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
                    Icons.check_circle,
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
