import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Раздел настроек: подпись и карточка со строками под ней.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLabeledDivider(
          label: title,
          padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
        ),
        // В экранных темах карточка раздела — пластина стекла, как панели и
        // плитки дней; в блокнотных остаётся бумажной со своей тенью.
        DecoratedBox(
          decoration: GlassSurface.maybeOf(context, radius: radius) ??
              BoxDecoration(
                color: colors.surface,
                borderRadius: radius,
                border: Border.all(color: colors.outlineVariant),
                boxShadow: notebookSurfaceShadow(
                  context,
                  NotebookSurfaceDepth.card,
                ),
              ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    if (index > 0)
                      Divider(
                        height: 1,
                        indent: 64,
                        color: colors.outlineVariant,
                      ),
                    children[index],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
