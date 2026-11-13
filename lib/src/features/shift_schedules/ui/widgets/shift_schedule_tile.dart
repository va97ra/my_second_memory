import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/ui/memory_card/sticker_paper.dart';
import '../../../../shared/ui/memory_card/sticker_strip.dart';
import '../../../../shared/ui/shift_schedule_color.dart';
import '../../../settings/settings.dart';
import '../../state/shift_schedules_controller.dart';
import 'shift_schedule_menu.dart';
import 'shift_schedule_tile_details.dart';

/// Карточка графика на той же бумаге, что и аккаунты: полоса его цвета с рисунком
/// смен, название и будильники. Нажатие открывает редактор.
class ShiftScheduleTile extends ConsumerWidget {
  const ShiftScheduleTile({
    super.key,
    required this.scheduleId,
    required this.locale,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  /// Высота карточки: ряды сетки ровные, сколько бы строк ни было заполнено.
  static double heightOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(144);

  final String scheduleId;
  final String locale;
  final ValueChanged<ShiftSchedule> onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(shiftScheduleByIdProvider(scheduleId));
    if (schedule == null) return const SizedBox.shrink();
    final strings = AppStrings.of(context);
    final accent = schedule.isEnabled
        ? shiftScheduleColor(AppThemeColors.of(context), schedule)
        : AppPalette.done;

    return PressPulse(
      child: StickerPaper(
        accent: accent,
        tint: schedule.isEnabled ? accent.withValues(alpha: 0.1) : null,
        strip: StickerStrip(
          accent: accent,
          label: '${schedule.workDays}/${schedule.restDays}',
          trailingLabel: DateFormat.yMMMd(locale).format(schedule.startDate),
        ),
        child: NotebookPressable(
          key: ValueKey('shift_schedule_${schedule.id}'),
          onTap: () => onEdit(schedule),
          borderRadius: BorderRadius.zero,
          pulse: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ShiftScheduleTileDetails(
                    schedule: schedule,
                    locale: locale,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Semantics(
                      toggled: schedule.isEnabled,
                      child: NotebookPressable(
                        key: ValueKey('shift_schedule_toggle_${schedule.id}'),
                        onTap: onToggle,
                        child: SizedBox(
                          width: 54,
                          height: 40,
                          child: Center(
                            child: SettingsToggle(value: schedule.isEnabled),
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: strings.editShiftSchedule,
                      child: NotebookPressable(
                        key: ValueKey('shift_schedule_menu_${schedule.id}'),
                        onTap: () => showShiftScheduleMenu(
                          context,
                          onEdit: () => onEdit(schedule),
                          onDelete: onDelete,
                        ),
                        child: const SizedBox(
                          width: 36,
                          height: 40,
                          child: Icon(Icons.more_vert_rounded, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
