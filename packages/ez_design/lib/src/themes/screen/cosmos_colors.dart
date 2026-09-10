import 'package:flutter/material.dart';

import 'screen_theme_colors.dart';

/// «Космос»: светлое небо, белые панели матового стекла и тёплый оранжевый
/// акцент.
///
/// Тема светлая нарочно. Тёмный «Космос» был почти неотличим от «Киберпанка»:
/// две тёмные темы с холодными панелями различались только оттенком неона, и
/// выбирать было не из чего.
///
/// Сегодняшний день здесь розовый, а не оранжевый: оранжевым отмечено то, что
/// выбрал человек — открытый раздел в панели, — и путать эти две приметы
/// нельзя.
const cosmosColors = ScreenThemeColors(
  brightness: Brightness.light,
  panels: ScreenPanelStyle.floating,
  backgroundStart: Color(0xFFD8E5F8),
  backgroundEnd: Color(0xFFEAF0FC),
  navigation: Color(0xF2FFFFFF),
  panel: Color(0xF7FFFFFF),
  raised: Color(0xFFF3F8FF),
  nested: Color(0xFFE7EFFC),
  tile: Color(0xFFF8FBFF),
  weekday: Color(0xF2FFFFFF),
  border: Color(0xFFC9D8EE),
  divider: Color(0xFFDDE7F6),
  ink: Color(0xFF1B2A45),
  mutedInk: Color(0xFF64748B),
  dimInk: Color(0xFFAAB8CC),
  accent: Color(0xFFF4643C),
  accentDeep: Color(0xFFD1441F),
  onAccent: Color(0xFFFFFFFF),
  today: Color(0xFFEE4FA6),
  glow: Color(0xFFEE4FA6),
  event: Color(0xFF2B7FFF),
  task: Color(0xFF7C5CFF),
  family: Color(0xFF00A6A6),
  purchase: Color(0xFF2B7FFF),
  shift: Color(0xFF19C7A6),
  holiday: Color(0xFFF0564A),
  toolTints: [
    Color(0xFF4A6FA5),
    Color(0xFF2B7FFF),
    Color(0xFF32456B),
  ],
  backdrop: 'assets/textures/cosmos_backdrop.webp',
);
