import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import '../../../shared/ui/screen_chrome.dart';
import 'package:ez_data/ez_data.dart';
import '../../notifications/ui/reminder_sound_picker.dart';
import 'package:ez_domain/ez_domain.dart';
import '../state/shift_schedules_controller.dart';
import '../../notifications/state/notification_providers.dart';

part 'widgets/shift_schedule_tile.dart';
part 'widgets/shift_schedule_editor.dart';
part 'widgets/shift_vacation_form_widgets.dart';
part 'widgets/shift_schedule_control_widgets.dart';
part 'widgets/shift_color_picker.dart';

class ShiftSchedulesScreen extends ConsumerWidget {
  const ShiftSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final schedules = ref.watch(shiftSchedulesControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppPageAppBar(
        fallbackLocation: '/settings',
        title: Text(
          strings.shiftSchedules,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      body: WarmGradientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    if (schedules.isEmpty)
                      AppEmptyState(
                        icon: Icons.work_history_rounded,
                        title: strings.noShiftSchedules,
                        actionLabel: strings.addShiftSchedule,
                        onAction: () => _openEditor(context, ref),
                      )
                    else
                      for (final schedule in schedules)
                        _ShiftScheduleTile(
                          schedule: schedule,
                          locale: locale,
                          onEdit: () => _openEditor(context, ref, schedule),
                          onToggle: () {
                            ref
                                .read(shiftSchedulesControllerProvider.notifier)
                                .toggleEnabled(schedule.id);
                          },
                          onDelete: () =>
                              _confirmDelete(context, ref, schedule.id),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.addShiftSchedule),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, [
    ShiftSchedule? schedule,
  ]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ShiftScheduleEditorSheet(schedule: schedule);
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.deleteShiftScheduleQuestion),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.delete),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      await ref.read(shiftSchedulesControllerProvider.notifier).delete(id);
    }
  }
}
