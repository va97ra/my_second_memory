import 'package:flutter/material.dart';

/// Кто сейчас переворачивает страницу.
///
/// Переворот один на всё приложение: два одновременных сняли бы снимки друг
/// друга и показали бы страницу, которой нет.
class PageTurnCoordinator extends ChangeNotifier {
  Object? _owner;

  bool get isBusy => _owner != null;

  bool tryAcquire(Object owner) {
    if (_owner != null) return false;
    _owner = owner;
    notifyListeners();
    return true;
  }

  void release(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    notifyListeners();
  }
}

class PageTurnCoordinatorScope extends InheritedNotifier<PageTurnCoordinator> {
  const PageTurnCoordinatorScope({
    required PageTurnCoordinator coordinator,
    required super.child,
    super.key,
  }) : super(notifier: coordinator);

  static PageTurnCoordinator? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PageTurnCoordinatorScope>()
        ?.notifier;
  }
}
