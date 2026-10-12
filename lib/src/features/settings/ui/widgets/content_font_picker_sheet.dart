import 'package:flutter/material.dart';

import 'font_preview_row.dart';

import 'package:ez_design/ez_design.dart';

/// Выбор шрифта записей. Шрифтов полтора десятка: заголовок стоит на месте,
/// а список под ним листается — колонка без прокрутки уходила за край
/// листа, и нижние шрифты было не выбрать.
Future<AppContentFontStyle?> showContentFontPickerSheet({
  required BuildContext context,
  required AppContentFontStyle selected,
  required bool isRu,
}) {
  const styles = AppContentFontStyle.values;
  return showModalBottomSheet<AppContentFontStyle>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
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
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: styles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) => FontPreviewRow(
                    style: styles[index],
                    selected: styles[index] == selected,
                    phrase: isRu
                        ? 'Ёжик, заметка на 22 июля'
                        : 'A note for 22 July',
                    onTap: () => Navigator.of(context).pop(styles[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
