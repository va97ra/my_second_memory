import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/exchange_rate_controller.dart';
import 'currency_converter_body.dart';

Future<void> showCurrencyConverterSheet(
  BuildContext context, {
  required String ledgerCurrency,
}) {
  // Лист собирается один раз — как и лист операции: пока едет клавиатура,
  // обёртка пересобирается каждый кадр, и с нею пересобиралось бы поле суммы.
  final sheet = CurrencyConverterSheet(ledgerCurrency: ledgerCurrency);
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
  const CurrencyConverterSheet({required this.ledgerCurrency, super.key});

  /// Валюта журнала: в неё переводят, если она не доллар.
  final String ledgerCurrency;

  @override
  ConsumerState<CurrencyConverterSheet> createState() =>
      _CurrencyConverterSheetState();
}

class _CurrencyConverterSheetState
    extends ConsumerState<CurrencyConverterSheet> {
  // Лист открывается на вопросе, который задают чаще всего: «сколько сейчас
  // стоит доллар». Единица слева и валюта журнала справа отвечают на него
  // сразу, без единого нажатия; тысяча рублей в долларах такого ответа не
  // давала — её ещё надо было поделить в уме.
  late final TextEditingController _amount = TextEditingController(text: '1');
  String _from = 'USD';
  late String _to =
      widget.ledgerCurrency == 'USD' ? 'RUB' : widget.ledgerCurrency;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final rates = ref.watch(exchangeRatesProvider);
    final known = rates.valueOrNull;
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
            Row(
              children: [
                Expanded(
                  child: TextField(
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
                ),
                const SizedBox(width: 8),
                _syncButton(strings, busy: rates.isLoading),
              ],
            ),
            const SizedBox(height: 12),
            if (known != null)
              CurrencyConverterBody(
                rates: known,
                amount: _amount,
                from: _from,
                to: _to,
                onPick: (from, to) => setState(() {
                  _from = from;
                  _to = to;
                }),
              )
            else if (rates.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Text(strings.ratesNotLoaded, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// Кнопка стоит вплотную к сумме и ровно её высоты: это одна строка сетки,
  /// а не значок, приклеенный сбоку.
  Widget _syncButton(AppStrings strings, {required bool busy}) => SizedBox(
        width: _fieldHeight,
        height: _fieldHeight,
        child: IconButton(
          key: const ValueKey('converter_sync'),
          tooltip: strings.syncWithSource,
          onPressed: busy
              ? null
              : ref.read(exchangeRatesProvider.notifier).syncWithSource,
          icon: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync_rounded),
        ),
      );
}

/// Высота поля с рамкой `OutlineInputBorder` в этой теме.
const double _fieldHeight = 56;
