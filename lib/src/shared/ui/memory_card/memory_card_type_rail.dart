import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'memory_item_presentation.dart';

/// Левая полоса карточки: вид записи, её дата и время.
class MemoryCardTypeRail extends StatelessWidget {
  const MemoryCardTypeRail({
    super.key,
    required this.item,
    required this.color,
    required this.showDate,
    required this.compact,
    required this.denseFeedLayout,
  });

  final MemoryItem item;
  final Color color;
  final bool showDate;
  final bool compact;
  final bool denseFeedLayout;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    // Спрашиваем страницу, а не бумагу под собой: внутри листа блокнот есть
    // всегда — им бумага и нарисована, — а кожаная полоса положена только на
    // блокнотной странице.
    final notebookPage = PaperSheet.pageIsNotebook(context);
    final foreground =
        notebookPage ? notebookLeatherForeground(color) : Colors.white;
    // Рваный край откусывает часть этой полосы, поэтому её содержимое
    // отодвинуто от него.
    final tearInset = notebookPage ? TornPaperShapeBorder.tearDepth : 0.0;
    final verticalPadding = denseFeedLayout
        ? 4.0
        : compact
            ? 6.0
            : 8.0;
    final time = item.timeMinutes == null
        ? DateFormat.Hm(locale).format(item.createdAt)
        : formatMinutesOfDay(item.timeMinutes!);

    // Кожа — примета блокнота. На странице другой темы полоса ровного цвета:
    // тиснению там взяться неоткуда. Спрашивать об этом саму поверхность
    // нельзя — внутри листа блокнот есть всегда.
    final rail = SizedBox(
      width: (compact ? 50 : 54) + tearInset,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          3 + tearInset,
          verticalPadding,
          3,
          verticalPadding,
        ),
        child: Column(
          children: [
            // Значок и подпись всегда прижаты к верху — и у датированных, и
            // у записок. Раньше записка центрировалась распоркой сверху, и
            // подписи соседних карточек стояли на разной высоте.
            Icon(
              memoryTypeIcon(item.type),
              color: foreground,
              size: denseFeedLayout
                  ? 17
                  : compact
                      ? 19
                      : 21,
            ),
            SizedBox(height: denseFeedLayout ? 2 : (compact ? 3 : 5)),
            Text(
              item.isUndated
                  ? AppStrings.of(context).noteCard
                  : item.type.label(locale),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontSize: denseFeedLayout
                        ? 7.8
                        : compact
                            ? 8.2
                            : 8.8,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
            ),
            const Spacer(),
            if (!item.isUndated && showDate)
              Text(
                DateFormat.MMMd(locale).format(item.memoryDate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foreground.withValues(alpha: 0.88),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            if (!item.isUndated)
              Text(
                time,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontSize: compact ? 10 : 10.5,
                      fontWeight: FontWeight.w900,
                    ),
              ),
          ],
        ),
      ),
    );

    return notebookPage
        ? NotebookLeatherSurface(color: color, child: rail)
        : ColoredBox(color: color, child: rail);
  }
}
