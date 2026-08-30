import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

/// Записи и поддельные хранилища для тестов резервной копии.
MemoryItem memoryItem(String id, DateTime date) {
  return MemoryItem(
    id: id,
    type: MemoryType.note,
    title: id,
    memoryDate: date,
    createdAt: date,
    updatedAt: date,
  );
}

ShiftSchedule shiftSchedule(String id, DateTime date) {
  return ShiftSchedule(
    id: id,
    organizationName: id,
    colorValue: 0xFF2563EB,
    startDate: date,
    workDays: 2,
    restDays: 2,
    vacations: [
      ShiftVacation(
        id: '$id-vacation',
        startDate: date.add(const Duration(days: 5)),
        durationDays: 14,
      ),
    ],
  );
}

AccountItem account(String id, DateTime date) {
  return AccountItem(
    id: id,
    serviceName: id,
    login: id,
    password: 'secret',
    createdAt: date,
    updatedAt: date,
  );
}

FinanceEntry financeEntry(String id, DateTime date, {String currency = 'RUB'}) {
  return FinanceEntry(
    id: id,
    kind: FinanceEntryKind.expense,
    amount: '125.50',
    currencyCode: currency,
    category: 'Продукты',
    occurredOn: date,
    createdAt: date,
    updatedAt: date,
  );
}

class FakeMemoryRepository implements MemoryRepository {
  FakeMemoryRepository(this.items);

  List<MemoryItem> items;

  @override
  Future<List<MemoryItem>> loadAll() async => List.of(items);

  @override
  Future<void> upsert(MemoryItem item) async {}

  @override
  Future<void> upsertAll(List<MemoryItem> items) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> replaceAll(List<MemoryItem> items) async {
    this.items = List.of(items);
  }

  @override
  Future<void> close() async {}
}

class FakeShiftRepository implements ShiftScheduleRepository {
  FakeShiftRepository(this.schedules);

  List<ShiftSchedule> schedules;

  @override
  Future<List<ShiftSchedule>> loadSchedules() async => List.of(schedules);

  @override
  Future<void> saveSchedules(List<ShiftSchedule> schedules) async {
    this.schedules = List.of(schedules);
  }
}

class FakeAccountRepository implements AccountRepository {
  FakeAccountRepository(this.accounts);

  List<AccountItem> accounts;

  @override
  Future<List<AccountItem>> loadAccounts() async => List.of(accounts);

  @override
  Future<void> saveAccounts(List<AccountItem> accounts) async {
    this.accounts = List.of(accounts);
  }
}

class FailOnceAccountRepository extends FakeAccountRepository {
  FailOnceAccountRepository(super.accounts);

  bool _shouldFail = true;

  @override
  Future<void> saveAccounts(List<AccountItem> accounts) async {
    if (_shouldFail) {
      _shouldFail = false;
      throw StateError('Simulated account write failure');
    }
    await super.saveAccounts(accounts);
  }
}

class FakeFinanceRepository implements FinanceRepository {
  FakeFinanceRepository(this.entries);

  List<FinanceEntry> entries;

  @override
  Future<List<FinanceEntry>> loadAll() async => List.of(entries);

  @override
  Future<void> replaceAll(List<FinanceEntry> entries) async {
    this.entries = List.of(entries);
  }
}

class FailOnceFinanceRepository extends FakeFinanceRepository {
  FailOnceFinanceRepository(super.entries);

  bool _shouldFail = true;

  @override
  Future<void> replaceAll(List<FinanceEntry> entries) async {
    if (_shouldFail) {
      _shouldFail = false;
      throw StateError('Simulated finance write failure');
    }
    await super.replaceAll(entries);
  }
}

class FakeRecurrenceRepository implements RecurrenceRepository {
  FakeRecurrenceRepository(this.series);

  List<RecurrenceSeries> series;

  @override
  Future<List<RecurrenceSeries>> loadAll() async => List.of(series);

  @override
  Future<void> upsert(RecurrenceSeries series) async {}

  @override
  Future<void> upsertAll(List<RecurrenceSeries> series) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> replaceAll(List<RecurrenceSeries> series) async {
    this.series = List.of(series);
  }

  @override
  Future<void> close() async {}
}
