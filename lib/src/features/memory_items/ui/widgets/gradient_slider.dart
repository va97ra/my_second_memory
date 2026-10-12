import 'package:flutter/material.dart';

/// Ползунок с цветной дорожкой: оттенок — радуга, насыщенность — от серого
/// к чистому цвету. Тянуть или ткнуть в нужное место.
class GradientSlider extends StatelessWidget {
  const GradientSlider({
    required this.label,
    required this.value,
    required this.colors,
    required this.thumb,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final List<Color> colors;
  final Color thumb;
  final ValueChanged<double> onChanged;

  static const _thumb = 28.0;

  @override
  Widget build(BuildContext context) {
    double stepped(double by) => (value + by).clamp(0.0, 1.0);
    String percent(double of) => '${(of * 100).round()}%';
    return Semantics(
      slider: true,
      label: label,
      value: percent(value),
      increasedValue: percent(stepped(0.05)),
      decreasedValue: percent(stepped(-0.05)),
      onIncrease: () => onChanged(stepped(0.05)),
      onDecrease: () => onChanged(stepped(-0.05)),
      child: LayoutBuilder(builder: (context, box) {
        final track = box.maxWidth - _thumb;
        void at(Offset local) =>
            onChanged(((local.dx - _thumb / 2) / track).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => at(details.localPosition),
          onHorizontalDragStart: (details) => at(details.localPosition),
          onHorizontalDragUpdate: (details) => at(details.localPosition),
          child: SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: _thumb / 2,
                  right: _thumb / 2,
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      gradient: LinearGradient(colors: colors),
                    ),
                  ),
                ),
                Positioned(
                  left: value * track,
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: thumb,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
