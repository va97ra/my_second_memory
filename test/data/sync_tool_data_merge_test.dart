import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/sync_test_support.dart';

void main() {
  test('a renamed calculation wins and its payload stays encrypted', () async {
    final remote = SyncRemote();
    final key = List<int>.generate(32, (index) => index + 3);
    final firstCipher = AppCipher.fromKeyBytes(key);
    final secondCipher = AppCipher.fromKeyBytes(key);
    addTearDown(firstCipher.destroy);
    addTearDown(secondCipher.destroy);
    final created = DateTime.utc(2026, 8, 30, 10);
    var first = [_calculation('shared', 'Кабель на кухню', created)];
    var second = <SavedToolCalculation>[];

    await _runCalculations(remote, firstCipher, first, (v) => first = v);
    await _runCalculations(remote, secondCipher, second, (v) => second = v);
    second = [
      second.single.copyWith(
        name: 'Кабель на кухню и балкон',
        updatedAt: created.add(const Duration(minutes: 1)),
      ),
    ];
    await _runCalculations(remote, secondCipher, second, (v) => second = v);
    await _runCalculations(remote, firstCipher, first, (v) => first = v);

    expect(first.single.name, 'Кабель на кухню и балкон');
    final stored = remote.storedEntities['tool_calculation:shared']!;
    expect(stored.kind, SyncEntityKind.toolCalculation);
    expect(stored.encryptedPayload, isNot(contains('Кабель')));
  });

  test('a deleted calculation does not come back from another device',
      () async {
    final remote = SyncRemote();
    final key = List<int>.generate(32, (index) => index + 7);
    final firstCipher = AppCipher.fromKeyBytes(key);
    final secondCipher = AppCipher.fromKeyBytes(key);
    final firstTombstones = MemoryTombstoneStore();
    final secondTombstones = MemoryTombstoneStore();
    addTearDown(firstCipher.destroy);
    addTearDown(secondCipher.destroy);
    final created = DateTime.utc(2026, 8, 30, 12);
    var first = [_calculation('gone', 'Черновик', created)];
    var second = <SavedToolCalculation>[];

    await _runCalculations(
      remote,
      firstCipher,
      first,
      (v) => first = v,
      tombstones: firstTombstones,
    );
    await _runCalculations(
      remote,
      secondCipher,
      second,
      (v) => second = v,
      tombstones: secondTombstones,
    );
    first = [];
    await firstTombstones.markDeleted(
      'user',
      'gone',
      created.add(const Duration(minutes: 1)),
      kind: SyncEntityKind.toolCalculation,
    );
    await _runCalculations(
      remote,
      firstCipher,
      first,
      (v) => first = v,
      tombstones: firstTombstones,
    );
    await _runCalculations(
      remote,
      secondCipher,
      second,
      (v) => second = v,
      tombstones: secondTombstones,
    );

    expect(second, isEmpty);
    expect(remote.storedEntities['tool_calculation:gone']!.isDeleted, isTrue);
  });
}

Future<void> _runCalculations(
  SyncRemote remote,
  AppCipher cipher,
  List<SavedToolCalculation> calculations,
  void Function(List<SavedToolCalculation>) replace, {
  MemoryTombstoneStore? tombstones,
}) {
  return sync(
    remote: remote,
    cipher: cipher,
    tombstones: tombstones ?? MemoryTombstoneStore(),
    toolCalculations: calculations,
    replaceToolCalculations: (value) async => replace(value),
    shifts: const [],
    replaceShifts: (_) async {},
    accounts: const [],
    replaceAccounts: (_) async {},
  ).then((_) {});
}

SavedToolCalculation _calculation(String id, String name, DateTime date) {
  return SavedToolCalculation(
    id: id,
    name: name,
    payload: const SavedConversionPayload(
      category: 'length',
      fromUnit: 'm',
      toUnit: 'cm',
      value: 3.6,
    ),
    createdAt: date,
    updatedAt: date,
  );
}
