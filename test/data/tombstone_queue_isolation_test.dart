import 'dart:async';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище, у которого запись зависает: так ведёт себя тест на поддельном
/// времени, не дождавшийся своей очереди.
class _StuckTombstoneStore extends SyncTombstoneStore {
  final stuck = Completer<void>();

  @override
  Future<void> write(
    String userId,
    Map<String, DateTime> values, {
    SyncEntityKind kind = SyncEntityKind.memoryItem,
  }) =>
      stuck.future;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('зависшая запись одного хранилища не держит другое', () async {
    final stuck = _StuckTombstoneStore();
    unawaited(stuck.markDeleted('user', 'a', DateTime.utc(2026, 11, 12)));
    await Future<void>.delayed(Duration.zero);

    final store = SyncTombstoneStore();
    await store
        .markDeleted('user', 'b', DateTime.utc(2026, 11, 12))
        .timeout(const Duration(seconds: 2));

    expect((await store.read('user')).keys, ['b']);
    stuck.stuck.complete();
  });
}
