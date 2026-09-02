import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'type_picker_row.dart';

/// Выбор вида записи отдельным листом.
///
/// Лист, а не поле в форме: вид выбирают один раз при создании и почти
/// никогда не меняют, а строку на экране поле занимало постоянно.
Future<MemoryType?> showMemoryTypePicker(
  BuildContext context, {
  required MemoryType selected,
}) {
  return showModalBottomSheet<MemoryType>(
    context: context,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) {
      final locale = Localizations.localeOf(context).languageCode;
      final strings = AppStrings.of(context);

      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(
                strings.recordType,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final type in editableMemoryTypes)
              TypePickerRow(
                type: type,
                label: type.label(locale),
                selected: type == selected,
                onTap: () => Navigator.of(context).pop(type),
              ),
          ],
        ),
      );
    },
  );
}
