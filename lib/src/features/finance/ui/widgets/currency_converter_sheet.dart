import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/exchange_rate_controller.dart';
import 'currency_converter_body.dart';

Future<void> showCurrencyConverterSheet(
  BuildContext context, {
  required String currencyCode,
}) {
  // Лист собирается один раз — как и лист операции: пока едет клавиатура,
  // обёртка пересобирается каждый кадр, и с нею пересобиралось бы поле суммы.
  final sheet = CurrencyConverterSheet(initialFrom: currencyCode);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => sheet,
  );
}

/// Оболочка листа: сумма, состояние загрузки курсов и выбранная пара.
/// Сам пересчёт и его показ — в [CurrencyConverterBody].
///
/// Поле суммы отдаётся телу контроллером, а не строкой: набор цифры не должен
/// пересобирать ни списки валют, ни оболочку — только строку ответа.
class CurrencyConverterSheet extends ConsumerStatefulWidget {
  const CurrencyConverterSheet({required this.initialFrom, super.key});

  final String initialFrom;

  @override
  ConsumerState<CurrencyConverterSheet> createState() =>
      _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState
    extends ConsumerState<CurrencyConverterSheet> {
  late final TextEditingController _amount =
      TextEditingController(text: '1000');
  late String _from = widget.initialFrom;
  late String _to = widget.initialFrom == 'RUB' ? 'USD' : 'RUB';

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final rates = ref.watch(exchangeRatesProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.currencyConverter,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('converter_amount'),
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: strings.amount,
              ),
            ),
            const SizedBox(height: 12),
            rates.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(strings.ratesNotLoaded),
              data: (value) => value == null
                  ? Text(strings.ratesNotLoaded)
                  : CurrencyConverterBody(
                      rates: value,
                      amount: _amount,
                      from: _from,
                      to: _to,
                      onPick: (from, to) => setState(() {
                        _from = from;
                        _to = to;
                      }),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
