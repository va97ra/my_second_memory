import 'package:flutter/material.dart';

import 'screen_theme_colors.dart';

/// «Космос»: почти чёрный фон с тёплым свечением из верхнего угла, холодные
/// панели и терракотовый акцент — тот же, что у блокнота, чтобы приложение
/// оставалось узнаваемым при переключении темы.
const cosmosColors = ScreenThemeColors(
  backgroundStart: Color(0xFF0A0D13),
  backgroundEnd: Color(0xFF11151E),
  navigation: Color(0xFF10141C),
  panel: Color(0xFF161B25),
  raised: Color(0xFF1C2230),
  nested: Color(0xFF232B3A),
  tile: Color(0xFF141922),
  weekday: Color(0xFF161B25),
  border: Color(0xFF2A3242),
  divider: Color(0xFF222938),
  ink: Color(0xFFF1F4F8),
  mutedInk: Color(0xFF8B95A6),
  dimInk: Color(0xFF4A5364),
  accent: Color(0xFFF4552E),
  accentDeep: Color(0xFFC0361A),
  onAccent: Color(0xFFFFFFFF),
  glow: Color(0xFFF4552E),
  event: Color(0xFF1F6FE0),
  task: Color(0xFF7A2E2A),
  family: Color(0xFF6E3A2A),
  purchase: Color(0xFF2F5AA8),
  shift: Color(0xFF1E7A5A),
  holiday: Color(0xFFE0392C),
);
