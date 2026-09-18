import 'dart:io';
import 'package:ez_data/ez_data.dart';

// Live response downloaded 2026-09-17 with cc=ru&pre=1&holiday=1&covid=1&sd=0.
// Government decree: https://publication.pravo.gov.ru/document/0001202509240023
String productionFixture() =>
    File('test/fixtures/isdayoff_ru_2026.txt').readAsStringSync();

class FakeProductionSource implements ProductionCalendarSource {
  FakeProductionSource(this.fetchBody);
  final Future<String> Function(int) fetchBody;
  int calls = 0;
  @override
  Future<String> fetch(int year) {
    calls++;
    return fetchBody(year);
  }
}
