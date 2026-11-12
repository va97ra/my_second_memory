import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/finance/state/finance_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Хранилище операций, которое считает полные перезаписи.
class _CountingFinanceRepository implements FinanceRepository {
  _CountingFinanceRepository(this.entries);

  List<FinanceEntry> entries;
  var replaceAllCount = 0;

  @override
  Future<List<FinanceEntry>> loadAll() async => List.of(entries);

  @override
  Future<void> replaceAll(List<FinanceEntry> entries) async {
    replaceAllCount++;
    this.entries = List.of(entries);
  }

  @override
  Future<void> upsertAll(List<FinanceEntry> incoming) async {
    // Медленная запись: следующая правка успевает встать за ней в очередь.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final byId = {
      for (final entry in entries) entry.id: entry,
      for (final entry in incoming) entry.id: entry,
    };
    entries = byId.values.toList();
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    final removed = ids.toSet();
    entries = [
      for (final entry in entries)
        if (!removed.contains(entry.id)) entry,
    ];
  }
}

/// О3 для финансов: одна операция — одна запись в хранилище, а не
/// перезапись всего журнала. При PIN это ещё и новое шифрование каждой
/// операции на каждое нажатие.
void main() {
  final date = DateTime(2026, 11, 12, 9);

  FinanceEntry entry(int index, {String amount = '100'}) => FinanceEntry(
        id: 'entry-$index',
        kind: FinanceEntryKind.expense,
        amount: amount,
        currencyCode: 'RUB',
        category: 'Продукты',
        occurredOn: date,
        createdAt: date,
        updatedAt: date,
      );

  Future<(FinanceController, _CountingFinanceRepository)> loaded() async {
    final repository = _CountingFinanceRepository([
      for (var index = 0; index < 500; index++) entry(index),
    ]);
    final controller = FinanceController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    return (controller, repository);
  }

  test('adding one operation does not rewrite the journal', () async {
    final (controller, repository) = await loaded();

    await controller.add(entry(500));

    expect(repository.replaceAllCount, 0);
    expect(repository.entries, hasLength(501));
  });

  test('editing and deleting one operation do not rewrite the journal',
      () async {
    final (controller, repository) = await loaded();

    await controller.update(entry(3, amount: '250'));
    await controller.delete('entry-4');

    expect(repository.replaceAllCount, 0);
    expect(repository.entries, hasLength(499));
    expect(
      repository.entries.singleWhere((value) => value.id == 'entry-3').amount,
      '250',
    );
  });

  test('a merge from the cloud writes only what changed', () async {
    final (controller, repository) = await loaded();
    final edited = entry(9, amount: '900').copyWith(
      updatedAt: date.add(const Duration(minutes: 1)),
    );

    await controller.replaceAllFromSync(
      [
        for (final value in controller.state)
          if (value.id == edited.id) edited else value,
      ],
      baseline: List.of(controller.state),
    );

    expect(repository.replaceAllCount, 0);
    expect(
      repository.entries.singleWhere((value) => value.id == edited.id).amount,
      '900',
    );
  });

  test('two quick edits of one operation land in the order they were made',
      () async {
    final (controller, repository) = await loaded();

    final first = controller.update(entry(1, amount: '111'));
    final second = controller.update(entry(1, amount: '222'));
    await Future.wait([first, second]);

    expect(
      repository.entries.singleWhere((value) => value.id == 'entry-1').amount,
      '222',
    );
  });
}
