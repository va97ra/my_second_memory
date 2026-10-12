import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

/// Выбор размера; null — выбор отменили.
Future<({TextSize? size})?> pickTextSize(
    BuildContext context, TextSize? current) {
  final strings = AppStrings.of(context);
  final options = <(TextSize?, String)>[
    (TextSize.small, strings.formatSmall),
    (null, strings.formatNormal),
    (TextSize.large, strings.formatLarge),
    (TextSize.huge, strings.formatHuge),
  ];
  return showModalBottomSheet<({TextSize? size})>(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (size, label) in options)
            ListTile(
              key: ValueKey('format_size_${size?.name ?? 'normal'}'),
              selected: size == current,
              title: Text(
                label,
                style: TextStyle(fontSize: 16 * (size?.scale ?? 1)),
              ),
              onTap: () => Navigator.of(sheet).pop((size: size)),
            ),
        ],
      ),
    ),
  );
}

/// Выбор шрифта — из того же списка, что и шрифт записей в настройках;
/// null — выбор отменили, `font: null` — шрифт записи.
Future<({AppContentFontStyle? font})?> pickTextFont(
  BuildContext context,
  String? current,
) {
  final strings = AppStrings.of(context);
  return showModalBottomSheet<({AppContentFontStyle? font})>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheet).height * 0.7,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              key: const ValueKey('format_font_default'),
              selected: current == null,
              title: Text(strings.formatDefault),
              onTap: () => Navigator.of(sheet).pop((font: null)),
            ),
            for (final font in AppContentFontStyle.values)
              ListTile(
                key: ValueKey('format_font_${font.name}'),
                selected: font.name == current,
                title: Text(
                  font.label,
                  style: TextStyle(fontFamily: font.family, fontSize: 18),
                ),
                subtitle: Text(
                  'Съешь ещё этих мягких французских булок',
                  style: TextStyle(fontFamily: font.family),
                ),
                onTap: () => Navigator.of(sheet).pop((font: font)),
              ),
          ],
        ),
      ),
    ),
  );
}
