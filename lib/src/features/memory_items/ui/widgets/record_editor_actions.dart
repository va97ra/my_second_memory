import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'recurrence_badge.dart';
import 'square_action_button.dart';

/// Нижняя строка редактора: отметка повтора слева, фотография и голос справа.
class RecordEditorActions extends StatelessWidget {
  const RecordEditorActions({
    super.key,
    required this.recurrenceFrequency,
    required this.isRecording,
    required this.buttonSize,
    required this.onRecurrenceTap,
    required this.onPickImage,
    required this.onVoicePressed,
  });

  final RecurrenceFrequency? recurrenceFrequency;
  final bool isRecording;
  final double buttonSize;
  final VoidCallback onRecurrenceTap;
  final VoidCallback onPickImage;
  final VoidCallback onVoicePressed;

  @override
  Widget build(BuildContext context) {
    final frequency = recurrenceFrequency;
    final badge = frequency == null
        ? null
        : RecurrenceBadge(frequency: frequency, onTap: onRecurrenceTap);

    return LayoutBuilder(
      builder: (context, constraints) {
        // В узкой строке или при крупном тексте отметка и кнопки не помещаются
        // рядом, поэтому встают друг под друга.
        final stacked = badge != null &&
            (constraints.maxWidth < 230 ||
                MediaQuery.textScalerOf(context).scale(1) > 1.5);
        if (!stacked) {
          return Row(
            children: [
              if (badge != null) badge,
              const Spacer(),
              _buttons(context),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerLeft, child: badge),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: _buttons(context)),
          ],
        );
      },
    );
  }

  Widget _buttons(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SquareActionButton(
          tooltip: strings.addImage,
          icon: Icons.photo_camera_rounded,
          color: colors.primary,
          size: buttonSize,
          onPressed: onPickImage,
        ),
        const SizedBox(width: 8),
        SquareActionButton(
          tooltip: isRecording ? strings.stopRecording : strings.voice,
          icon: isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: isRecording ? colors.error : colors.secondary,
          size: buttonSize,
          onPressed: onVoicePressed,
        ),
      ],
    );
  }
}
