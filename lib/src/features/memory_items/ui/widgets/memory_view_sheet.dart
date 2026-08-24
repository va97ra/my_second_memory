import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'memory_view_body.dart';
import 'memory_view_header.dart';

/// Лист, на котором показывают запись: бумага темы, шапка и содержимое.
class MemoryViewSheet extends StatelessWidget {
  const MemoryViewSheet({super.key, required this.item});

  final MemoryItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('memory_readonly_view'),
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SizedBox(
                key: const ValueKey('memory_readonly_panel'),
                width: double.infinity,
                height: constraints.maxHeight - 18,
                child: DecoratedBox(
                  decoration: _paper(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MemoryViewHeader(item: item),
                      const Divider(),
                      Expanded(child: MemoryViewBody(item: item)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Бумага блокнотной темы, текстура обычной или ровный цвет, если у темы нет
  /// ни того, ни другого.
  BoxDecoration _paper(BuildContext context) {
    final notebook = NotebookVisuals.maybeOf(context);
    final textures = AppSurfaceTextures.maybeOf(context);
    final palette = AppSurfacePalette.of(context);
    final colors = Theme.of(context).colorScheme;

    return BoxDecoration(
      color: textures == null
          ? notebook?.paper ?? colors.surface.withValues(alpha: 0.97)
          : null,
      gradient: textures == null ? null : palette.surfaceGradient(),
      image: notebook != null
          ? DecorationImage(
              image: AssetImage(notebook.paperAsset),
              fit: BoxFit.cover,
              opacity: 0.62,
            )
          : textures == null
              ? null
              : DecorationImage(
                  image: AssetImage(textures.surfaceAsset),
                  fit: BoxFit.cover,
                  opacity: textures.surfaceOpacity,
                  filterQuality: FilterQuality.low,
                ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: colors.outlineVariant),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6B4F35).withValues(alpha: 0.09),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
