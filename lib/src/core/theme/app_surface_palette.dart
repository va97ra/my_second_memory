import 'package:flutter/material.dart';

@immutable
class AppSurfacePalette extends ThemeExtension<AppSurfacePalette> {
  const AppSurfacePalette({
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.navigationSurface,
    required this.panelSurface,
    required this.raisedSurface,
    required this.calendarTile,
    required this.weekdaySurface,
    required this.borderStart,
    required this.borderEnd,
    required this.accentStart,
    required this.accentEnd,
  });

  final Color backgroundStart;
  final Color backgroundEnd;
  final Color navigationSurface;
  final Color panelSurface;
  final Color raisedSurface;
  final Color calendarTile;
  final Color weekdaySurface;
  final Color borderStart;
  final Color borderEnd;
  final Color accentStart;
  final Color accentEnd;

  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [backgroundStart, backgroundEnd],
      );

  LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accentStart, accentEnd],
      );

  static AppSurfacePalette of(BuildContext context) {
    final theme = Theme.of(context);
    final configured = theme.extension<AppSurfacePalette>();
    if (configured != null) {
      return configured;
    }
    return theme.brightness == Brightness.dark
        ? const AppSurfacePalette(
            backgroundStart: Color(0xFF000000),
            backgroundEnd: Color(0xFF12100F),
            navigationSurface: Color(0xFF121311),
            panelSurface: Color(0xFF1A1C19),
            raisedSurface: Color(0xFF20231F),
            calendarTile: Color(0xFF242722),
            weekdaySurface: Color(0xFF171916),
            borderStart: Color(0xFF5C6257),
            borderEnd: Color(0xFF2A2D28),
            accentStart: Color(0xFFE47A57),
            accentEnd: Color(0xFFBF543B),
          )
        : const AppSurfacePalette(
            backgroundStart: Color(0xFFF4F1EB),
            backgroundEnd: Color(0xFFE9E4DB),
            navigationSurface: Color(0xFFFFFDF9),
            panelSurface: Color(0xFFFFFDF9),
            raisedSurface: Color(0xFFE6E1D8),
            calendarTile: Color(0xFFDAD7CF),
            weekdaySurface: Color(0xFFCBC8C0),
            borderStart: Color(0xFFA7A197),
            borderEnd: Color(0xFFD3CEC5),
            accentStart: Color(0xFFD87352),
            accentEnd: Color(0xFFB9553D),
          );
  }

  @override
  AppSurfacePalette copyWith({
    Color? backgroundStart,
    Color? backgroundEnd,
    Color? navigationSurface,
    Color? panelSurface,
    Color? raisedSurface,
    Color? calendarTile,
    Color? weekdaySurface,
    Color? borderStart,
    Color? borderEnd,
    Color? accentStart,
    Color? accentEnd,
  }) {
    return AppSurfacePalette(
      backgroundStart: backgroundStart ?? this.backgroundStart,
      backgroundEnd: backgroundEnd ?? this.backgroundEnd,
      navigationSurface: navigationSurface ?? this.navigationSurface,
      panelSurface: panelSurface ?? this.panelSurface,
      raisedSurface: raisedSurface ?? this.raisedSurface,
      calendarTile: calendarTile ?? this.calendarTile,
      weekdaySurface: weekdaySurface ?? this.weekdaySurface,
      borderStart: borderStart ?? this.borderStart,
      borderEnd: borderEnd ?? this.borderEnd,
      accentStart: accentStart ?? this.accentStart,
      accentEnd: accentEnd ?? this.accentEnd,
    );
  }

  @override
  AppSurfacePalette lerp(
    covariant AppSurfacePalette? other,
    double t,
  ) {
    if (other == null) {
      return this;
    }
    return AppSurfacePalette(
      backgroundStart: Color.lerp(backgroundStart, other.backgroundStart, t)!,
      backgroundEnd: Color.lerp(backgroundEnd, other.backgroundEnd, t)!,
      navigationSurface:
          Color.lerp(navigationSurface, other.navigationSurface, t)!,
      panelSurface: Color.lerp(panelSurface, other.panelSurface, t)!,
      raisedSurface: Color.lerp(raisedSurface, other.raisedSurface, t)!,
      calendarTile: Color.lerp(calendarTile, other.calendarTile, t)!,
      weekdaySurface: Color.lerp(weekdaySurface, other.weekdaySurface, t)!,
      borderStart: Color.lerp(borderStart, other.borderStart, t)!,
      borderEnd: Color.lerp(borderEnd, other.borderEnd, t)!,
      accentStart: Color.lerp(accentStart, other.accentStart, t)!,
      accentEnd: Color.lerp(accentEnd, other.accentEnd, t)!,
    );
  }
}
