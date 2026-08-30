import 'package:flutter/material.dart';

import '../themes/notebook/notebook_background.dart';

/// Width an icon button claims beside a header title, tap padding included.
///
/// A centred title needs the same width claimed on both sides, so a header
/// with nothing to put in a slot leaves the slot empty rather than closing it.
/// Ширина, которую шапка занимает под кнопку с каждой стороны заголовка.
///
/// Одна на все шапки приложения: и на бумажную шапку страницы, и на AppBar.
/// Пока их было две, кнопка «назад» на разных экранах выходила разного
/// размера — это видно невооружённым глазом.
const double notebookHeaderSlot = 48;

/// One band of a page header, two ruled rows tall unless told otherwise.
@immutable
class NotebookHeaderBand {
  const NotebookHeaderBand({required this.child, this.ruledRows = 2});

  final Widget child;
  final int ruledRows;
}

/// Зазор между шапкой и панелью над ней.
///
/// Шапка — продолжение верхней панели, а не плашка, брошенная посреди листа:
/// она держится к панели вплотную. Раньше карту опускали на ближайшую линейку,
/// и лист начинался с пустой полосы в треть шапки высотой.
const double notebookHeaderTopSpacing = 2;

/// The header every page wears: a card lying on ruled paper, split into bands.
///
/// Each band is a whole number of ruled rows, so the header keeps the rhythm
/// of the page it sits on. The card's border paints inside the box and costs
/// no height; the divider between two bands costs one pixel, which the lower
/// band gives back.
class NotebookPageHeader extends StatelessWidget {
  const NotebookPageHeader({
    required this.bands,
    this.cardKey,
    super.key,
  });

  final List<NotebookHeaderBand> bands;

  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          10,
          notebookHeaderTopSpacing,
          10,
          6,
        ),
        child: NotebookCardSurface(
          key: cardKey,
          depth: NotebookSurfaceDepth.card,
          // The header is the cover the page is bound into, same material as
          // the navigation panel.
          material: NotebookSurfaceMaterial.leather,
          padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
          child: Column(
            children: [
              for (var index = 0; index < bands.length; index++) ...[
                if (index > 0) const Divider(height: 1, thickness: 1),
                SizedBox(
                  height: bands[index].ruledRows * notebookPageLineHeight -
                      (index == 0 ? 0 : 1),
                  child: bands[index].child,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
