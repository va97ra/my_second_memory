import 'package:flutter/material.dart';

/// Подпись ужимается целиком, а не обрывается многоточием.
class StickerStripLabel extends StatelessWidget {
  const StickerStripLabel({
    super.key,
    required this.alignment,
    required this.text,
    required this.style,
  });

  final Alignment alignment;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(text, maxLines: 1, style: style),
      );
}
