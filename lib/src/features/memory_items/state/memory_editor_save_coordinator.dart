import 'dart:async';

import '../../../core/async/sequential_task_queue.dart';

class MemoryEditorSaveCoordinator {
  MemoryEditorSaveCoordinator({
    this.delay = const Duration(milliseconds: 700),
  });

  final Duration delay;
  final SequentialTaskQueue _queue = SequentialTaskQueue();

  Timer? _timer;
  bool _hasPendingSave = false;
  int _revision = 0;

  int beginSave() {
    _hasPendingSave = false;
    return ++_revision;
  }

  bool isCurrent(int revision) => revision == _revision;

  Future<T> enqueue<T>(Future<T> Function() operation) {
    return _queue.add(operation);
  }

  void schedule({
    required bool canSave,
    required Future<void> Function() save,
  }) {
    _timer?.cancel();
    if (!canSave) return;

    _hasPendingSave = true;
    _timer = Timer(delay, () => unawaited(save()));
  }

  Future<void> flush({
    required bool canSave,
    required Future<void> Function() save,
  }) async {
    _timer?.cancel();
    _timer = null;
    if (_hasPendingSave && canSave) {
      await save();
    }
    await _queue.idle;
  }

  void discardPending() {
    _timer?.cancel();
    _timer = null;
    _hasPendingSave = false;
  }

  void dispose() => discardPending();
}
