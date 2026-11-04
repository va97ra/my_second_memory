import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Значок сервиса: первая буква названия на цветном квадратике.
class ServiceAvatar extends StatelessWidget {
  const ServiceAvatar({super.key, required this.name, required this.color});

  static const _size = 24.0;

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter =
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SizedBox.square(
        dimension: _size,
        child: Center(
          child: Text(
            letter,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: readableInkOn(color),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}
