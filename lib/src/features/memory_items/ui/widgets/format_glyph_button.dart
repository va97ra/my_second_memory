import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Кнопка панели оформления: вместо значка — сама буква в том виде, какой
/// она станет. Так кнопки читаются, как в Word: **Ж**, *К*, Ч, ~~аб~~.
class FormatGlyphButton extends StatelessWidget {
  const FormatGlyphButton({
    required this.label,
    required this.onTap,
    required this.child,
    this.selected = false,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  /// Оформление уже есть у выделенного — кнопка подсвечена.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const radius = BorderRadius.all(Radius.circular(10));
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: NotebookPressable(
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.primaryContainer : Colors.transparent,
              borderRadius: radius,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: 21,
                height: 1,
                color: selected ? colors.onPrimaryContainer : colors.onSurface,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
