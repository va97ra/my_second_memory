import 'package:flutter/material.dart';

import 'theme_preview.dart';
import 'theme_style_label.dart';

import 'package:ez_design/ez_design.dart';

Future<AppThemeStyle?> showThemePickerSheet({
  required BuildContext context,
  required AppThemeStyle selected,
  required bool isRu,
}) {
  return showModalBottomSheet<AppThemeStyle>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isRu ? 'Оформление' : 'Appearance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              // Образцы стоят рядом, пока их помещается три; четвёртая тема
              // ломает ряд на телефоне — четыре колонки по 76 пикселей уже
              // не образец, а полоска. Тогда они встают сеткой два на два.
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final columns = AppThemeStyle.values.length <= 3
                      ? AppThemeStyle.values.length
                      : 2;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: 12,
                    children: [
                      for (final style in AppThemeStyle.values)
                        SizedBox(
                          width: width,
                          child: ThemePreview(
                            style: style,
                            selected: style == selected,
                            label: themeStyleLabel(style, isRu: isRu),
                            onTap: () => Navigator.of(context).pop(style),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
