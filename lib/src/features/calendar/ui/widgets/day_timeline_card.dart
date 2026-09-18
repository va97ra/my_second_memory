import 'package:flutter/material.dart';
import 'package:ez_design/ez_design.dart';
import 'day_timeline_geometry.dart';
import 'day_timeline_card_body.dart';

class DayTimelineCard extends StatelessWidget {
  const DayTimelineCard(
      {super.key,
      required this.block,
      required this.selected,
      required this.handles});
  final DayTimelineBlock block;
  final bool selected;
  final Widget handles;
  @override
  Widget build(BuildContext context) => PaperSheet(
        child: Builder(
          builder: (context) {
            final colors = Theme.of(context).colorScheme;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      image: const DecorationImage(
                        image: AssetImage(NotebookAssets.paper),
                        fit: BoxFit.cover,
                        opacity: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            selected ? colors.primary : colors.outlineVariant,
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
                  ),
                ),
                if (selected) Positioned.fill(child: handles),
              ],
            );
          },
        ),
      );
}
