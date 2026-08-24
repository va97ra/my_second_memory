part of '../home_feed_screen.dart';

class _NotebookFeedBook extends StatelessWidget {
  const _NotebookFeedBook({
    required this.selected,
    required this.onSelected,
    required this.page,
  });

  final FeedSection selected;
  final ValueChanged<FeedSection> onSelected;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        const tabHeight = 52.0;

        return Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: 12,
              right: 14,
              top: 12,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    const Color(0x1F7A4A22),
                    notebook.paper,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0x557A4A22),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 7,
              right: 20,
              top: 7,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: notebook.paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x667A4A22)),
                ),
              ),
            ),
            Positioned(
              left: 4,
              right: 4,
              top: 3,
              bottom: tabHeight,
              child: SizedBox.expand(
                key: const ValueKey('notebook_feed_sheet'),
                child: page,
              ),
            ),
            Positioned(
              left: 4,
              top: 3,
              bottom: tabHeight,
              width: 14,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4,
              right: 4,
              bottom: 8,
              height: tabHeight,
              child: _NotebookSectionTabs(
                selected: selected,
                onSelected: onSelected,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _NotebookSectionTabs extends StatelessWidget {
  const _NotebookSectionTabs({
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
            child: _NotebookIndexTab(
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

class _NotebookIndexTab extends StatelessWidget {
  const _NotebookIndexTab({
    required this.section,
    required this.selected,
    required this.compact,
    required this.onPressed,
  });

  final FeedSection section;
  final bool selected;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context)!;
    final base = switch (section) {
      FeedSection.day => notebook.yellow,
      FeedSection.notes => notebook.teal,
    };
    final label = _sectionTabLabel(context, section, compact: compact);
    final fullLabel = _sectionTabLabel(context, section);
    final edgeColor =
        selected ? const Color(0xFF8B542D) : const Color(0x996D4528);
    const pageEdgeColor = Color(0xFF9A6034);
    return Semantics(
      button: true,
      selected: selected,
      label: fullLabel,
      child: SizedBox(
        key: ValueKey('feed_section_${section.name}'),
        height: 52,
        child: Align(
          alignment: Alignment.bottomCenter,
          // Paper does not ripple. Pressing a tab pushes it further out of
          // the book instead.
          child: NotebookPressable(
            onTap: selected ? null : onPressed,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(7),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              height: selected ? 52 : 44,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: selected
                    ? Color.alphaBlend(
                        base.withValues(alpha: 0.14),
                        notebook.paper,
                      )
                    : Color.alphaBlend(
                        base.withValues(alpha: 0.34),
                        notebook.paper,
                      ),
                image: DecorationImage(
                  image: AssetImage(notebook.paperAsset),
                  fit: BoxFit.cover,
                  opacity: 0.55,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
                // A single visible colour keeps the border paintable with a
                // border radius.
                border: Border(
                  left: BorderSide(color: edgeColor, width: 0.8),
                  // A tab has no edge of its own on top: it is cut from the
                  // sheet above it. What crosses the tabs behind the current
                  // sheet is that sheet's own bottom edge, drawn below.
                  top: BorderSide.none,
                  right: BorderSide(color: edgeColor, width: 0.8),
                  bottom: BorderSide(color: edgeColor, width: 0.8),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Tabs behind the current sheet are crossed by its bottom
                  // edge and lie in its shadow.
                  if (!selected) ...[
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 10,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 1.2,
                      child: IgnorePointer(
                        child: ColoredBox(color: pageEdgeColor),
                      ),
                    ),
                  ],
                  Center(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(4, selected ? 8 : 0, 4, 0),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: notebook.ink,
                              fontSize: compact ? 9 : 10,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
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

class _FeedTopSectionSelector extends StatelessWidget {
  const _FeedTopSectionSelector({
    required this.selected,
    required this.onSelected,
  });

  final FeedSection selected;
  final ValueChanged<FeedSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
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
                      label: _sectionTabLabel(context, section),
                      child: Material(
                        color: section == selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: ValueKey('feed_section_${section.name}'),
                          onTap: section == selected
                              ? null
                              : () => onSelected(section),
                          child: Center(
                            child: Text(
                              _sectionTabLabel(
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

String _sectionTabLabel(
  BuildContext context,
  FeedSection section, {
  bool compact = false,
}) {
  final strings = AppStrings.of(context);
  return switch (section) {
    FeedSection.day => strings.dayTab,
    FeedSection.notes => compact ? strings.notesTabShort : strings.notes,
  };
}
