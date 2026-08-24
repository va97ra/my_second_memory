import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Полоса внизу дня с кнопкой «Добавить запись».
///
/// Календарь — основное место, где записи заводят, поэтому кнопка занимает всю
/// ширину и не уезжает вместе со списком.
class AddRecordBar extends StatelessWidget {
  const AddRecordBar({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.96),
        border: Border(top: BorderSide(color: colors.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('calendar_day_add_record'),
              onPressed: onPressed,
              icon: const Icon(Icons.add_rounded),
              label: Text(AppStrings.of(context).addRecord),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
