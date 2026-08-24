import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Карточка экрана замка.
class SecurityCard extends StatelessWidget {
  const SecurityCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: _shadow(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }

  /// Тень блокнотной темы, если она есть; иначе — своя, мягкая.
  List<BoxShadow> _shadow(BuildContext context) {
    final notebook = notebookSurfaceShadow(context, NotebookSurfaceDepth.panel);
    if (notebook.isNotEmpty) return notebook;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
    ];
  }
}
