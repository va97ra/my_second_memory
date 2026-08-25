import 'package:flutter/material.dart';

/// Переход между ветками оболочки: у веток свой навигатор, и уйти в чужую
/// ветку можно только через того, кто держит их все.
class PageTurnBranchNavigationScope extends InheritedWidget {
  const PageTurnBranchNavigationScope({
    required this.onGo,
    required super.child,
    super.key,
  });

  final Future<bool> Function(String location) onGo;

  static PageTurnBranchNavigationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PageTurnBranchNavigationScope>();
  }

  @override
  bool updateShouldNotify(PageTurnBranchNavigationScope oldWidget) =>
      oldWidget.onGo != onGo;
}
