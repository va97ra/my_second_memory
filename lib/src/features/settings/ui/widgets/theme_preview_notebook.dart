import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'theme_preview_bar.dart';
import 'theme_preview_paper.dart';

/// Миниатюра блокнотной темы: стол, лист на нём и терракотовые полосы.
class ThemePreviewNotebook extends StatelessWidget {
  const ThemePreviewNotebook({super.key, required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final colors = dark
        ? const [Color(0xFF1C1512), Color(0xFF3A332C)]
        : const [Color(0xFFC98D57), Color(0xFFFFF0CD)];
    final ink = dark ? const Color(0xFFEDE6DA) : const Color(0xFF201712);
    final panelTexture =
        dark ? NotebookAssets.darkPaper : NotebookAssets.paper;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        image: DecorationImage(
          image: AssetImage(dark ? NotebookAssets.darkWood : NotebookAssets.wood),
          fit: BoxFit.cover,
          opacity: dark ? 0.9 : 0.75,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          children: [
            ThemePreviewPaper(
              color: colors.last,
              texture: panelTexture,
              ink: ink,
              height: 15,
              bordered: false,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: ThemePreviewPaper(
                color: colors.last,
                texture: panelTexture,
                ink: ink,
              ),
            ),
            const SizedBox(height: 6),
            const ThemePreviewBar(),
            const SizedBox(height: 6),
            Expanded(
              child: ThemePreviewPaper(
                color: colors.last,
                texture: panelTexture,
                ink: ink,
              ),
            ),
            const SizedBox(height: 6),
            const ThemePreviewBar(raised: true),
          ],
        ),
      ),
    );
  }
}
