import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/page_turn_navigation.dart';
import '../../accounts/accounts.dart' show accountCardColumns;
import '../../../shared/ui/memory_card/even_wrap.dart';
import '../../../shared/ui/memory_card/sticker_paper.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../state/shift_schedules_controller.dart';
import 'widgets/shift_schedule_tile.dart';

/// Список графиков смен. Редактор открывается своим окном.
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
        hint: strings.shiftsPageHint,
        title: Text(strings.shiftSchedules),
        actions: [
          IconButton(
            key: const ValueKey('shift_schedule_add'),
            tooltip: strings.addShiftSchedule,
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add_rounded, size: 22),
            style: notebookIconButtonStyle(),
          ),
        ],
      ),
      body: WarmGradientBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            StickerPaper.gridEdge,
            12,
            StickerPaper.gridEdge,
            24,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: schedules.isEmpty
                    ? AppEmptyState(
                        icon: Icons.work_history_rounded,
                        title: strings.noShiftSchedules,
                        actionLabel: strings.addShiftSchedule,
                        onAction: () => _openEditor(context),
                      )
                    : EvenWrap(
                        columns: accountCardColumns,
                        itemHeight: ShiftScheduleTile.heightOf(context),
                        children: [
                          for (final schedule in schedules)
                            ShiftScheduleTile(
                              key: ValueKey(schedule.id),
                              scheduleId: schedule.id,
                              locale: locale,
                              onEdit: (edited) => _openEditor(context, edited),
                              onToggle: () => ref
                                  .read(
                                    shiftSchedulesControllerProvider.notifier,
                                  )
                                  .toggleEnabled(schedule.id),
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
    );
  }

  Future<void> _openEditor(BuildContext context, [ShiftSchedule? schedule]) {
    final path = schedule == null
        ? '/settings/shifts/new'
        : '/settings/shifts/item/${Uri.encodeComponent(schedule.id)}';
    return context.pageTurnPush(path);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );

    if (confirmed ?? false) {
      await ref.read(shiftSchedulesControllerProvider.notifier).delete(id);
    }
  }
}
