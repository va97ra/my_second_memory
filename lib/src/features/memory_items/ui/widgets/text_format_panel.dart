import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/styled_text_controller.dart';
import 'text_color_picker.dart';
import 'text_format_glyphs.dart';
import 'text_format_pickers.dart';

/// Панель оформления выделенного текста — снизу, пока текст выделен.
///
/// Сверху остаётся системное «Копировать / Вставить / Выбрать всё», а здесь
/// — что сделать с выделенным: жирный, курсив, подчёркнутый, зачёркнутый,
/// цвет, размер, шрифт. Просьба из отзыва (11 октября 2026). Кнопки — сами
/// буквы в будущем виде: что нажимаешь, то и получаешь.
class TextFormatPanel extends StatelessWidget {
  const TextFormatPanel({super.key, required this.controller});

  final StyledTextController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final mark = controller.current;
    final colors = Theme.of(context).colorScheme;
    Widget toggle(TextMarkToggle what, String label, bool on, TextStyle look,
            String letters) =>
        FormatGlyphButton(
          key: ValueKey('format_${what.name}'),
          label: label,
          selected: on,
          onTap: () => controller.toggle(what),
          child: Text(letters, style: look),
        );
    final divider = Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colors.outlineVariant,
    );

    return Material(
      key: const ValueKey('text_format_panel'),
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          children: [
            toggle(TextMarkToggle.bold, strings.formatBold, mark.bold,
                const TextStyle(fontWeight: FontWeight.w900), 'Ж'),
            toggle(TextMarkToggle.italic, strings.formatItalic, mark.italic,
                const TextStyle(fontStyle: FontStyle.italic), 'К'),
            toggle(
                TextMarkToggle.underline,
                strings.formatUnderline,
                mark.underline,
                const TextStyle(
                    decoration: TextDecoration.underline,
                    decorationThickness: 2),
                'Ч'),
            toggle(
                TextMarkToggle.strike,
                strings.formatStrike,
                mark.strike,
                const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    decorationThickness: 2),
                'аб'),
            divider,
            FormatGlyphButton(
              key: const ValueKey('format_color'),
              label: strings.formatColor,
              onTap: () => pickTextColor(
                context,
                current: mark.color,
                onChanged: controller.setColor,
              ),
              child: ColorGlyph(color: mark.color),
            ),
            FormatGlyphButton(
              key: const ValueKey('format_size'),
              label: strings.formatSize,
              selected: mark.size != null,
              onTap: () async {
                final picked = await pickTextSize(context, mark.size);
                if (picked != null) controller.setSize(picked.size);
              },
              child: const SizeGlyph(),
            ),
            FormatGlyphButton(
              key: const ValueKey('format_font'),
              label: strings.formatFont,
              selected: mark.font != null,
              onTap: () async {
                final picked = await pickTextFont(context, mark.font);
                if (picked != null) controller.setFont(picked.font?.name);
              },
              child: FontGlyph(font: mark.font),
            ),
            divider,
            FormatGlyphButton(
              key: const ValueKey('format_clear'),
              label: strings.formatClear,
              onTap: controller.clearFormat,
              child: Icon(Icons.format_clear_rounded,
                  color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
