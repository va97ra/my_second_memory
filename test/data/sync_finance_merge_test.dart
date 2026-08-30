import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sync_test_support.dart';

void main() {
  test('finance edits use latest updatedAt and remain encrypted', () async {
    final remote = SyncRemote();
    final key = List<int>.generate(32, (index) => index + 1);
    final firstCipher = AppCipher.fromKeyBytes(key);
    final secondCipher = AppCipher.fromKeyBytes(key);
    addTearDown(firstCipher.destroy);
    addTearDown(secondCipher.destroy);
    final created = DateTime.utc(2026, 8, 30, 10);
    var first = [_entry('shared', '10', created)];
    var second = <FinanceEntry>[];

    await _run(remote, firstCipher, first, (value) => first = value);
    await _run(remote, secondCipher, second, (value) => second = value);
    second = [
      second.single.copyWith(
        amount: '12.50',
        updatedAt: created.add(const Duration(minutes: 1)),
      ),
    ];
    await _run(remote, secondCipher, second, (value) => second = value);
    await _run(remote, firstCipher, first, (value) => first = value);

    expect(first.single.amount, '12.5');
    final stored = remote.storedEntities['finance_entry:shared']!;
    expect(stored.kind, SyncEntityKind.financeEntry);
    expect(stored.encryptedPayload, isNot(contains('12.5')));
  });

  test('finance tombstone removes a stale entry on another device', () async {
    final remote = SyncRemote();
    final key = List<int>.generate(32, (index) => index + 11);
    final firstCipher = AppCipher.fromKeyBytes(key);
    final secondCipher = AppCipher.fromKeyBytes(key);
    final firstTombstones = MemoryTombstoneStore();
    final secondTombstones = MemoryTombstoneStore();
    addTearDown(firstCipher.destroy);
    addTearDown(secondCipher.destroy);
    final created = DateTime.utc(2026, 8, 30, 10);
    var first = [_entry('deleted', '25', created)];
    var second = <FinanceEntry>[];

    await _run(
      remote,
      firstCipher,
      first,
      (value) => first = value,
      tombstones: firstTombstones,
    );
    await _run(
      remote,
      secondCipher,
      second,
      (value) => second = value,
      tombstones: secondTombstones,
    );
    first = [];
    await firstTombstones.markDeleted(
      'user',
      'deleted',
      created.add(const Duration(minutes: 1)),
      kind: SyncEntityKind.financeEntry,
    );
    await _run(
      remote,
      firstCipher,
      first,
      (value) => first = value,
      tombstones: firstTombstones,
    );
    await _run(
      remote,
      secondCipher,
      second,
      (value) => second = value,
      tombstones: secondTombstones,
    );

    expect(second, isEmpty);
    expect(remote.storedEntities['finance_entry:deleted']!.isDeleted, isTrue);
  });
}

Future<void> _run(
  SyncRemote remote,
  AppCipher cipher,
  List<FinanceEntry> entries,
  void Function(List<FinanceEntry>) replace, {
  MemoryTombstoneStore? tombstones,
}) {
  return sync(
    remote: remote,
    cipher: cipher,
    tombstones: tombstones ?? MemoryTombstoneStore(),
    financeEntries: entries,
    replaceFinanceEntries: (value) async => replace(value),
    shifts: const [],
    replaceShifts: (_) async {},
    accounts: const [],
    replaceAccounts: (_) async {},
  ).then((_) {});
}

FinanceEntry _entry(String id, String amount, DateTime date) => FinanceEntry(
      id: id,
      kind: FinanceEntryKind.expense,
      amount: amount,
      currencyCode: 'RUB',
      category: 'Продукты',
      occurredOn: date,
      createdAt: date,
      updatedAt: date,
    );
