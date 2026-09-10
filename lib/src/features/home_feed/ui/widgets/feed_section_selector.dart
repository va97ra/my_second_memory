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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
        child: SizedBox(
          height: 52,
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
                      child: Material(
                        color: section == selected
                            ? colors.primaryContainer
                            : colors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('feed_section_${section.name}'),
                          onTap: section == selected
                              ? null
                              : () => onSelected(section),
                          child: Center(
                            child: Text(
                              feedSectionTabLabel(
                                context,
                                section,
                                compact: compact,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
