import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/ui/memory_card/memory_item_presentation.dart';

/// Шапка безопасного просмотра: вид записи, её дата и время.
class MemoryViewHeader extends StatelessWidget {
  const MemoryViewHeader({super.key, required this.item});

  final MemoryItem item;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final typeColor = memoryTypeColor(item.type);
    final timeText =
        item.timeMinutes == null ? null : formatMinutesOfDay(item.timeMinutes!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              memoryTypeIcon(item.type),
              color: typeColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.isUndated ? strings.noteCard : item.type.label(locale),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: typeColor,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
          // У записки нет ни даты, ни времени: показывать нечего.
          if (!item.isUndated)
            Text(
              DateFormat('d MMM y', locale).format(item.memoryDate),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF6B5B47),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          if (!item.isUndated && timeText != null) ...[
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                child: Text(
                  timeText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: typeColor,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
