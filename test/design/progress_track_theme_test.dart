import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Дорожка полосы прогресса — то, что видно при нуле. Material берёт её из
/// `secondaryContainer`, если тема не задала свою.
Color _track(ThemeData theme) =>
    theme.progressIndicatorTheme.linearTrackColor ??
    theme.colorScheme.secondaryContainer;

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (la > lb ? la + 0.05 : lb + 0.05) / (la > lb ? lb + 0.05 : la + 0.05);
}

void main() {
  final themes = {
    'light notebook': buildNotebookTheme(brightness: Brightness.light),
    'dark notebook': buildNotebookTheme(brightness: Brightness.dark),
    'cosmos': buildScreenTheme(cosmosColors),
    'cyberpunk': buildScreenTheme(cyberpunkColors),
  };

  // Пустая полоса — желобок, едва отличимый от листа. Экранные темы держат в
  // `secondaryContainer` насыщенный цвет выбранного чипа, и в «Космосе»
  // «прошло 0 из 21» рисовалось сплошной синей полосой, как будто всё прошло.
  for (final MapEntry(key: name, value: theme) in themes.entries) {
    test('$name: an empty progress bar does not look filled', () {
      final surface = theme.colorScheme.surface;
      final track = Color.alphaBlend(_track(theme), surface);
      expect(_contrast(track, surface), lessThan(1.6));
    });
  }
}
