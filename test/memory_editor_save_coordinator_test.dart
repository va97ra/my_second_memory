import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ezhednevnik_v2/src/features/memory_items/state/memory_editor_save_coordinator.dart';

void main() {
  test('scheduled save runs only when saving is allowed', () async {
    final coordinator = MemoryEditorSaveCoordinator(delay: Duration.zero);
    var saves = 0;

    coordinator.schedule(
      canSave: false,
      save: () async => saves++,
    );
    await Future<void>.delayed(Duration.zero);
    expect(saves, 0);

    coordinator.schedule(
      canSave: true,
      save: () async {
        coordinator.beginSave();
        saves++;
      },
    );
    await Future<void>.delayed(Duration.zero);
    expect(saves, 1);
    coordinator.dispose();
  });

  test('queued saves execute sequentially', () async {
    final coordinator = MemoryEditorSaveCoordinator();
    final firstCanFinish = Completer<void>();
    final order = <String>[];

    final first = coordinator.enqueue(() async {
      order.add('first-start');
      await firstCanFinish.future;
      order.add('first-end');
    });
    final second = coordinator.enqueue(() async => order.add('second'));

    await Future<void>.delayed(Duration.zero);
    expect(order, ['first-start']);
    firstCanFinish.complete();
    await Future.wait([first, second]);
    expect(order, ['first-start', 'first-end', 'second']);
    coordinator.dispose();
  });

  test('only the latest revision is current', () {
    final coordinator = MemoryEditorSaveCoordinator();
    final first = coordinator.beginSave();
    final second = coordinator.beginSave();

    expect(coordinator.isCurrent(first), isFalse);
    expect(coordinator.isCurrent(second), isTrue);
    coordinator.dispose();
  });
}
