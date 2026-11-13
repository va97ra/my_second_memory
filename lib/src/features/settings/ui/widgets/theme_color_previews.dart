import 'dart:math' as math;

import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/even_wrap.dart';
import 'theme_color_preview.dart';
import 'theme_color_target.dart';

/// Все образцы карточки темы по разделам. Графики смен появляются, только
/// когда хотя бы один заведён: без них перекрашивать нечего.
class ThemeColorPreviews extends StatelessWidget {
  const ThemeColorPreviews({
    super.key,
    required this.schedules,
    required this.selected,
    required this.isRu,
    required this.onSelect,
  });

  final List<ShiftSchedule> schedules;
  final ThemeColorTarget selected;
  final bool isRu;
  final ValueChanged<ThemeColorTarget> onSelect;

  /// Порядок разделов — от самого заметного: календарь видят первым.
  static const calendar = [
    ThemeRoleTarget(AppColorRole.weekend),
    ThemeRoleTarget(AppColorRole.shortenedDay),
    ThemeRoleTarget(AppColorRole.today),
  ];

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      children: [
        _section(isRu ? 'Календарь' : 'Calendar', calendar, scaler),
        if (schedules.isNotEmpty)
          _section(
            isRu ? 'Графики смен' : 'Shift schedules',
            [for (final schedule in schedules) ThemeShiftTarget(schedule)],
            scaler,
          ),
        _section(
          isRu ? 'Оформление' : 'Interface',
          const [ThemeRoleTarget(AppColorRole.accent)],
          scaler,
        ),
        _section(
          isRu ? 'Записи' : 'Records',
          [for (final type in MemoryType.values) ThemeRoleTarget.type(type)],
          scaler,
        ),
      ],
    );
  }

  Widget _section(
    String title,
    List<ThemeColorTarget> targets,
    TextScaler scaler,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLabeledDivider(
          label: title,
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
        ),
        EvenWrap(
          // На телефоне три в ряд, как карточки записок.
          columns: (width) => math.max(2, width / scaler.scale(1) ~/ 104),
          itemHeight: scaler.scale(78),
          children: [
            for (final target in targets)
              ThemeColorPreview(
                key: ValueKey('theme_color_$target'),
                target: target,
                selected: target == selected,
                isRu: isRu,
                onTap: () => onSelect(target),
              ),
          ],
        ),
      ],
    );
  }
}
