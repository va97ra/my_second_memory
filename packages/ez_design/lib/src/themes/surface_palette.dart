import 'package:flutter/material.dart';

@immutable
class AppSurfacePalette extends ThemeExtension<AppSurfacePalette> {
  const AppSurfacePalette({
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.navigationSurface,
    required this.panelSurface,
    required this.raisedSurface,
    required this.nestedSurface,
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
  final Color nestedSurface;
  final Color calendarTile;
  final Color weekdaySurface;
  final Color borderStart;
  final Color borderEnd;
  final Color accentStart;
  final Color accentEnd;

  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          backgroundStart,
          Color.lerp(backgroundStart, accentStart, 0.07)!,
          backgroundEnd,
        ],
        stops: const [0, 0.46, 1],
      );

  LinearGradient get accentGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(accentStart, Colors.white, 0.24)!,
          accentStart,
          accentEnd,
        ],
        stops: const [0, 0.34, 1],
      );

  LinearGradient surfaceGradient({Color? base}) {
    final surface = base ?? panelSurface;
    final isDark = surface.computeLuminance() < 0.28;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(
          surface,
          isDark ? Colors.white : accentStart,
          isDark ? 0.1 : 0.035,
        )!,
        surface,
        Color.lerp(
          surface,
          isDark ? Colors.black : borderEnd,
          isDark ? 0.16 : 0.09,
        )!,
      ],
      stops: const [0, 0.38, 1],
    );
  }

  LinearGradient get navigationGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(navigationSurface, Colors.white, 0.08)!,
          navigationSurface,
          Color.lerp(navigationSurface, Colors.black, 0.1)!,
        ],
        stops: const [0, 0.22, 1],
      );

  static AppSurfacePalette of(BuildContext context) {
    final theme = Theme.of(context);
    final configured = theme.extension<AppSurfacePalette>();
    if (configured != null) {
      return configured;
    }
    return theme.brightness == Brightness.dark
        ? const AppSurfacePalette(
            backgroundStart: Color(0xFF07090D),
            backgroundEnd: Color(0xFF151018),
            navigationSurface: Color(0xFF161C23),
            panelSurface: Color(0xFF1D252E),
            raisedSurface: Color(0xFF27333F),
            nestedSurface: Color(0xFF303E4B),
            calendarTile: Color(0xFF202A34),
            weekdaySurface: Color(0xFF2A3642),
            borderStart: Color(0xFF718397),
            borderEnd: Color(0xFF344351),
            accentStart: Color(0xFFFF6A3D),
            accentEnd: Color(0xFFC9361E),
          )
        : const AppSurfacePalette(
            backgroundStart: Color(0xFFF4F7F8),
            backgroundEnd: Color(0xFFDDE6EA),
            navigationSurface: Color(0xFFFCFEFF),
            panelSurface: Color(0xFFFFFFFF),
            raisedSurface: Color(0xFFE9F0F3),
            nestedSurface: Color(0xFFD8E3E8),
            calendarTile: Color(0xFFEDF2F4),
            weekdaySurface: Color(0xFFDCE7EB),
            borderStart: Color(0xFF6F8490),
            borderEnd: Color(0xFFBCCAD0),
            accentStart: Color(0xFFF05A30),
            accentEnd: Color(0xFFB72F1B),
          );
  }

  @override
  AppSurfacePalette copyWith({
    Color? backgroundStart,
    Color? backgroundEnd,
    Color? navigationSurface,
    Color? panelSurface,
    Color? raisedSurface,
    Color? nestedSurface,
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
      nestedSurface: nestedSurface ?? this.nestedSurface,
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
      nestedSurface: Color.lerp(nestedSurface, other.nestedSurface, t)!,
      calendarTile: Color.lerp(calendarTile, other.calendarTile, t)!,
      weekdaySurface: Color.lerp(weekdaySurface, other.weekdaySurface, t)!,
      borderStart: Color.lerp(borderStart, other.borderStart, t)!,
      borderEnd: Color.lerp(borderEnd, other.borderEnd, t)!,
      accentStart: Color.lerp(accentStart, other.accentStart, t)!,
      accentEnd: Color.lerp(accentEnd, other.accentEnd, t)!,
    );
  }
}
