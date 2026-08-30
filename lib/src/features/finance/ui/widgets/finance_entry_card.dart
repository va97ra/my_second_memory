import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

class FinanceEntryCard extends StatelessWidget {
  const FinanceEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final FinanceEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isIncome = entry.kind == FinanceEntryKind.income;
    final color = isIncome ? const Color(0xFF168653) : const Color(0xFFD32020);
    return Card(
      key: ValueKey('finance_entry_${entry.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
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
                    onPressed: onDelete,
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
