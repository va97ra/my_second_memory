import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../navigation/page_turn_navigation.dart';

/// Праздники дня одной карточкой. По нажатию открывается их полный список.
class HolidaySummaryCard extends StatelessWidget {
  const HolidaySummaryCard({
    super.key,
    required this.holidays,
    required this.date,
    required this.locale,
  });

  final List<HolidayOccurrence> holidays;
  final DateTime date;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: NotebookCardSurface(
        depth: NotebookSurfaceDepth.card,
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.pageTurnPush(
              '/calendar/holidays?date=${DateFormat('yyyy-MM-dd').format(date)}',
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        Icons.celebration_rounded,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: _titles(context, colors)),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _titles(BuildContext context, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          locale == 'ru' ? 'Праздники' : 'Holidays',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 3),
        for (final holiday in holidays)
          Text(
            '${holiday.title(locale)} — ${holiday.shortDescription(locale)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
      ],
    );
  }
}
