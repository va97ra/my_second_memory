import 'dart:math' as math;

import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/memory_card/even_wrap.dart';

/// Сколько плиток настроек в ряду: на телефоне две, при крупном шрифте одна.
int settingsTileColumns(double width, double textScale) =>
    math.max(1, width / textScale ~/ 140);

/// Раздел настроек: подпись, если их на экране несколько, и плитки под ней.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.children,
    this.title,
  });

  /// Плитка одной высоты, сколько бы строк ни было в подписи: ряды ровные.
  static const _tileHeight = 92.0;

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final height = scaler.scale(_tileHeight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title case final label?)
          AppLabeledDivider(
            label: label,
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
          ),
        EvenWrap(
          columns: (width) => settingsTileColumns(width, scaler.scale(1)),
          itemHeight: height,
          children: children,
        ),
      ],
    );
  }
}
