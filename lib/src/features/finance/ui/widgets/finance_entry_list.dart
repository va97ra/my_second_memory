import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../state/finance_month_ledger.dart';
import 'finance_entry_card.dart';

class FinanceEntryList extends StatelessWidget {
  const FinanceEntryList({
    required this.days,
    required this.locale,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final List<FinanceDayGroup> days;
  final String locale;
  final ValueChanged<FinanceEntry> onEdit;
  final ValueChanged<FinanceEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      DateFormat.yMMMMd(locale).format(day.date),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _column(
                          day.incomes,
                          onEdit: onEdit,
                          onDelete: onDelete,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _column(
                          day.expenses,
                          onEdit: onEdit,
                          onDelete: onDelete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _column(
    List<FinanceEntry> entries, {
    required ValueChanged<FinanceEntry> onEdit,
    required ValueChanged<FinanceEntry> onDelete,
  }) {
    return Column(
      children: [
        for (var index = 0; index < entries.length; index++) ...[
          FinanceEntryCard(
            entry: entries[index],
            onEdit: () => onEdit(entries[index]),
            onDelete: () => onDelete(entries[index]),
          ),
          if (index != entries.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
