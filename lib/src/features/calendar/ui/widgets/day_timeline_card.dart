import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/memory_card_paper.dart';
import 'day_timeline_card_body.dart';
import 'day_timeline_geometry.dart';

class DayTimelineCard extends StatelessWidget {
  const DayTimelineCard({
    super.key,
    required this.block,
    required this.selected,
  });

  static final _radius = BorderRadius.circular(8);

  final DayTimelineBlock block;
  final bool selected;

  @override
  Widget build(BuildContext context) => PaperSheet(
        child: Builder(
          builder: (context) {
            final colors = Theme.of(context).colorScheme;
            return DecoratedBox(
              decoration: MemoryCardPaper.surface(_radius).copyWith(
                border: Border.all(
                  color: selected ? colors.primary : colors.outlineVariant,
                  width: selected ? 2 : 1,
                ),
                boxShadow: notebookSurfaceShadow(
                  context,
                  NotebookSurfaceDepth.card,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: DayTimelineCardBody(block: block),
              ),
            );
          },
        ),
      );
}
