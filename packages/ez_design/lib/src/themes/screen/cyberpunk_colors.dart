import 'package:flutter/material.dart';

import 'screen_theme_colors.dart';

/// «Киберпанк»: синяя ночь, малиновый акцент и холодная бирюза по краям.
///
/// Малиновый здесь занимает место терракотового: им отмечены сегодня, выбранная
/// закладка и активная кнопка панели. Бирюза — цвет границ и рамок: она не
/// обозначает действие, а очерчивает то, на чём оно происходит.
const cyberpunkColors = ScreenThemeColors(
  brightness: Brightness.dark,
  panels: ScreenPanelStyle.edge,
  navIndicator: ScreenNavIndicator.underline,
  backgroundStart: Color(0xFF050B14),
  backgroundEnd: Color(0xFF0A1522),
  navigation: Color(0xFF07101B),
  panel: Color(0xFF0D1A28),
  raised: Color(0xFF12212F),
  nested: Color(0xFF17293A),
  tile: Color(0x8C101E2C),
  weekday: Color(0x8C0D1A28),
  border: Color(0xFF1F5C7A),
  divider: Color(0xFF163A4E),
  ink: Color(0xFFE8F6FF),
  mutedInk: Color(0xFF80A6BE),
  dimInk: Color(0xFF44637A),
  accent: Color(0xFFFF2E6A),
  accentDeep: Color(0xFFB8004A),
  onAccent: Color(0xFFFFFFFF),
  today: Color(0xFFFF2E6A),
  glow: Color(0xFFFF2E6A),
  glint: Color(0xFF7DE9FF),
  event: Color(0xFF1E7BFF),
  task: Color(0xFF9B4DFF),
  family: Color(0xFF22B8E8),
  purchase: Color(0xFF6A3DFF),
  shift: Color(0xFF00E0A0),
  holiday: Color(0xFFFF2050),
  toolTints: [
    Color(0xFFFF2D6F),
    Color(0xFF2B9DFF),
    Color(0xFF17E0C8),
  ],
  backdrop: 'assets/textures/cyberpunk_backdrop.webp',
);
