import 'package:flutter/material.dart';

import '../../../../core/theme/app_surface_textures.dart';
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
      AppThemeStyle.light => const [Color(0xFFF4F7F8), Color(0xFFDDE6EA)],
      AppThemeStyle.dark => const [Color(0xFF07090D), Color(0xFF27333F)],
      AppThemeStyle.notebook => const [Color(0xFFC98D57), Color(0xFFFFF0CD)],
    };
    final ink = style == AppThemeStyle.dark
        ? const Color(0xFFF7F9FC)
        : const Color(0xFF17222B);
    final backgroundTexture = switch (style) {
      AppThemeStyle.light => LightThemeAssets.wood,
      AppThemeStyle.dark => DarkThemeAssets.wood,
      AppThemeStyle.notebook => NotebookAssets.wood,
    };
    final panelTexture = switch (style) {
      AppThemeStyle.light => LightThemeAssets.paper,
      AppThemeStyle.dark => DarkThemeAssets.paper,
      AppThemeStyle.notebook => NotebookAssets.paper,
    };
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
                      opacity: switch (style) {
                        AppThemeStyle.light => 0.62,
                        AppThemeStyle.dark => 0.9,
                        AppThemeStyle.notebook => 0.75,
                      },
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
                            gradient: style == AppThemeStyle.light
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFF7D52),
                                      Color(0xFFF05A30),
                                      Color(0xFFB72F1B),
                                    ],
                                  )
                                : style == AppThemeStyle.dark
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFFF8B65),
                                          Color(0xFFFF6A3D),
                                          Color(0xFFC9361E),
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFFFF7F57),
                                          Color(0xFFF4512A),
                                          Color(0xFFB92B16),
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
