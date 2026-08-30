import 'package:ez_core/ez_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../state/finance_currencies.dart';

/// Шапка финансов: валюта, месяц и конвертер.
///
/// Ряд, а не `Wrap`: с переносом пятая кнопка уезжала на свою строку и висела
/// там одна посреди пустоты. Здесь валюта прижата влево, конвертер вправо, а
/// месяц занимает всё между ними и по центру — на узком экране и при крупном
/// шрифте сжимается название месяца, а строка остаётся одна.
class FinanceMonthHeader extends StatelessWidget {
  const FinanceMonthHeader({
    required this.currency,
    required this.month,
    required this.onCurrency,
    required this.onMonthDelta,
    required this.onConverter,
    super.key,
  });

  final String currency;
  final DateTime month;
  final ValueChanged<String> onCurrency;
  final ValueChanged<int> onMonthDelta;
  final VoidCallback onConverter;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final locale = Localizations.localeOf(context).toString();
    return LayoutBuilder(
      builder: (context, constraints) => Row(
        children: [
          DropdownButton<String>(
            key: const ValueKey('finance_currency'),
            value: currency,
            items: [
              for (final code in financeCurrencyCodes)
                DropdownMenuItem(value: code, child: Text(code)),
            ],
            onChanged: (value) {
              if (value != null) onCurrency(value);
            },
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _arrow(Icons.chevron_left_rounded, () => onMonthDelta(-1)),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      DateFormat.yMMM(locale).format(month),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                _arrow(Icons.chevron_right_rounded, () => onMonthDelta(1)),
              ],
            ),
          ),
          _converterButton(context, strings, constraints.maxWidth),
        ],
      ),
    );
  }

  /// Стрелки месяца ужаты: место в строке нужнее подписи у конвертера, а
  /// область нажатия остаётся в сорок логических пикселей.
  Widget _arrow(IconData icon, VoidCallback onPressed) => IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        visualDensity: VisualDensity.compact,
      );

  /// Одна иконка «что это такое?» не объясняет, поэтому там, где строка
  /// вмещает подпись, кнопка её показывает. Где не вмещает — остаётся значок
  /// с подсказкой по долгому нажатию: подпись съела бы название месяца.
  ///
  /// Решает не ширина сама по себе, а ширина относительно размера шрифта:
  /// при двойном масштабе те же 360 логических пикселей вмещают вдвое меньше
  /// букв, и подпись там уже лишняя.
  Widget _converterButton(
    BuildContext context,
    AppStrings strings,
    double width,
  ) {
    const key = ValueKey('finance_converter');
    const icon = Icon(Icons.currency_exchange_rounded, size: 20);
    final roomForWords = width / MediaQuery.textScalerOf(context).scale(1);
    if (roomForWords < 320) {
      return IconButton(
        key: key,
        tooltip: strings.currencyConverter,
        onPressed: onConverter,
        icon: icon,
      );
    }
    return TextButton.icon(
      key: key,
      onPressed: onConverter,
      icon: icon,
      label: Text(strings.exchangeRate),
    );
  }
}
