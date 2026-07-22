import 'package:flutter/material.dart';

import '../../../../core/theme/app_content_font.dart';
import '../../../../shared/ui/notebook_pressable.dart';

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
              _FontPreviewRow(
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

class _FontPreviewRow extends StatelessWidget {
  const _FontPreviewRow({
    required this.style,
    required this.selected,
    required this.phrase,
    required this.onTap,
  });

  final AppContentFontStyle style;
  final bool selected;
  final String phrase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final row = Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      phrase,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: style.family,
                        fontFamilyFallback: const ['Manrope'],
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: colors.primary),
            ],
          ),
        ),
      ),
    );
    return NotebookPressable(onTap: onTap, child: row);
  }
}
