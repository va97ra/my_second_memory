import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Page<void> pageTurnPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final useFastTransition = _useFastTransition(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: useFastTransition
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 260),
    reverseTransitionDuration: useFastTransition
        ? const Duration(milliseconds: 100)
        : const Duration(milliseconds: 230),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      if (useFastTransition) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
          child: child,
        );
      }
      return PageTurnTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    },
  );
}

bool _useFastTransition(BuildContext context) {
  if (kIsWeb) return false;
  final platform = Theme.of(context).platform;
  return platform == TargetPlatform.android ||
      platform == TargetPlatform.windows;
}

/// A light fade-through transition that never paints two readable pages at
/// once. The shared textured app background stays visible between the pages,
/// so a route cannot briefly expose a flat scaffold color while images decode.
class PageTurnTransition extends StatelessWidget {
  const PageTurnTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final routeOpacity = _routeOpacity(animation);
        final uncoveredOpacity = _uncoveredRouteOpacity(secondaryAnimation);
        final opacity = (routeOpacity * uncoveredOpacity).clamp(0.0, 1.0);
        final scale = 0.992 + opacity * 0.008;

        return IgnorePointer(
          ignoring: opacity < 0.99,
          child: Opacity(
            key: const ValueKey('app_route_transition'),
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
    );
  }

  double _routeOpacity(Animation<double> routeAnimation) {
    final value = routeAnimation.value;
    if (routeAnimation.status == AnimationStatus.reverse) {
      return Curves.easeInCubic.transform(
        ((value - 0.65) / 0.35).clamp(0.0, 1.0),
      );
    }
    return Curves.easeOutCubic.transform(
      ((value - 0.35) / 0.65).clamp(0.0, 1.0),
    );
  }

  double _uncoveredRouteOpacity(Animation<double> coveringAnimation) {
    final value = coveringAnimation.value;
    if (coveringAnimation.status == AnimationStatus.reverse) {
      return Curves.easeOutCubic.transform(
        (1 - value / 0.65).clamp(0.0, 1.0),
      );
    }
    return 1 -
        Curves.easeInCubic.transform(
          (value / 0.35).clamp(0.0, 1.0),
        );
  }
}

/// Animates only the newly selected tab. The previous tab is removed before
/// this animation begins, which avoids the snapshot overlay used previously.
class PageTurnTabFrame extends StatefulWidget {
  const PageTurnTabFrame({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  State<PageTurnTabFrame> createState() => _PageTurnTabFrameState();
}

class _PageTurnTabFrameState extends State<PageTurnTabFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 210),
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = _useFastTransition(context)
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 210);
  }

  @override
  void didUpdateWidget(covariant PageTurnTabFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _direction = widget.index > oldWidget.index ? 1 : -1;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    if (_useFastTransition(context)) {
      return FadeTransition(
        key: const ValueKey('app_tab_transition'),
        opacity: CurvedAnimation(
          parent: _controller,
          curve: Curves.easeOutCubic,
        ),
        child: widget.child,
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(_controller.value);
        return ClipRect(
          child: Opacity(
            key: const ValueKey('app_tab_transition'),
            opacity: progress,
            child: Transform.translate(
              offset: Offset(_direction * 14 * (1 - progress), 0),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
