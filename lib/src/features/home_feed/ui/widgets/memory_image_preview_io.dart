import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../media/state/encrypted_media_provider.dart';

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
                Uint8List.fromList(bytes),
                fit: fit,
                cacheWidth: cacheWidth,
                cacheHeight: cacheHeight,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const _BrokenImagePlaceholder(),
            )
        : path.startsWith('data:')
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
