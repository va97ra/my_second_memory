import 'package:flutter/material.dart';

import 'nav_bar_style.dart';

enum NavigationPanelEdge { top, bottom }

/// Shared material and safe-area surface for shell navigation panels.
class AppNavigationPanel extends StatelessWidget {
  const AppNavigationPanel({
    required this.edge,
    required this.child,
    super.key,
  });

  final NavigationPanelEdge edge;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = NavBarStyle.of(context);
    // Each panel owns its ink reactions. Their retained compositor surfaces
    // come from the separate Scaffold appBar and bottomNavigationBar slots.
    return DecoratedBox(
      decoration: style.decoration,
      child: style.wrap(
        Material(
          type: MaterialType.transparency,
          child: SafeArea(
            top: edge == NavigationPanelEdge.top,
            bottom: edge == NavigationPanelEdge.bottom,
            maintainBottomViewPadding: edge == NavigationPanelEdge.bottom,
            child: child,
          ),
        ),
      ),
    );
  }
}
