import 'dart:convert';

import 'package:flutter/material.dart';

import 'broken_image_placeholder.dart';

class MemoryImagePreview extends StatelessWidget {
  const MemoryImagePreview({
    required this.path,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.cacheHeight,
    super.key,
  });

  final String path;
  final BoxFit fit;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final child = path.startsWith('data:')
        ? Image.memory(
            base64Decode(path.substring(path.indexOf(',') + 1)),
            fit: fit,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            errorBuilder: (context, error, stackTrace) =>
                const BrokenImagePlaceholder(),
          )
        : Image.network(
            path,
            fit: fit,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            errorBuilder: (context, error, stackTrace) =>
                const BrokenImagePlaceholder(),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: child,
    );
  }
}
