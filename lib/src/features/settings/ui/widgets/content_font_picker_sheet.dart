import 'package:flutter/material.dart';

import 'font_preview_row.dart';

import 'package:ez_design/ez_design.dart';

Future<AppContentFontStyle?> showContentFontPickerSheet({
  required BuildContext context,
  required AppContentFontStyle selected,
  required bool isRu,
}) {
  return showModalBottomSheet<AppContentFontStyle>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isRu ? 'Шрифт записей' : 'Record font',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final style in AppContentFontStyle.values) ...[
              FontPreviewRow(
                style: style,
                selected: style == selected,
                phrase:
                    isRu ? 'Ёжик, заметка на 22 июля' : 'A note for 22 July',
                onTap: () => Navigator.of(context).pop(style),
              ),
              if (style != AppContentFontStyle.values.last)
                const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    ),
  );
}
