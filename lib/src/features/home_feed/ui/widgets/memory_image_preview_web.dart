import 'dart:convert';

import 'package:flutter/material.dart';

class MemoryImagePreview extends StatelessWidget {
  const MemoryImagePreview({
    required this.path,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final child = path.startsWith('data:')
        ? Image.memory(
            base64Decode(path.substring(path.indexOf(',') + 1)),
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                const _BrokenImagePlaceholder(),
          )
        : Image.network(
            path,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                const _BrokenImagePlaceholder(),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: child,
    );
  }
}

class _BrokenImagePlaceholder extends StatelessWidget {
  const _BrokenImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEAF3FF),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
      ),
    );
  }
}
