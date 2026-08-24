import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'broken_image_placeholder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/encrypted_media_provider.dart';

class MemoryImagePreview extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isRemoteLike = path.startsWith('http') ||
        path.startsWith('blob:') ||
        path.startsWith('data:');
    final child = path.endsWith('.ezm')
        ? ref.watch(encryptedMediaBytesProvider(path)).when(
              data: (bytes) => Image.memory(
                bytes,
                fit: fit,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const BrokenImagePlaceholder(),
            )
        : path.startsWith('data:')
            ? Image.memory(
                base64Decode(path.substring(path.indexOf(',') + 1)),
                fit: fit,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
                errorBuilder: (context, error, stackTrace) =>
                    const BrokenImagePlaceholder(),
              )
            : isRemoteLike
                ? Image.network(
                    path,
                    fit: fit,
                    cacheWidth: cacheWidth,
                    cacheHeight: cacheHeight,
                    errorBuilder: (context, error, stackTrace) =>
                        const BrokenImagePlaceholder(),
                  )
                : Image.file(
                    File(path),
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
