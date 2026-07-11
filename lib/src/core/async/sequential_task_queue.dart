class SequentialTaskQueue {
  Future<void> _tail = Future.value();

  Future<T> add<T>(Future<T> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>((_) {}, onError: (_, __) {});
    return next;
  }

  Future<void> get idle => _tail;
}
