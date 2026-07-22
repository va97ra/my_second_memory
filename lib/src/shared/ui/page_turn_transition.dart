import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/notebook/notebook_visuals.dart';

Page<void> pageTurnPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  if (NotebookVisuals.maybeOf(context) == null) {
    return MaterialPage<void>(key: state.pageKey, child: child);
  }
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) {
        return child;
      }
      return PageTurnTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    },
  );
}

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
    final incoming = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return AnimatedBuilder(
      animation: Listenable.merge([incoming, secondaryAnimation]),
      child: child,
      builder: (context, child) {
        final enterAngle = (1 - incoming.value) * -math.pi / 2.7;
        final exitAngle = secondaryAnimation.value * math.pi / 3.4;
        final angle = enterAngle + exitAngle;
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(angle);
        return Transform(
          alignment: angle <= 0 ? Alignment.centerLeft : Alignment.centerRight,
          transform: matrix,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              child!,
              if (angle.abs() > 0.01)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: angle < 0
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          end: angle < 0
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          colors: [
                            Colors.black.withValues(
                              alpha: 0.28 * (angle.abs() / (math.pi / 2)),
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

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
      duration: const Duration(milliseconds: 240),
      value: 1,
    );
  }

  @override
  void didUpdateWidget(covariant PageTurnTabFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _direction = widget.index > oldWidget.index ? 1 : -1;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context) ||
        NotebookVisuals.maybeOf(context) == null) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(_controller.value);
        final angle = (1 - progress) * 0.34 * _direction;
        return Transform(
          alignment:
              _direction > 0 ? Alignment.centerRight : Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angle),
          child: child,
        );
      },
    );
  }
}
