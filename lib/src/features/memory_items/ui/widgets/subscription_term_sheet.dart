import 'package:ez_design/ez_design.dart';
import 'package:flutter/material.dart';

/// Выбор срока подписки в месяцах.
class SubscriptionTermSheet extends StatefulWidget {
  const SubscriptionTermSheet({super.key, required this.initialMonths});

  final int? initialMonths;

  @override
  State<SubscriptionTermSheet> createState() => SubscriptionTermSheetState();
}

class SubscriptionTermSheetState extends State<SubscriptionTermSheet> {
  late bool _unlimited;
  late int _years;
  late int _months;

  @override
  void initState() {
    super.initState();
    final total = widget.initialMonths;
    _unlimited = total == null;
    _years = (total ?? 3) ~/ 12;
    _months = (total ?? 3) % 12;
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final ru = locale == 'ru';
    final total = _years * 12 + _months;
    return SafeArea(
      child: KeyboardInsetPadding(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ru ? 'Срок подписки' : 'Subscription term',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                ru
                    ? 'Платёж будет появляться каждый месяц только в течение выбранного срока.'
                    : 'The payment will appear monthly only for the selected term.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 10),
              SwitchListTile.adaptive(
                key: const ValueKey('subscription_term_unlimited'),
                contentPadding: EdgeInsets.zero,
                title: Text(ru ? 'Без срока' : 'No end date'),
                value: _unlimited,
                onChanged: (value) => setState(() {
                  _unlimited = value;
                  if (!value && _years == 0 && _months == 0) {
                    _months = 3;
                  }
                }),
              ),
              if (!_unlimited) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<int>(
                        key: const ValueKey('subscription_term_years'),
                        initialValue: _years,
                        decoration: InputDecoration(
                          labelText: ru ? 'Лет' : 'Years',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (var value = 0; value <= 30; value++)
                            DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _years = value);
                        },
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<int>(
                        key: const ValueKey('subscription_term_months'),
                        initialValue: _months,
                        decoration: InputDecoration(
                          labelText: ru ? 'Месяцев' : 'Months',
                          border: const OutlineInputBorder(),
                        ),
                        items: [
                          for (var value = 0; value < 12; value++)
                            DropdownMenuItem(
                              value: value,
                              child: Text('$value'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _months = value);
                        },
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey('subscription_term_save'),
                onPressed: !_unlimited && total == 0
                    ? null
                    : () => Navigator.of(context).pop(_unlimited ? 0 : total),
                icon: const Icon(Icons.check_rounded),
                label: Text(ru ? 'Готово' : 'Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
