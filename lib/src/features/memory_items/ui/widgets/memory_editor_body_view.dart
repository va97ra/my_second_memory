import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import '../../state/memory_editor_controller.dart';
import '../memory_editor_actions.dart';
import 'editor_body.dart';
import 'memory_editor_special_fields.dart';
import 'record_editor.dart';

/// Тело редактора: дата, вид записи, особые поля и само поле записи.
class MemoryEditorBodyView extends StatelessWidget {
  const MemoryEditorBodyView({
    super.key,
    required this.controller,
    required this.actions,
    required this.bodyController,
    required this.amountController,
    required this.item,
    required this.showHints,
  });

  final MemoryEditorController controller;
  final MemoryEditorActions actions;
  final TextEditingController bodyController;
  final TextEditingController amountController;

  /// Запись, которую правят, или null у ещё не сохранённого черновика.
  final MemoryItem? item;

  final bool showHints;

  @override
  Widget build(BuildContext context) {
    final form = controller.form;

    return EditorBody(
      isUndated: form.isUndated,
      specialFields: _specialFields(),
      showRecurrenceHint:
          !form.isUndated && showHints && form.recurrenceFrequency == null,
      onRecurrenceHintTap: actions.openRepeatPicker,
      recordEditor: RecordEditor(
        controller: bodyController,
        imagePaths: form.imagePaths,
        audioPath: form.audioPath,
        audioDurationSeconds: form.audioDurationSeconds,
        memoryDate: form.memoryDate,
        isRecording: controller.isRecording,
        recurrenceFrequency: form.recurrenceFrequency,
        onRecurrenceTap: actions.openRepeatPicker,
        onPickImage: actions.media.pickImage,
        onRemoveImage: (path) => controller.applyForm(
          (form) => form.copyWith(
            imagePaths: [
              for (final image in form.imagePaths)
                if (image != path) image,
            ],
          ),
        ),
        onRemoveAudio: () =>
            controller.applyForm((form) => form.copyWith(clearAudio: true)),
        onVoicePressed: controller.isRecording
            ? actions.media.stopAndSaveVoice
            : actions.media.startVoice,
        onChanged: controller.scheduleAutosave,
      ),
    );
  }

  /// Поля отдельных видов записи. У записки их не бывает.
  Widget? _specialFields() {
    final form = controller.form;
    if (form.isUndated || !MemoryEditorSpecialFields.supports(form.type)) {
      return null;
    }

    return MemoryEditorSpecialFields(
      form: form,
      amountController: amountController,
      // Срок подписки принадлежит серии, поэтому у одного её вхождения
      // его менять нечем: правка должна идти на всю серию.
      canEditSubscriptionTerm:
          form.recurrenceFrequency == RecurrenceFrequency.monthly &&
              (item?.seriesId == null ||
                  controller.editFutureOccurrences ||
                  controller.refreshNewSeriesTemplate),
      onCategoryChanged: (category) =>
          controller.applyForm((form) => form.withPaymentCategory(category)),
      onChanged: controller.scheduleAutosave,
      onSubscriptionTermTap: actions.pickSubscriptionTerm,
      onBirthYearTap: actions.pickBirthYear,
      onClearBirthYear: form.birthYear == null
          ? null
          : () => controller.applyForm(
                (form) => form.copyWith(clearBirthYear: true),
              ),
    );
  }
}
