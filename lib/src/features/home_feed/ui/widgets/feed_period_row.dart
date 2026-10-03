import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Полоса шапки с периодом: стрелки листают его, нажатие на подпись
/// открывает выбор дня.
class FeedPeriodRow extends StatelessWidget {
  const FeedPeriodRow({
    super.key,
    required this.label,
    required this.onPickDate,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPickDate;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Row(
      children: [
        IconButton(
          key: const ValueKey('feed_previous_period'),
          tooltip: strings.previousPeriod,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded, size: 24),
          style: notebookIconButtonStyle(),
        ),
        Expanded(
          // Свой прозрачный материал: без него волна нажатия уходит
          // материалу `Scaffold` и рисуется поверх задника.
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: const ValueKey('feed_pick_date'),
              onTap: onPickDate,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.08,
                      ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('feed_next_period'),
          tooltip: strings.nextPeriod,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded, size: 24),
          style: notebookIconButtonStyle(),
        ),
      ],
    );
  }
}
