import 'package:ez_core/ez_core.dart';
import 'package:ez_design/ez_design.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';

import 'finance_amount_field.dart';
import 'finance_category_field.dart';
import 'finance_date_button.dart';

class FinanceEntrySheet extends StatefulWidget {
  const FinanceEntrySheet({
    required this.kind,
    required this.currencyCode,
    required this.categories,
    this.entry,
    super.key,
  });

  final FinanceEntryKind kind;
  final String currencyCode;
  final List<String> categories;
  final FinanceEntry? entry;

  @override
  State<FinanceEntrySheet> createState() => _FinanceEntrySheetState();
}

class _FinanceEntrySheetState extends State<FinanceEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late String _category;
  late final TextEditingController _description;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: widget.entry?.amount ?? '');
    _category = widget.entry?.category ?? '';
    _description = TextEditingController(text: widget.entry?.description ?? '');
    _date = widget.entry?.occurredOn ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      child: KeyboardInsetPadding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.entry == null
                      ? widget.kind == FinanceEntryKind.income
                          ? strings.addIncome
                          : strings.addExpense
                      : strings.editOperation,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                FinanceAmountField(
                  controller: _amount,
                  currencyCode: widget.currencyCode,
                  validator: (value) {
                    try {
                      FinanceEntry(
                        id: 'validation',
                        kind: widget.kind,
                        amount: value ?? '',
                        currencyCode: widget.currencyCode,
                        category: 'validation',
                        occurredOn: _date,
                        createdAt: _date,
                        updatedAt: _date,
                      );
                      return null;
                    } on FormatException {
                      return strings.amount;
                    }
                  },
                ),
                const SizedBox(height: 12),
                FinanceCategoryField(
                  initialValue: _category,
                  categories: widget.categories,
                  onChanged: (value) => _category = value,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration:
                      InputDecoration(labelText: strings.financeDescription),
                ),
                const SizedBox(height: 12),
                FinanceDateButton(date: _date, onPressed: _pickDate),
                const SizedBox(height: 16),
                FilledButton(onPressed: _save, child: Text(strings.save)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      initialDate: _date,
    );
    if (value != null) setState(() => _date = value);
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final old = widget.entry;
    Navigator.pop(
      context,
      FinanceEntry(
        id: old?.id ?? 'finance-${now.microsecondsSinceEpoch}',
        kind: widget.kind,
        amount: _amount.text,
        currencyCode: widget.currencyCode,
        category: _category.trim(),
        description: _description.text.trim(),
        occurredOn: DateTime(_date.year, _date.month, _date.day),
        createdAt: old?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }
}
