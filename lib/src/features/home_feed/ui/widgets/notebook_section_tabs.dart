import 'package:flutter/material.dart';

import '../../state/feed_providers.dart';
import 'notebook_index_tab.dart';

/// Полоса закладок под листом блокнота.
class NotebookSectionTabs extends StatelessWidget {
  const NotebookSectionTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final FeedSection selected;
  final ValueChanged<FeedSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final section in FeedSection.values)
          Expanded(
            child: NotebookIndexTab(
              section: section,
              selected: section == selected,
              compact: compact,
              onPressed: () => onSelected(section),
            ),
          ),
      ],
    );
  }
}
