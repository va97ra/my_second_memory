import 'dart:math' as math;

import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Круглый значок Джарвиса на странице. По нему видно, что он делает:
/// слушает — расходится кольцо, думает — бежит дуга, говорит — значок
/// чуть дышит.
class JarvisBadgeOrb extends StatelessWidget {
  const JarvisBadgeOrb({
    required this.listening,
    required this.thinking,
    required this.speaking,
    required this.pulse,
    required this.onTap,
    super.key,
  });

  final bool listening;
  final bool thinking;
  final bool speaking;

  /// Ход одного вдоха: от 0 до 1 и снова.
  final Animation<double> pulse;
  final VoidCallback onTap;

  static const size = 56.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = AppStrings.of(context);
    return Semantics(
      button: true,
      label: strings.jarvis,
      child: NotebookPressable(
        key: const ValueKey('jarvis_badge'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: AnimatedBuilder(
          animation: pulse,
          builder: (context, child) => CustomPaint(
            painter: _Halo(
              color: colors.primary,
              listening: listening,
              thinking: thinking,
              phase: pulse.value,
            ),
            child: child,
          ),
          child: SizedBox.square(
            dimension: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: AnimatedScale(
                scale: speaking ? 1.12 : 1,
                duration: const Duration(milliseconds: 240),
                child: Icon(Icons.support_agent_rounded,
                    color: colors.onPrimary, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Кольцо вокруг значка: расходится, пока слушает; дуга бежит, пока думает.
class _Halo extends CustomPainter {
  const _Halo({
    required this.color,
    required this.listening,
    required this.thinking,
    required this.phase,
  });

  final Color color;
  final bool listening;
  final bool thinking;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    if (listening) {
      canvas.drawCircle(
        center,
        radius + 4 + 8 * phase,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = color.withValues(alpha: 0.45 * (1 - phase)),
      );
    }
    if (thinking) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 4),
        phase * 2 * math.pi,
        math.pi / 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_Halo old) =>
      old.phase != phase ||
      old.listening != listening ||
      old.thinking != thinking ||
      old.color != color;
}
