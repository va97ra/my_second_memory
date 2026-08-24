import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Само поле записи: текст по линейке блокнота.
///
/// Линейку рисует тема; там, где её нет, поле остаётся обычным, залитым.
class RecordEditorField extends StatelessWidget {
  const RecordEditorField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final notebook = NotebookVisuals.maybeOf(context);
    final textures = AppSurfaceTextures.maybeOf(context);
    final plain = notebook == null && textures == null;
    final typography = AppContentTypography.of(context);
    final textStyle = typography.apply(
      Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
      manropeWeight: FontWeight.w600,
    );
    final lineHeight = typography.measuredLineHeight(textStyle);

    return CustomPaint(
      painter: plain
          ? null
          : NotebookPaperLinesPainter(
              color: notebook?.line ?? textures!.lineColor,
              // Первая линейка подчёркивает первую строку текста, а плавающая
              // подпись поля стоит над ней.
              top: lineHeight + 10,
              lineHeight: lineHeight,
            ),
      child: TextFormField(
        key: const ValueKey('record_editor_text'),
        controller: controller,
        expands: true,
        maxLines: null,
        minLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textAlignVertical: TextAlignVertical.top,
        scrollPadding: const EdgeInsets.only(bottom: 120),
        style: textStyle,
        decoration: InputDecoration(
          labelText: AppStrings.of(context).description,
          alignLabelWithHint: true,
          labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          filled: plain,
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}
