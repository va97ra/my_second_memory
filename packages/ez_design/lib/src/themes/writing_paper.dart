import 'package:flutter/material.dart';

import '../tokens/app_palette.dart';
import '../tokens/app_textures.dart';
import 'paper_sheet.dart';

/// Лист, на котором пишут: бумага с зерном поверх любой темы. Кожа — это обложка, а
/// текст записывают на бумаге, поэтому в редакторе лист один во всех темах.
class WritingPaper extends StatelessWidget {
  const WritingPaper({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PaperSheet(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppPalette.writingPaper,
          image: const DecorationImage(
            image: AssetImage(AppTextures.writingSheet),
            fit: BoxFit.cover,
            opacity: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppPalette.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
