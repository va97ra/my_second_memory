import 'package:flutter/material.dart';

import '../themes/notebook/notebook_background.dart';
import '../themes/notebook/notebook_visuals.dart';

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

/// The header every page wears: a card lying on ruled paper, split into bands.
///
/// The card starts on a ruled line and each band is a whole number of ruled
/// rows, so the header never floats between the ruling. The card's border
/// paints inside the box and costs no height; the divider between two bands
/// costs one pixel, which the lower band gives back.
class NotebookPageHeader extends StatelessWidget {
  const NotebookPageHeader({
    required this.bands,
    this.alignToRuling = true,
    this.sheetTopInset = 0,
    this.cardKey,
    super.key,
  });

  final List<NotebookHeaderBand> bands;

  /// Whether to drop the card onto a ruled line. Off where the header does not
  /// sit at the top of the page, since then there is no line to meet.
  final bool alignToRuling;

  /// How far below the top of the ruled background the page itself starts.
  final double sheetTopInset;

  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final onRuling = alignToRuling && NotebookVisuals.maybeOf(context) != null;
    final topPadding = onRuling
        ? _ruledTopPadding(MediaQuery.paddingOf(context).top + sheetTopInset)
        : 6.0;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, topPadding, 10, 6),
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

/// Top padding that drops the header onto the first ruled line it can reach.
///
/// [offset] is everything the header already sits below. Lines only exist from
/// [notebookPageLineTop] downwards, so a header that would start above the
/// first one waits for it.
double _ruledTopPadding(double offset) {
  final steps =
      ((offset - notebookPageLineTop) / notebookPageLineHeight).ceil();
  final line =
      notebookPageLineTop + (steps < 0 ? 0 : steps) * notebookPageLineHeight;
  return line - offset;
}
