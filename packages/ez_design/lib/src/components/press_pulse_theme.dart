import 'package:flutter/material.dart';

import 'press_pulse.dart';

/// Содержимое кнопки Material сжимается при нажатии. Кнопки сообщают нажатие сами,
/// поэтому эффект подключается темой, и новые кнопки получают его без правок.
Widget _pulseContent(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) =>
    PressPulse(
      pressed: states.contains(WidgetState.pressed),
      child: child ?? const SizedBox.shrink(),
    );

ButtonStyle _withPulse(ButtonStyle? style) =>
    (style ?? const ButtonStyle()).copyWith(foregroundBuilder: _pulseContent);

/// Тема, в которой кнопки отвечают на палец сжатием.
ThemeData withPressPulse(ThemeData theme) => theme.copyWith(
      filledButtonTheme: FilledButtonThemeData(
        style: _withPulse(theme.filledButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _withPulse(theme.outlinedButtonTheme.style),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _withPulse(theme.textButtonTheme.style),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _withPulse(theme.elevatedButtonTheme.style),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: _withPulse(theme.iconButtonTheme.style),
      ),
    );
