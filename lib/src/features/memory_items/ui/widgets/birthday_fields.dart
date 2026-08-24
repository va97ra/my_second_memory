import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';

/// Поля дня рождения: год рождения.
class BirthdayFields extends StatelessWidget {
  const BirthdayFields({super.key, 
    required this.birthYear,
    required this.locale,
    required this.onTap,
    required this.onClear,
  });

  final int? birthYear;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Icon(Icons.cake_rounded, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  birthYear == null
                      ? (locale == 'ru' ? 'Год рождения' : 'Birth year')
                      : birthYear.toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: AppStrings.of(context).delete,
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
