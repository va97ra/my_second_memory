import 'dart:convert';
import 'dart:io';

import 'package:ez_data/ez_data.dart';
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
    // Файл читается через хранилище, а не напрямую: оно одно знает, лежит
    // вложение открытым или зашифрованным. Раньше эту развилку решал флаг
    // «на устройстве задан PIN», и на приехавшем синхронизацией файле он
    // расходился с тем, что на диске, — картинка не открывалась.
    final child = !MediaStorage.isExternal(path)
        ? ref.watch(mediaBytesProvider(path)).when(
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
                    // Каталог свой у каждого устройства: в записи лежит
                    // имя, путь собирается здесь.
                    File(MediaStorage.resolve(path)),
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
