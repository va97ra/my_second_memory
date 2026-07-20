import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../memory_items/domain/memory_item.dart';
import '../../memory_items/domain/memory_type.dart';
import '../../memory_items/ui/widgets/memory_item_presentation.dart';
import '../domain/recurrence_series.dart';
import '../state/recurrence_controller.dart';

class RecurringInformers extends ConsumerWidget {
  const RecurringInformers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(recurrenceLoadProvider);
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _RecurringInformer(
              frequency: RecurrenceFrequency.monthly,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _RecurringInformer(
              frequency: RecurrenceFrequency.yearly,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringInformer extends ConsumerWidget {
  const _RecurringInformer({required this.frequency});

  final RecurrenceFrequency frequency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).languageCode;
    final monthly = frequency == RecurrenceFrequency.monthly;
    final upcoming = ref.watch(recurringCurrentPeriodItemsProvider(frequency));
    final colors = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final title = monthly
        ? _capitalize(DateFormat.MMMM(locale).format(now))
        : (locale == 'ru' ? '${now.year} год' : '${now.year}');
    final route = monthly ? '/recurring/monthly' : '/recurring/yearly';

    return SizedBox(
      height: 126,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(7, 3, 7, 7),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.push(route),
                child: SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      Icon(
                        monthly ? Icons.sync_outlined : Icons.event_repeat,
                        color: colors.primary,
                        size: 17,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                      ),
                      Text(
                        '${upcoming.length}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const Icon(Icons.chevron_right, size: 15),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: upcoming.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          locale == 'ru' ? 'Пока пусто' : 'No records yet',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      )
                    : Scrollbar(
                        child: ListView.separated(
                          primary: false,
                          padding: EdgeInsets.zero,
                          physics: const ClampingScrollPhysics(),
                          itemCount: upcoming.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 3),
                          itemBuilder: (context, index) {
                            final item = upcoming[index];
                            return _RecurringMiniCard(
                              item: item,
                              locale: locale,
                              onTap: () => context.push(
                                '/memory/view/${Uri.encodeComponent(item.id)}',
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _RecurringMiniCard extends StatelessWidget {
  const _RecurringMiniCard({
    required this.item,
    required this.locale,
    required this.onTap,
  });

  final MemoryItem item;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = memoryTypeColor(item.type);
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: typeColor.withValues(alpha: 0.38)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 34,
          child: Row(
            children: [
              SizedBox(width: 4, child: ColoredBox(color: typeColor)),
              const SizedBox(width: 5),
              Icon(memoryTypeIcon(item.type), color: typeColor, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurface,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      _details(item, locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

String _details(MemoryItem item, String locale) {
  final details = <String>[
    (item.repeatRule == RecurrenceFrequency.yearly.name
            ? DateFormat.yMMMd(locale)
            : DateFormat.MMMd(locale))
        .format(item.memoryDate),
    if (item.timeMinutes != null) formatMemoryTime(item.timeMinutes!),
  ];
  if (item.type == MemoryType.payment && item.amountMinor != null) {
    details.add('${_formatMoney(item.amountMinor!)} ₽');
  }
  if (item.type == MemoryType.birthday && item.birthYear != null) {
    final age = item.memoryDate.year - item.birthYear!;
    details.add(locale == 'ru' ? '$age лет' : '$age years');
  }
  return details.join(' · ');
}

String _formatMoney(int minor) {
  return NumberFormat.decimalPattern('ru').format(minor ~/ 100);
}
