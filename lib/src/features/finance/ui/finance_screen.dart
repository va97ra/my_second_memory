import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/finance_controller.dart';
import '../state/finance_preferences.dart';
import 'widgets/currency_converter_sheet.dart';
import 'widgets/finance_month_header.dart';
import 'widgets/finance_entry_sheet_launcher.dart';
import 'widgets/finance_entry_list.dart';
import 'widgets/finance_summary_card.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final currency = ref.watch(financeCurrencyProvider);
    final month = ref.watch(financeMonthProvider);
    final ledger = ref.watch(financeMonthLedgerProvider);
    final locale = Localizations.localeOf(context).toString();
    return WarmGradientBackground(
      child: CustomScrollView(
        key: const ValueKey('finance_scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    children: [
                      FinanceMonthHeader(
                        currency: currency,
                        month: month,
                        onCurrency: (value) => ref
                            .read(financeCurrencyProvider.notifier)
                            .select(value),
                        onMonthDelta: (delta) =>
                            _changeMonth(ref, month, delta),
                        onConverter: () => showCurrencyConverterSheet(
                          context,
                          ledgerCurrency: currency,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FinanceSummaryCard(
                        summary: ledger.summary,
                        currencyCode: currency,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              key: const ValueKey('finance_add_income'),
                              onPressed: () => _edit(
                                context,
                                ref,
                                FinanceEntryKind.income,
                              ),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(strings.income),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              key: const ValueKey('finance_add_expense'),
                              onPressed: () => _edit(
                                context,
                                ref,
                                FinanceEntryKind.expense,
                              ),
                              icon: const Icon(Icons.remove_rounded),
                              label: Text(strings.expense),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (ledger.entries.isEmpty)
            SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text(strings.noFinanceEntries)))
          else
            FinanceEntryList(
              days: ledger.days,
              locale: locale,
              onEdit: (entry) => _edit(context, ref, entry.kind, entry),
              onDelete: (entry) => _delete(context, ref, entry),
            ),
        ],
      ),
    );
  }

  void _changeMonth(WidgetRef ref, DateTime month, int offset) {
    ref.read(financeMonthProvider.notifier).state =
        DateTime(month.year, month.month + offset);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, FinanceEntryKind kind,
      [FinanceEntry? entry]) async {
    final currency = ref.read(financeCurrencyProvider);
    final strings = AppStrings.of(context);
    final defaults = kind == FinanceEntryKind.income
        ? strings.defaultIncomeCategories
        : strings.defaultExpenseCategories;
    final custom = ref
        .read(financeControllerProvider)
        .where((item) => item.currencyCode == currency && item.kind == kind)
        .map((item) => item.category);
    final categories = <String>{...defaults, ...custom}.toList();
    final value = await showFinanceEntrySheet(context,
        kind: kind,
        currencyCode: currency,
        categories: categories,
        entry: entry);
    if (value == null) return;
    final controller = ref.read(financeControllerProvider.notifier);
    entry == null
        ? await controller.add(value)
        : await controller.update(value);
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, FinanceEntry entry) async {
    final strings = AppStrings.of(context);
    final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                    title: Text(strings.deleteOperationQuestion),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(strings.cancel)),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(strings.delete))
                    ])) ??
        false;
    if (confirmed) {
      await ref.read(financeControllerProvider.notifier).delete(entry.id);
    }
  }
}
