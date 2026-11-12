import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../navigation/page_turn_navigation.dart';
import '../../../shared/ui/memory_card/sticker_paper.dart';
import '../../../shared/ui/screen_chrome.dart';
import '../state/shift_editor_draft.dart';
import '../state/shift_schedules_controller.dart';
import 'widgets/shift_editor_cards.dart';

/// Окно создания и правки графика. Сверху полоса с названием, ниже каждая
/// настройка на своей карточке: нажатие открывает её.
///
/// Получает идентификатор и читает график сам.
class ShiftScheduleEditorScreen extends ConsumerStatefulWidget {
  const ShiftScheduleEditorScreen({super.key, this.scheduleId});

  final String? scheduleId;

  @override
  ConsumerState<ShiftScheduleEditorScreen> createState() =>
      _ShiftScheduleEditorScreenState();
}

class _ShiftScheduleEditorScreenState
    extends ConsumerState<ShiftScheduleEditorScreen> {
  late final ShiftSchedule? _schedule;
  late final ShiftEditorDraft _draft;

  @override
  void initState() {
    super.initState();
    final id = widget.scheduleId;
    _schedule = id == null ? null : ref.read(shiftScheduleByIdProvider(id));
    _draft = ShiftEditorDraft(_schedule);
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      body: WarmGradientBackground(
        child: Column(
          children: [
            MainPageHeader(
              title: _schedule == null
                  ? strings.addShiftSchedule
                  : strings.editShiftSchedule,
              backLocation: '/settings/shifts',
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  StickerPaper.gridEdge,
                  4,
                  StickerPaper.gridEdge,
                  12,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListenableBuilder(
                      listenable: _draft.updates,
                      builder: (context, _) => ShiftEditorCards(draft: _draft),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(strings.save),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final schedule = _draft.toSchedule(_schedule?.id);
    if (schedule == null) return;

    final controller = ref.read(shiftSchedulesControllerProvider.notifier);
    if (_schedule == null) {
      await controller.add(schedule);
    } else {
      await controller.update(schedule);
    }
    if (mounted) await context.pageTurnPop();
  }
}
