import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Значок сервиса: первая буква названия на цветном кружке.
class ServiceAvatar extends StatelessWidget {
  const ServiceAvatar({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter =
        trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppPalette.muted),
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: Text(
            letter,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}
