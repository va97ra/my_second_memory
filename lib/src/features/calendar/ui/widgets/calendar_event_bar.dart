import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import '../../../../shared/ui/memory_card/memory_item_presentation.dart';

import 'outlined_calendar_text.dart';

/// Полоска записи в ячейке дня.
class CalendarEventBar extends StatelessWidget {
  const CalendarEventBar({
    super.key,
    required this.item,
    required this.locale,
    required this.isMuted,
  });

  final MemoryItem item;
  final String locale;
  final bool isMuted;

  static const _verticalPadding = 1.0;

  /// Высота полоски при таком масштабе шрифта системы: текст растёт вместе
  /// с ним, поля — нет. Строку текста движок округляет вверх до целого.
  static double extentFor(double textScale) =>
      (OutlinedCalendarText.fontSize * textScale).ceilToDouble() +
      _verticalPadding * 2;

  @override
  Widget build(BuildContext context) {
    final color = memoryAccentColor(AppThemeColors.of(context), item);
    final colors = Theme.of(context).colorScheme;
    final barColor = isMuted ? color.withValues(alpha: 0.48) : color;
    final title = _recordTitle(item, locale);
    final time = _formatTime(item.timeMinutes);
    final text = time == null ? title : '$time $title';

    return DecoratedBox(
      key: ValueKey('calendar_event_bar_${item.id}'),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: colors.onSurface.withValues(alpha: isMuted ? 0.3 : 0.62),
          width: 0.75,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: _verticalPadding,
        ),
        child: OutlinedCalendarText(text: text),
      ),
    );
  }

  String? _formatTime(int? minutes) {
    if (minutes == null) {
      return null;
    }
    return formatMinutesOfDay(minutes);
  }

  String _recordTitle(MemoryItem item, String locale) {
    final title = item.title.trim();
    if (title.isNotEmpty) {
      return title;
    }
    final body = item.plainBody.trim();
    if (body.isNotEmpty) {
      return body.split(RegExp(r'\s+')).take(4).join(' ');
    }
    return item.type.label(locale);
  }
}
