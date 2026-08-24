import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Подпись о ходе автосохранения. Одна на весь редактор: её показывает и
/// заголовок, и значок.
String memorySaveStatusLabel(
  BuildContext context, {
  required bool isSaving,
  required bool hasError,
}) {
  final strings = AppStrings.of(context);
  if (hasError) return strings.saveFailed;
  return isSaving ? strings.saving : strings.saved;
}

/// Значок автосохранения: сохранено, сохраняется или не удалось.
class MemoryAutosaveBadge extends StatelessWidget {
  const MemoryAutosaveBadge({
    super.key,
    required this.isSaving,
    required this.hasError,
  });

  final bool isSaving;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Tooltip(
      message: memorySaveStatusLabel(
        context,
        isSaving: isSaving,
        hasError: hasError,
      ),
      child: AnimatedContainer(
        key: const ValueKey('memory_autosave_status'),
        duration: const Duration(milliseconds: 220),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (hasError
                  ? errorColor
                  : isSaving
                      ? const Color(0xFFD59A48)
                      : const Color(0xFF239B61))
              .withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          hasError
              ? Icons.cloud_off_rounded
              : isSaving
                  ? Icons.sync_rounded
                  : Icons.cloud_done_rounded,
          key: ValueKey(
            hasError
                ? 'memory_autosave_error'
                : isSaving
                    ? 'memory_autosave_saving'
                    : 'memory_autosave_saved',
          ),
          size: 22,
          color: hasError
              ? errorColor
              : isSaving
                  ? const Color(0xFFB7791F)
                  : const Color(0xFF168653),
        ),
      ),
    );
  }
}
