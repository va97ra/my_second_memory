import 'dart:async';

/// Когда синхронизация запускается сама.
///
/// Три повода: правка в приложении (с задержкой, чтобы не гонять облако на
/// каждую букву), сообщение об изменении с другого устройства и просто время.
class SyncScheduler {
  SyncScheduler({required this.run, required this.canRun});

  final void Function() run;

  /// Пока это неверно, будильники молчат: без ключа и без сети идти некуда.
  final bool Function() canRun;

  static const _defaultDelay = Duration(milliseconds: 900);
  static const _period = Duration(minutes: 2);

  Timer? _debounce;
  Timer? _periodic;
  StreamSubscription<void>? _remoteChanges;

  void schedule([Duration delay = _defaultDelay]) {
    if (!canRun()) return;
    _debounce?.cancel();
    _debounce = Timer(delay, run);
  }

  void cancelPending() => _debounce?.cancel();

  /// Включает самостоятельный запуск: подписку на чужие изменения и повтор по времени.
  void start(Stream<void>? remoteChanges) {
    _remoteChanges?.cancel();
    _remoteChanges = remoteChanges?.listen(
      (_) => schedule(const Duration(milliseconds: 350)),
      onError: (_, __) {},
    );
    _periodic?.cancel();
    _periodic = Timer.periodic(_period, (_) => schedule(Duration.zero));
  }

  void stop() {
    _debounce?.cancel();
    _periodic?.cancel();
    _remoteChanges?.cancel();
    _remoteChanges = null;
  }

  void dispose() => stop();
}
