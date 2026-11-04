import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Цветная полоса квадратной карточки: мелкая подпись слева и, если есть, справа.
class StickerStrip extends StatelessWidget {
  const StickerStrip({
    super.key,
    required this.accent,
    required this.label,
    this.trailingLabel,
  });

  final Color accent;
  final String label;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: readableInkOn(accent),
      fontSize: 8.5,
      fontWeight: FontWeight.w800,
      height: 1,
    );

    return ColoredBox(
      color: accent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _Fitted(
                alignment: Alignment.centerLeft,
                text: label,
                style: style,
              ),
            ),
            if (trailingLabel case final trailing?) ...[
              const SizedBox(width: 3),
              Expanded(
                flex: 2,
                child: _Fitted(
                  alignment: Alignment.centerRight,
                  text: trailing,
                  style: style,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Подпись ужимается целиком, а не обрывается многоточием.
class _Fitted extends StatelessWidget {
  const _Fitted({
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
