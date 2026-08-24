import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'memory_amount.dart';
import 'memory_editor_draft.dart';
import 'memory_editor_form.dart';

/// Поля ввода редактора: текст записи и сумма.
///
/// Ими владеет Flutter, поэтому они не в форме, а здесь — вместе со всем, что
/// нужно из них прочитать.
class MemoryEditorFields {
  final body = TextEditingController();
  final amount = TextEditingController();

  void loadFrom(MemoryItem item) {
    body.text = item.body;
    amount.text = formatAmount(item.amountMinor);
  }

  void clear() {
    body.clear();
    amount.clear();
  }

  void dispose() {
    body.dispose();
    amount.dispose();
  }

  /// Есть ли что сохранять. Пустая запись без вложений и суммы — ещё не
  /// запись.
  bool hasContent(MemoryEditorForm form) {
    return body.text.trim().isNotEmpty ||
        form.hasAttachments ||
        (form.type == MemoryType.payment &&
            parseAmountMinor(amount.text) != null);
  }

  MemoryEditorDraft buildDraft(
    MemoryEditorForm form, {
    required String locale,
  }) {
    return form.toDraft(
      title: memoryTitleFromRecord(body.text, form.type, locale),
      body: body.text.trim(),
      amountMinor: parseAmountMinor(amount.text),
      savedAt: DateTime.now(),
    );
  }
}
