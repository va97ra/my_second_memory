import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

class ConverterSaveButton extends StatelessWidget {
  const ConverterSaveButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final screen = ScreenVisuals.maybeOf(context)?.colors;
    if (screen == null) {
      return FilledButton.icon(
        key: const ValueKey('converter_save'),
        onPressed: onPressed,
        icon: const Icon(Icons.bookmark_add_outlined),
        label: Text(label),
      );
    }
    return SizedBox(
      height: 48,
      child: ScreenGlassButton(
        key: const ValueKey('converter_save'),
        opacity: 0.58,
        tint: screen.accent,
        semanticLabel: label,
        onPressed: onPressed,
        painterKey: const ValueKey('converter_save_glass'),
        lampKey: const ValueKey('converter_save_lamp'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  Icons.bookmark_add_outlined,
                  color: screen.onAccent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: screen.onAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
