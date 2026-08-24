import 'package:flutter/material.dart';

import '../../state/feed_providers.dart';
import '../feed_labels.dart';

/// Выбор закладки вне блокнотной темы: обычные кнопки над лентой.
class FeedTopSectionSelector extends StatelessWidget {
  const FeedTopSectionSelector({
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
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
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
