import 'dart:async';
import '../support/production_calendar_test_support.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('live 2026 fixture matches every official day, including short days',
      () {
    final year = parseProductionYear(2026, productionFixture());
    for (var i = 0; i < 365; i++) {
      final date = DateTime.utc(2026, 1, i + 1);
      expect(year.day(date), const ProductionCalendar().day(date),
          reason: '$date');
    }
  });
  test('rejects truncation, error bodies, invalid codes and conflicting dates',
      () {
    for (final bad in [
      '101',
      '0' * 365,
      productionFixture().substring(1),
      '9' * 365,
      '0${productionFixture().substring(1)}'
    ]) {
      expect(() => parseProductionYear(2026, bad), throwsFormatException);
    }
    final data = '01' * 183;
    expect(parseProductionYear(2024, data).days, hasLength(366));
    expect(() => parseProductionYear(2023, data), throwsFormatException);
  });
  test('source requests complete RU five-day year and rejects HTTP failures',
      () async {
    final source = IsDayOffSource(client: MockClient((request) async {
      expect(request.url.scheme, 'https');
      expect(request.url.host, 'isdayoff.ru');
      expect(request.url.queryParameters, {
        'year': '2026',
        'cc': 'ru',
        'pre': '1',
        'holiday': '1',
        'covid': '1',
        'sd': '0',
      });
      return http.Response(productionFixture(), 200);
    }));
    addTearDown(source.close);
    expect(await source.fetch(2026), productionFixture());
    final failed = IsDayOffSource(
        client: MockClient((_) async => http.Response('101', 404)));
    addTearDown(failed.close);
    await expectLater(failed.fetch(2027), throwsStateError);
  });
  test(
      'cache survives restart and failed or conflicting refresh; requests deduplicate',
      () async {
    final completer = Completer<String>();
    final source = FakeProductionSource((_) => completer.future);
    final repo = ProductionCalendarRepository(source: source);
    final now = DateTime.utc(2026, 9, 17);
    final first = repo.refresh(2026, now: now);
    final second = repo.refresh(2026, now: now);
    expect(source.calls, 1);
    completer.complete(productionFixture());
    await Future.wait([first, second]);
    final broken = ProductionCalendarRepository(
        source: FakeProductionSource((_) async => '0' * 365));
    await expectLater(broken.refresh(2026), throwsFormatException);
    final cached = (await broken.readCached(2026))!;
    expect(cached.checkedAt, now);
    expect(cached.data.day(DateTime(2026, 12, 31)),
        ProductionDay.transferredDayOff);
    expect(cached.isFresh(now.add(const Duration(hours: 23))), isTrue);
    expect(cached.isFresh(now.add(const Duration(hours: 24))), isFalse);
    expect(cached.isFresh(now.subtract(const Duration(seconds: 1))), isFalse);
    final offline = ProductionCalendarRepository(
        source: FakeProductionSource((_) async => throw StateError('offline')));
    await expectLater(offline.refresh(2026), throwsStateError);
    expect((await offline.readCached(2026))!.checkedAt, now);
  });
  test('corrupt disk cache is ignored', () async {
    SharedPreferences.setMockInitialValues(
        {ProductionCalendarRepository.storageKey(2026): '{bad'});
    final repo = ProductionCalendarRepository(
        source: FakeProductionSource((_) async => productionFixture()));
    expect(await repo.readCached(2026), isNull);
    await repo.refresh(2026);
    expect(await repo.readCached(2026), isNotNull);
  });
}
