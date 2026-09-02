import 'package:flutter/material.dart';

import 'theme_preview.dart';

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
              Row(
                children: [
                  for (final style in AppThemeStyle.values) ...[
                    Expanded(
                      child: ThemePreview(
                        style: style,
                        selected: style == selected,
                        label: switch (style) {
                          AppThemeStyle.notebookLight =>
                            isRu ? 'Светлый' : 'Light',
                          AppThemeStyle.notebookDark =>
                            isRu ? 'Тёмный' : 'Dark',
                        },
                        onTap: () => Navigator.of(context).pop(style),
                      ),
                    ),
                    if (style != AppThemeStyle.values.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
