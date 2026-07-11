import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

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
    final isRemoteLike = path.startsWith('http') ||
        path.startsWith('blob:') ||
        path.startsWith('data:');
    final child = path.startsWith('data:')
        ? Image.memory(
            base64Decode(path.substring(path.indexOf(',') + 1)),
            fit: fit,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            errorBuilder: (context, error, stackTrace) =>
                const _BrokenImagePlaceholder(),
          )
        : isRemoteLike
            ? Image.network(
                path,
                fit: fit,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                errorBuilder: (context, error, stackTrace) =>
                    const _BrokenImagePlaceholder(),
              )
            : Image.file(
                File(path),
                fit: fit,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
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
