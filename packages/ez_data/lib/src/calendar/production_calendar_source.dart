import 'package:ez_domain/ez_domain.dart';
import 'package:http/http.dart' as http;

abstract interface class ProductionCalendarSource {
  Future<String> fetch(int year);
}

/// Third-party API, not a government service. One request for the whole year.
class IsDayOffSource implements ProductionCalendarSource {
  IsDayOffSource({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  @override
  Future<String> fetch(int year) async {
    final response = await _client
        .get(Uri.https('isdayoff.ru', '/api/getdata', {
          'year': '$year',
          'cc': 'ru',
          'pre': '1',
          'holiday': '1',
          'covid': '1',
          'sd': '0',
        }))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw StateError('isDayOff HTTP ${response.statusCode}');
    }
    return response.body.trim();
  }

  void close() => _client.close();
}

/// Both network and disk data pass the same validation. The bundled official
/// 2026 calendar is also a day-by-day reference, not just an annual total.
ProductionYear parseProductionYear(int year, String body) {
  final count = DateTime.utc(year + 1).difference(DateTime.utc(year)).inDays;
  if (body.length != count || !RegExp(r'^[01248]+$').hasMatch(body)) {
    throw const FormatException('Invalid isDayOff response');
  }
  final days = <ProductionDay>[];
  for (var i = 0; i < count; i++) {
    var day = switch (body[i]) {
      '0' => ProductionDay.working,
      '2' => ProductionDay.shortened,
      '8' => ProductionDay.holiday,
      _ => ProductionDay.dayOff,
    };
    final date = DateTime.utc(year, 1, i + 1);
    final official = const ProductionCalendar().day(date);
    if (official != null) {
      int category(ProductionDay value) => switch (value) {
            ProductionDay.working => 0,
            ProductionDay.shortened => 2,
            _ => 1,
          };
      if (category(day) != category(official)) {
        throw const FormatException(
            'Calendar conflicts with official 2026 data');
      }
      day = official;
    }
    days.add(day);
  }
  // Reject empty/default datasets (some providers return all working days).
  if (!days.contains(ProductionDay.working) ||
      !days.any((day) =>
          day != ProductionDay.working && day != ProductionDay.shortened)) {
    throw const FormatException('Calendar has no working days or days off');
  }
  return ProductionYear(year, days);
}
