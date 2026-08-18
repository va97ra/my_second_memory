import 'package:flutter/material.dart';

import 'windows_desktop.dart';

class WindowsTrayFrame extends StatelessWidget {
  const WindowsTrayFrame({
    required this.child,
    this.enabled,
    super.key,
  });

  final Widget child;
  final bool? enabled;

  @override
  Widget build(BuildContext context) {
    if (!(enabled ?? windowsDesktopPlatform.isSupported)) return child;

    return DecoratedBox(
      key: const ValueKey('windows_tray_border'),
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: child,
    );
  }
}
