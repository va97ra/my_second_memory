import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/jarvis/state/jarvis_bank_notices.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Уведомления банков, отложенные Android, становятся записями финансов —
/// одна покупка, пришедшая пушем и SMS, записывается один раз.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('ezhednevnik_v2/bank');
  final at = DateTime(2026, 10, 9, 15, 42).millisecondsSinceEpoch;

  late List<Map<String, Object?>> pending;
  late List<String> forgotten;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    forgotten = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'pending':
          return pending;
        case 'forget':
          forgotten.addAll(
              ((call.arguments as Map)['keys'] as List).cast<String>());
      }
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('покупка пушем и SMS — одна запись, реклама — ни одной', () async {
    pending = [
      {
        'key': 'push',
        'app': 'СберБанк',
        'title': 'Покупка',
        'text': 'Покупка 350 ₽, SPAR. Баланс 4 590 ₽',
        'at': at,
      },
      {
        'key': 'sms',
        'app': 'Сообщения',
        'title': '900',
        'text': 'MIR-1234 15:42 Покупка 350р SPAR Баланс: 4590.20р',
        'at': at + 5000,
      },
      {
        'key': 'shop',
        'app': 'Магазин',
        'title': 'Скидка',
        'text': 'Скидка 500 ₽ на первую покупку!',
        'at': at,
      },
    ];
    final recorded = <AddFinanceEntry>[];
    final notices = JarvisBankNotices(
      enabled: () => true,
      record: (entry) async => recorded.add(entry),
    );
    await notices.check();
    expect(recorded, hasLength(1));
    expect(recorded.single.amount, '350');
    expect(recorded.single.category, 'SPAR');
    expect(recorded.single.source, 'СберБанк');
    expect(forgotten, ['push', 'sms', 'shop'],
        reason: 'разобранное больше не лежит в очереди');
  });

  test('пока владелец не включил — ничего не читается', () async {
    pending = [
      {
        'key': 'push',
        'app': 'СберБанк',
        'title': '',
        'text': 'Покупка 350 ₽, SPAR. Баланс 4 590 ₽',
        'at': at,
      },
    ];
    final recorded = <AddFinanceEntry>[];
    await JarvisBankNotices(
      enabled: () => false,
      record: (entry) async => recorded.add(entry),
    ).check();
    expect(recorded, isEmpty);
    expect(forgotten, isEmpty);
  });
}
