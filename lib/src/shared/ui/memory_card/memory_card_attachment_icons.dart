import 'package:flutter/material.dart';

/// Значки при записи: фотографии, голос и заведённое напоминание.
///
/// Один виджет на карточки ленты и на таблички шкалы: правило, по которому
/// запись показывает своё содержимое, должно быть одно.
class MemoryCardAttachmentIcons extends StatelessWidget {
  const MemoryCardAttachmentIcons({
    super.key,
    required this.imageCount,
    required this.hasAudio,
    this.hasReminder = false,
  });

  final int imageCount;
  final bool hasAudio;

  /// Напоминание заведено. Иначе о нём знает только меню записи.
  final bool hasReminder;

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
        if (hasReminder) ...[
          if (imageCount > 0 || hasAudio) const SizedBox(width: 3),
          Icon(
            Icons.notifications_active_rounded,
            size: 15,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ],
    );
  }
}
