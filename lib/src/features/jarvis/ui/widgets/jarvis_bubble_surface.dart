import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Подложка реплики: карточка бумаги в блокноте и стекло в экранных темах —
/// как у сводки финансов и табло калькулятора, чтобы разговор не выбивался
/// из остальных страниц.
///
/// Реплика человека окрашена акцентом темы: так в ленте разговора с одного
/// взгляда видно, кто что сказал.
class JarvisBubbleSurface extends StatelessWidget {
  const JarvisBubbleSurface({
    required this.child,
    this.fromPerson = false,
    super.key,
  });

  final Widget child;
  final bool fromPerson;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screen = ScreenVisuals.maybeOf(context)?.colors;
    if (screen == null) {
      return Card(
        margin: EdgeInsets.zero,
        color: fromPerson ? scheme.primaryContainer : null,
        child: child,
      );
    }
    return ScreenGlassSurface(
      colors: screen,
      opacity: screen.isDark ? 0.36 : 0.22,
      tint: fromPerson ? scheme.primary : null,
      child: child,
    );
  }
}
