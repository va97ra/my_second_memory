import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ez_design/ez_design.dart';
import 'page_turn_navigation.dart';

Page<void> pageTurnPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  bool interceptBack = true,
  String? backFallback,
}) {
  final useFastTransition = _useFastTransition(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: interceptBack
        ? PageTurnBackScope(
            fallbackLocation: backFallback,
            child: child,
          )
        : child,
    transitionDuration: useFastTransition
        ? const Duration(milliseconds: 120)
        : const Duration(milliseconds: 260),
    reverseTransitionDuration: useFastTransition
        ? const Duration(milliseconds: 100)
        : const Duration(milliseconds: 230),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final activePageTurn =
          PageTurnNavigationScope.maybeOf(context)?.isTurning ?? false;
      if (activePageTurn) {
        // The rasterized sheet owns the visible transition. Remove a route
        // that is popping immediately so the backward target snapshot cannot
        // accidentally capture the outgoing editor during its fallback fade.
        if (animation.status == AnimationStatus.reverse) {
          return const SizedBox.expand();
        }
        return child;
      }
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

/// A short fallback transition used while no rasterized page is available.
/// The physical page-turn overlay normally covers this transition completely.
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
