import 'dart:async';

import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

abstract interface class _PageTurnBackController {
  Future<void> pop<T>(T? result);

  Future<void> prepareForRouteReplacement();

  void restoreBackHandling();
}

class _PageTurnBackMarker extends InheritedWidget {
  const _PageTurnBackMarker({
    required this.controller,
    required super.child,
  });

  final _PageTurnBackController controller;

  static _PageTurnBackController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_PageTurnBackMarker>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(_PageTurnBackMarker oldWidget) =>
      oldWidget.controller != controller;
}

/// Makes both the app bar back button and Android's system back command use
/// the same non-interactive returning-page animation.
class PageTurnBackScope extends StatefulWidget {
  const PageTurnBackScope({
    required this.child,
    this.fallbackLocation,
    super.key,
  });

  final Widget child;
  final String? fallbackLocation;

  @override
  State<PageTurnBackScope> createState() => _PageTurnBackScopeState();
}

class _PageTurnBackScopeState extends State<PageTurnBackScope>
    implements _PageTurnBackController {
  bool _allowPop = false;
  bool _handlingPop = false;

  @override
  Future<void> prepareForRouteReplacement() async {
    if (_allowPop || !mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
  }

  @override
  void restoreBackHandling() {
    if (!mounted || _handlingPop || !_allowPop) return;
    setState(() => _allowPop = false);
  }

  @override
  Future<void> pop<T>(T? result) async {
    final navigatorCanPop = Navigator.of(context).canPop();
    if (_handlingPop ||
        !mounted ||
        (!navigatorCanPop && widget.fallbackLocation == null)) {
      return;
    }
    _handlingPop = true;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final frame = PageTurnNavigationScope.maybeOf(context);
    if (frame == null) {
      if (navigatorCanPop) {
        context.pop<T>(result);
      } else {
        context.go(widget.fallbackLocation!);
      }
      return;
    }

    final started = await frame.beginTurn(
      direction: PageTurnDirection.backward,
      switchContent: () {
        if (navigatorCanPop) {
          context.pop<T>(result);
        } else {
          context.go(widget.fallbackLocation!);
        }
      },
    );
    if (!started && mounted) {
      setState(() {
        _allowPop = false;
        _handlingPop = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final navigatorCanPop = Navigator.of(context).canPop();
    final markedChild = _PageTurnBackMarker(
      controller: this,
      child: widget.child,
    );
    if (!navigatorCanPop && widget.fallbackLocation != null) {
      return BackButtonListener(
        onBackButtonPressed: () async {
          await pop<Object?>(null);
          return true;
        },
        child: markedChild,
      );
    }
    return PopScope<Object?>(
      canPop: !navigatorCanPop || _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && navigatorCanPop) unawaited(pop(result));
      },
      child: markedChild,
    );
  }
}

extension PageTurnNavigationBuildContext on BuildContext {
  Future<void> pageTurnGo(
    String location, {
    Object? extra,
    PageTurnDirection direction = PageTurnDirection.forward,
  }) async {
    final backController = _PageTurnBackMarker.maybeOf(this);
    await backController?.prepareForRouteReplacement();
    if (!mounted) return;

    final frame = PageTurnNavigationScope.maybeOf(this);
    if (frame == null) {
      go(location, extra: extra);
      return;
    }
    final started = await frame.beginTurn(
      direction: direction,
      switchContent: () => go(location, extra: extra),
    );
    if (!started) backController?.restoreBackHandling();
  }

  Future<T?> pageTurnPush<T extends Object?>(
    String location, {
    Object? extra,
  }) async {
    final frame = PageTurnNavigationScope.maybeOf(this);
    if (frame == null) return push<T>(location, extra: extra);

    late Future<T?> result;
    final started = await frame.beginTurn(
      direction: PageTurnDirection.forward,
      switchContent: () {
        result = push<T>(location, extra: extra);
      },
    );
    if (!started) return null;
    return result;
  }

  Future<void> pageTurnPop<T extends Object?>([T? result]) async {
    final backController = _PageTurnBackMarker.maybeOf(this);
    if (backController != null) {
      await backController.pop(result);
      return;
    }

    final frame = PageTurnNavigationScope.maybeOf(this);
    if (frame == null) {
      pop<T>(result);
      return;
    }
    await frame.beginTurn(
      direction: PageTurnDirection.backward,
      switchContent: () => pop<T>(result),
    );
  }
}
