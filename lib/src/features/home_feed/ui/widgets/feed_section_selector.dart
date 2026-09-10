import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../state/feed_providers.dart';
import '../feed_labels.dart';

/// Выбор закладки вне блокнотной темы: кнопки под лентой.
///
/// Внизу, а не наверху: до них дотягивается большой палец, а верх страницы
/// принадлежит периоду и записям. В блокнотной теме закладки торчат сбоку
/// книги, и этот ряд там не показывается вовсе.
class FeedSectionSelector extends StatelessWidget {
  const FeedSectionSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FeedSection selected;
  final ValueChanged<FeedSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final colors = Theme.of(context).colorScheme;
    final screen = ScreenVisuals.maybeOf(context)?.colors;
    final radius = BorderRadius.circular(8);

    return SafeArea(
      top: false,
      // Снизу почти вплотную к панели: закладка принадлежит ей, а не листу
      // над собой, и полоска фона между ними разрывала эту пару.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
        child: SizedBox(
          height: 44,
          child: Row(
            children: [
              for (final section in FeedSection.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Semantics(
                      button: true,
                      selected: section == selected,
                      label: feedSectionTabLabel(context, section),
                      child: _tab(context, section, colors, screen, radius,
                          compact: compact),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Закладка: в экранных темах пластина стекла, в блокнотных — прежняя
  /// плашка. Выбранная подкрашена акцентом, но остаётся стеклом: сплошная
  /// заливка рядом со стеклянными соседями читается чужой.
  Widget _tab(
    BuildContext context,
    FeedSection section,
    ColorScheme colors,
    ScreenThemeColors? screen,
    BorderRadius radius, {
    required bool compact,
  }) {
    final isSelected = section == selected;
    final label = Center(
      child: Text(
        feedSectionTabLabel(context, section, compact: compact),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: isSelected && screen != null ? screen.accent : null,
            ),
      ),
    );
    final tap = NotebookPressable(
      key: ValueKey('feed_section_${section.name}'),
      onTap: isSelected ? null : () => onSelected(section),
      playClick: false,
      pressedOffset: 1,
      borderRadius: radius,
      child: label,
    );

    if (screen == null) {
      return Material(
        color: isSelected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: tap,
      );
    }
    return DecoratedBox(
      decoration: GlassSurface.decoration(
        screen,
        radius: radius,
        tint: isSelected ? screen.accent.withValues(alpha: 0.26) : null,
      ),
      child: tap,
    );
  }
}
