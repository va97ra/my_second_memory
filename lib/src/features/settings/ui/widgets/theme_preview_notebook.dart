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
        ? const [AppPalette.black, AppPalette.blackRaised]
        : const [AppPalette.silverDeep, AppPalette.silverPale];
    final ink = dark ? AppPalette.onBlack : AppPalette.paperInk;
    final panelTexture =
        dark ? NotebookAssets.darkPaper : NotebookAssets.lightPage;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        image: DecorationImage(
          image: AssetImage(dark ? NotebookAssets.darkLeather : NotebookAssets.lightLeather),
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
