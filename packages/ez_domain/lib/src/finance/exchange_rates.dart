/// Курсы валют на дату, приведённые к одной базовой валюте.
///
/// Хранится не «курс», а стоимость одной единицы валюты в базовой: у ЦБ РФ
/// курс дан за номинал (сто иен, тысяча вон), и номинал — часть источника, а
/// не часть правила. Приводить к единице нужно один раз, при разборе ответа,
/// иначе номинал разъедется по всем местам, где считают.
class ExchangeRates {
  const ExchangeRates({
    required this.base,
    required this.date,
    required this.basePerUnit,
  });

  /// Валюта, к которой приведены остальные. Её собственный курс всегда 1.
  final String base;

  /// Дата курса, а не время загрузки. Именно её показывают человеку: курс,
  /// приехавший вчера, остаётся вчерашним, сколько бы раз его ни прочитали.
  final DateTime date;

  /// Сколько базовой валюты стоит одна единица валюты с этим кодом.
  final Map<String, double> basePerUnit;

  Iterable<String> get currencies => [base, ...basePerUnit.keys];

  bool knows(String code) => rateOf(code) != null;

  double? rateOf(String code) => code == base ? 1 : basePerUnit[code];

  /// Пересчёт через базовую валюту. `null` означает, что одной из валют в
  /// таблице нет — показывать ноль в этом случае нельзя, это был бы ответ.
  double? convert({
    required double amount,
    required String from,
    required String to,
  }) {
    final fromRate = rateOf(from);
    final toRate = rateOf(to);
    if (fromRate == null || toRate == null || toRate == 0) return null;
    return amount * fromRate / toRate;
  }

  Map<String, Object?> toJson() => {
        'base': base,
        'date': date.toUtc().toIso8601String(),
        'basePerUnit': basePerUnit,
      };

  factory ExchangeRates.fromJson(Map<String, Object?> json) {
    return ExchangeRates(
      base: json['base'] as String,
      date: DateTime.parse(json['date'] as String).toLocal(),
      basePerUnit: {
        for (final entry
            in (json['basePerUnit'] as Map).cast<String, Object?>().entries)
          entry.key: (entry.value as num).toDouble(),
      },
    );
  }
}
