import 'dart:async';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:ezhednevnik_v2/src/features/accounts/state/accounts_controller.dart';
import 'package:ezhednevnik_v2/src/features/shift_schedules/state/shift_schedules_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an older account save cannot overwrite a concurrent sync merge',
      () async {
    final repository = _Accounts();
    final controller = AccountsController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    final now = DateTime(2026);
    AccountItem account(String id) => AccountItem(
        id: id,
        serviceName: id,
        login: '',
        password: '',
        createdAt: now,
        updatedAt: now);
    final first = controller.add(account('local'));
    await repository.started.future;
    final second =
        controller.replaceAllFromSync([account('cloud')], baseline: []);
    await Future<void>.delayed(Duration.zero);
    repository.release.complete();
    await Future.wait([first, second]);
    expect(
        repository.saved.map((a) => a.id), unorderedEquals(['local', 'cloud']));
  });

  test('an older shift save cannot overwrite a concurrent sync merge',
      () async {
    final repository = _Shifts();
    final controller = ShiftSchedulesController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    ShiftSchedule shift(String id) => ShiftSchedule(
        id: id,
        organizationName: id,
        colorValue: 0xFF1976D2,
        startDate: DateTime(2026),
        workDays: 1,
        restDays: 3,
        updatedAt: DateTime(2026));
    final first = controller.add(shift('local'));
    await repository.started.future;
    final second =
        controller.replaceAllFromSync([shift('cloud')], baseline: []);
    await Future<void>.delayed(Duration.zero);
    repository.release.complete();
    await Future.wait([first, second]);
    expect(
        repository.saved.map((s) => s.id), unorderedEquals(['local', 'cloud']));
  });
}

class _DelayedStore<T> {
  final started = Completer<void>();
  final release = Completer<void>();
  List<T> saved = [];
  Future<void> save(List<T> items) async {
    if (!started.isCompleted) {
      started.complete();
      await release.future;
    }
    saved = items;
  }
}

class _Accounts extends _DelayedStore<AccountItem>
    implements AccountRepository {
  @override
  Future<List<AccountItem>> loadAccounts() async => saved;
  @override
  Future<void> saveAccounts(List<AccountItem> accounts) => save(accounts);
}

class _Shifts extends _DelayedStore<ShiftSchedule>
    implements ShiftScheduleRepository {
  @override
  Future<List<ShiftSchedule>> loadSchedules() async => saved;
  @override
  Future<void> saveSchedules(List<ShiftSchedule> schedules) => save(schedules);
}
