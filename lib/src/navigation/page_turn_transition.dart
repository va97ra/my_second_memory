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
    // Обёртка одна и та же на всю жизнь страницы. Раньше здесь возвращались
    // разные деревья — то голый `child`, то `FadeTransition`, то пустой
    // `SizedBox`, — и при каждой смене формы Flutter выбрасывал поддерево и
    // строил его заново. Вместе с ним пропадало состояние экрана: позиция
    // прокрутки, выбранный фильтр, набранный текст. Теперь меняются только
    // значения внутри одной обёртки.
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return PageTurnTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        fast: useFastTransition,
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

/// Появление и уход страницы маршрута.
///
/// Обычно видимый переход рисует не она, а бумажный лист [PageTurnFrame]:
/// он накрывает страницу целиком. Здесь остаётся запасной вариант — на случай,
/// когда снимка страницы нет, — и правило «во время переворота не мешать».
class PageTurnTransition extends StatelessWidget {
  const PageTurnTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    this.fast = false,
    super.key,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;

  /// Короткое затухание вместо полного перехода: там, где переворот и так
  /// быстрый, длинный переход под ним только запаздывает.
  final bool fast;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([animation, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final opacity = _opacity(context);
        // Ниже 0.99 страница ещё проявляется: нажатия сквозь неё уходили бы
        // на ту, что под ней.
        return IgnorePointer(
          ignoring: opacity < 0.99,
          child: Opacity(
            key: const ValueKey('app_route_transition'),
            opacity: opacity,
            child: Transform.scale(
              scale: fast ? 1 : 0.992 + opacity * 0.008,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Насколько страница видна прямо сейчас.
  double _opacity(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return 1;

    if (PageTurnNavigationScope.maybeOf(context)?.isTurning ?? false) {
      // Видимым переходом владеет бумажный лист. Страница, которую снимают,
      // прячется целиком: иначе снимок для обратного переворота захватил бы
      // уходящий экран во время его затухания.
      return animation.status == AnimationStatus.reverse ? 0 : 1;
    }

    if (fast) {
      final curve = animation.status == AnimationStatus.reverse
          ? Curves.easeInCubic
          : Curves.easeOutCubic;
      return curve.transform(animation.value.clamp(0.0, 1.0));
    }

    final appearing = _routeOpacity(animation);
    final uncovered = _uncoveredRouteOpacity(secondaryAnimation);
    return (appearing * uncovered).clamp(0.0, 1.0);
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
