import 'dart:async';
import 'dart:math' as math;

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'windows_desktop.dart';
import 'windows_tray_window_bounds.dart';

/// Окно на Windows — телефон: экран приложения в корпусе.
///
/// Корпус нарисован здесь, а не взят картинкой: он свой, без чужой марки, и
/// подстраивается под окно, если рабочий стол меньше телефона. Системного
/// заголовка у окна нет, поэтому корпус — и ручка перетаскивания, и место
/// для кнопок «свернуть» и «закрыть». Всё вне корпуса прозрачно.
class WindowsPhoneFrame extends StatelessWidget {
  const WindowsPhoneFrame({
    required this.child,
    this.enabled,
    this.platform,
    super.key,
  });

  final Widget child;

  /// Рисовать ли корпус; по умолчанию — только в окне Windows.
  final bool? enabled;

  /// Окно, которым управляют кнопки корпуса; по умолчанию — настоящее.
  final WindowsDesktopPlatform? platform;

  /// Где экран внутри окна.
  static const screenInsets = EdgeInsets.fromLTRB(
    windowsPhoneBezelSide,
    windowsPhoneBezelTop,
    windowsPhoneBezelSide + windowsPhoneSideButtonsOutset,
    windowsPhoneBezelBottom,
  );

  static const screenRadius = 34.0;

  /// Приложение в своём окне на Windows. Нужны оба признака: окно умеет
  /// только Windows-сборка (в браузере на Windows его нет), а внешний вид
  /// решает целевая платформа — в тестах она телефонная, на какой бы машине
  /// их ни гоняли, и экраны проверяются без корпуса.
  static bool get isWindowsWindow =>
      windowsDesktopPlatform.isSupported &&
      defaultTargetPlatform == TargetPlatform.windows;

  @override
  Widget build(BuildContext context) {
    if (!(enabled ?? isWindowsWindow)) return child;

    final window = platform ?? windowsDesktopPlatform;
    final strings = AppStrings.of(context);
    final media = MediaQuery.of(context);
    final screen = Size(
      math.max(0, media.size.width - screenInsets.horizontal),
      math.max(0, media.size.height - screenInsets.vertical),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('windows_phone_body'),
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => unawaited(window.startWindowDrag()),
            child: const CustomPaint(painter: _PhoneBodyPainter()),
          ),
        ),
        Positioned(
          left: screenInsets.left,
          top: screenInsets.top,
          width: screen.width,
          height: screen.height,
          // Приложение видит экран телефона, а не окно с корпусом: от размера
          // экрана считаются раскладки и доли листов.
          child: MediaQuery(
            data: media.copyWith(size: screen),
            child: ClipRRect(
              key: const ValueKey('windows_phone_screen'),
              borderRadius: BorderRadius.circular(screenRadius),
              child: child,
            ),
          ),
        ),
        // Кнопки окна — вместе справа, как привыкли в Windows, и на прямом
        // участке рамки: в скруглении угла они висели бы на дуге.
        Positioned(
          right: windowsPhoneSideButtonsOutset + _PhoneBodyPainter.bodyRadius,
          top: 0,
          height: screenInsets.top,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FrameButton(
                key: const ValueKey('windows_phone_minimize'),
                icon: Icons.remove_rounded,
                label: strings.windowMinimize,
                onTap: () => unawaited(window.minimizeWindow()),
              ),
              const SizedBox(width: 4),
              _FrameButton(
                key: const ValueKey('windows_phone_close'),
                icon: Icons.close_rounded,
                label: strings.windowClose,
                onTap: () => unawaited(window.closeWindow()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Кнопка окна в верхней рамке: едва заметна, пока к ней не подвели мышь.
class _FrameButton extends StatefulWidget {
  const _FrameButton({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_FrameButton> createState() => _FrameButtonState();
}

class _FrameButtonState extends State<_FrameButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: widget.label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: NotebookPressable(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(11),
            child: SizedBox.square(
              dimension: 22,
              child: Icon(
                widget.icon,
                size: 14,
                color: _hovered
                    ? const Color(0xFFD2D4DA)
                    : const Color(0xFF6E7078),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Корпус: графитовый, со светлой кромкой, тёмным стеклом вокруг экрана,
/// камерой в верхней рамке и кнопками питания и громкости справа.
class _PhoneBodyPainter extends CustomPainter {
  const _PhoneBodyPainter();

  static const bodyRadius = 46.0;
  static const _body = Color(0xFF222328);
  static const _edge = Color(0xFF4E5058);
  static const _glass = Color(0xFF0C0C0E);
  static const _sideButton = Color(0xFF34363C);

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromLTWH(
      0,
      0,
      math.max(0, size.width - windowsPhoneSideButtonsOutset),
      size.height,
    );
    if (body.isEmpty) return;

    final buttons = Paint()..color = _sideButton;
    for (final (top, length) in const [(150.0, 60.0), (240.0, 100.0)]) {
      if (top + length > body.height) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              body.right - 2, top, 2 + windowsPhoneSideButtonsOutset, length),
          const Radius.circular(2),
        ),
        buttons,
      );
    }

    final outer = RRect.fromRectAndRadius(
      body,
      const Radius.circular(bodyRadius),
    );
    canvas.drawRRect(outer, Paint()..color = _body);
    canvas.drawRRect(
      outer.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _edge,
    );
    canvas.drawRRect(outer.deflate(4), Paint()..color = _glass);

    // На одной линии с кнопками окна: обе по середине верхней рамки.
    final camera = Offset(body.center.dx, windowsPhoneBezelTop / 2);
    canvas.drawCircle(camera, 5, Paint()..color = const Color(0xFF1A1C22));
    canvas.drawCircle(camera, 2.4, Paint()..color = const Color(0xFF28344E));
  }

  @override
  bool shouldRepaint(_PhoneBodyPainter oldDelegate) => false;
}
