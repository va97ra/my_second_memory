import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

import 'account_tint.dart';

/// Полоска выбора цвета карточки: слева бумага без краски, дальше цветовой круг.
///
/// Цвет меняется под пальцем, отпустили — выбор сделан.
class AccountTintStrip extends StatelessWidget {
  const AccountTintStrip({
    super.key,
    required this.hue,
    required this.onChanged,
    required this.onDone,
  });

  static const _paperShare = 0.14;
  static const _hueStep = 60;
  static const _markerWidth = 4.0;

  final int? hue;
  final ValueChanged<int?> onChanged;
  final VoidCallback onDone;

  static final _gradient = LinearGradient(
    colors: [
      AppPalette.paper,
      AppPalette.paper,
      for (var h = 0; h <= 360; h += _hueStep) accountTintAccent(h % 360),
    ],
    stops: [
      0,
      _paperShare,
      for (var h = 0; h <= 360; h += _hueStep)
        _paperShare + (1 - _paperShare) * h / 360,
    ],
  );

  int? _hueAt(double share) {
    if (share < _paperShare) return null;
    final circle = (share - _paperShare) / (1 - _paperShare);
    return (circle * 360).round().clamp(0, 359);
  }

  double _shareOf(int? value) => value == null
      ? _paperShare / 2
      : _paperShare + (1 - _paperShare) * value / 360;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    return Semantics(
      label: AppStrings.of(context).accountColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          void pick(Offset at) => onChanged(_hueAt(at.dx / width));

          return GestureDetector(
            key: const ValueKey('account_tint_strip'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => pick(details.localPosition),
            onTapUp: (_) => onDone(),
            onHorizontalDragStart: (details) => pick(details.localPosition),
            onHorizontalDragUpdate: (details) => pick(details.localPosition),
            onHorizontalDragEnd: (_) => onDone(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _gradient,
                  borderRadius: radius,
                  border: Border.all(color: AppPalette.muted),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: (_shareOf(hue) * width - _markerWidth / 2)
                          .clamp(0, width - _markerWidth),
                      top: 0,
                      bottom: 0,
                      width: _markerWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppPalette.paper,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: AppPalette.paperInk),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
