import 'package:flutter/material.dart';

/// Значки вложений в плотной карточке: фотографии и голос.
class MemoryCardAttachmentIcons extends StatelessWidget {
  const MemoryCardAttachmentIcons({
    super.key,
    required this.imageCount,
    required this.hasAudio,
  });

  final int imageCount;
  final bool hasAudio;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (imageCount > 0) ...[
          Icon(Icons.image_rounded, size: 16, color: color),
          if (imageCount > 1)
            Text(
              '$imageCount',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
            ),
        ],
        if (imageCount > 0 && hasAudio) const SizedBox(width: 3),
        if (hasAudio) Icon(Icons.mic_rounded, size: 16, color: color),
      ],
    );
  }
}
