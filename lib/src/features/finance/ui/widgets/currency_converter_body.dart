import 'package:ez_core/ez_core.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../state/finance_currencies.dart';

/// Пара валют, результат и дата курса.
///
/// Своего состояния не держит: выбранную пару отдаёт наверх, чтобы она пережила
/// перезагрузку курсов.
class CurrencyConverterBody extends StatelessWidget {
  const CurrencyConverterBody({
    required this.rates,
    required this.amount,
    required this.from,
    required this.to,
    required this.onPick,
    super.key,
  });

  final ExchangeRates rates;

  /// Контроллер поля суммы, а не её текст: перерисовывается только ответ.
  final TextEditingController amount;
  final String from;
  final String to;
  final void Function(String from, String to) onPick;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    // Показываем только те валюты, курс которых действительно приехал:
    // предложить валюту без курса значит пообещать ответ, которого нет.
    final known = [
      for (final code in financeCurrencyCodes)
        if (rates.knows(code)) code,
    ];
    if (known.length < 2) return Text(strings.ratesNotLoaded);
    final source = known.contains(from) ? from : known.first;
    final target = known.contains(to) ? to : known.last;
    final locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _picker('converter_from', known, source,
                  (code) => onPick(code, target)),
            ),
            IconButton(
              key: const ValueKey('converter_swap'),
              tooltip: strings.swapCurrencies,
              onPressed: () => onPick(target, source),
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
            Expanded(
              child: _picker('converter_to', known, target,
                  (code) => onPick(source, code)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: amount,
          builder: (context, value, _) {
            final entered = parseToolNumber(value.text);
            final result = entered == null
                ? null
                : rates.convert(amount: entered, from: source, to: target);
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                key: const ValueKey('converter_result'),
                // Деньги показываются двумя знаками — как суммы в остальных
                // финансах, а не шестью значащими, которыми считают инженерию.
                result == null ? '—' : '${result.toStringAsFixed(2)} $target',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          strings.ratesAsOf(DateFormat.yMMMMd(locale).format(rates.date)),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _picker(
    String key,
    List<String> codes,
    String value,
    ValueChanged<String> onChanged,
  ) =>
      DropdownButtonFormField<String>(
        key: ValueKey(key),
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: [
          for (final code in codes)
            DropdownMenuItem(value: code, child: Text(code)),
        ],
        onChanged: (picked) {
          if (picked != null) onChanged(picked);
        },
      );
}
