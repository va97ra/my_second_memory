import 'package:ez_design/ez_design.dart';
import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/finance_controller.dart';

/// Карточка операции: получает идентификатор и читает её сама.
class FinanceEntryCard extends ConsumerWidget {
  const FinanceEntryCard({
    required this.entryId,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final String entryId;
  final ValueChanged<FinanceEntry> onEdit;
  final ValueChanged<FinanceEntry> onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(financeEntryByIdProvider(entryId));
    if (entry == null) return const SizedBox.shrink();
    final strings = AppStrings.of(context);
    final isIncome = entry.kind == FinanceEntryKind.income;
    final color = isIncome ? AppPalette.success : AppPalette.danger;
    return Card(
      key: ValueKey('finance_entry_${entry.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onEdit(entry),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.category,
                      softWrap: true,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    key: ValueKey('finance_delete_${entry.id}'),
                    tooltip: strings.delete,
                    onPressed: () => onDelete(entry),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${isIncome ? '+' : '−'}${entry.amount} ${entry.currencyCode}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
              if (entry.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  entry.description,
                  softWrap: true,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
