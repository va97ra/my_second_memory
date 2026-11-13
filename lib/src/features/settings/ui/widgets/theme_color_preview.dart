import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'theme_color_sample.dart';
import 'theme_color_target.dart';

/// Плитка-образец в карточке темы: миниатюра и подпись. Выбранная обведена,
/// и палитра под образцами меняет именно её.
class ThemeColorPreview extends StatelessWidget {
  const ThemeColorPreview({
    super.key,
    required this.target,
    required this.selected,
    required this.isRu,
    required this.onTap,
  });

  final ThemeColorTarget target;
  final bool selected;
  final bool isRu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changed = target.isChanged(AppThemeColors.of(context));

    return Semantics(
      selected: selected,
      button: true,
      child: NotebookPressable(
        onTap: onTap,
        child: NotebookCardSurface(
          child: DecoratedBox(
            // Тонкой рамки плитки не хватало: выбранный образец обведён
            // толстой, его видно с первого взгляда.
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: selected
                  ? Border.all(color: theme.colorScheme.primary, width: 2.6)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
              child: Column(
                children: [
                  Expanded(child: ThemeColorSample(target: target)),
                  const SizedBox(height: 4),
                  Text(
                    target.label(isRu: isRu),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      // Изменённый цвет подписан жирнее: видно, что трогали.
                      fontWeight: changed ? FontWeight.w900 : FontWeight.w600,
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
