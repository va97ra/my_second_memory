import 'package:flutter/material.dart';

/// Место фотографии, которую не удалось прочитать.
///
/// Файл мог не расшифроваться или исчезнуть из хранилища; запись при этом
/// цела, поэтому вместо картинки показывается знак, а не пустота.
class BrokenImagePlaceholder extends StatelessWidget {
  const BrokenImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: colors.primary,
          size: 28,
        ),
      ),
    );
  }
}
