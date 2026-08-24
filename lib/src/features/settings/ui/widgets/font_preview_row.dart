import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Строка выбора шрифта записей: имя и образец им набранный.
class FontPreviewRow extends StatelessWidget {
  const FontPreviewRow({
    super.key,
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
              if (selected)
                Icon(Icons.check_circle_rounded, color: colors.primary),
            ],
          ),
        ),
      ),
    );
    return NotebookPressable(onTap: onTap, child: row);
  }
}
