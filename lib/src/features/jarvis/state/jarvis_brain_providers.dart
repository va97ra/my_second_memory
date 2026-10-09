import 'dart:async';

import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart' show jarvisAddress;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gigachat_limit.dart';
import 'jarvis_brain.dart';
import 'jarvis_executor.dart';
import 'jarvis_online.dart';

/// Руки Джарвиса — одни на правила и на нейросеть.
final jarvisExecutorProvider = Provider<JarvisExecutor>((ref) {
  return JarvisExecutor(ref, address: jarvisAddress);
});

final gigaChatKeyStoreProvider = Provider<GigaChatKeyStore>((ref) {
  return GigaChatKeyStore();
});

/// Ключ GigaChat: null — нейросеть не подключена.
final gigaChatKeyProvider =
    StateNotifierProvider<GigaChatKeyController, AsyncValue<String?>>((ref) {
  return GigaChatKeyController(ref.watch(gigaChatKeyStoreProvider));
});

class GigaChatKeyController extends StateNotifier<AsyncValue<String?>> {
  GigaChatKeyController(this._store) : super(const AsyncValue.loading()) {
    _loading = _load();
  }

  final GigaChatKeyStore _store;
  late final Future<void> _loading;

  /// Ключ прочитан с диска. Защищённое хранилище отвечает не сразу, и
  /// пока оно молчит, «ключа нет» — неправда.
  Future<void> get ready => _loading;

  /// Хранилище может отказать (сломанный ключ шифрования после переноса
  /// данных). Тогда ключ — ошибка с причиной, её видно в настройках, а
  /// Джарвис отвечает без нейросети, а не падает на каждой фразе.
  Future<void> _load() async {
    final key = await AsyncValue.guard(() async {
      final stored = await _store.read();
      // Сохранённое ключом не является (текст, попавший в поле): такой
      // «ключ» не отправить даже в заголовке. Его показывают как ошибку, а
      // поле для настоящего ключа открыто.
      if (stored != null && !GigaChatClient.looksLikeAuthKey(stored)) {
        throw const GigaChatException('сохранён не ключ — вставьте заново');
      }
      return stored;
    });
    if (mounted) state = key;
  }

  Future<void> save(String key) async {
    await _store.save(key);
    if (mounted) state = AsyncValue.data(key.trim());
  }

  Future<void> remove() async {
    await _store.delete();
    if (mounted) state = const AsyncValue.data(null);
  }
}

/// Клиент GigaChat для сохранённого ключа; без ключа — null.
final gigaChatClientProvider = Provider<GigaChatClient?>((ref) {
  final key = ref.watch(gigaChatKeyProvider).valueOrNull;
  if (key == null) return null;
  final client = GigaChatClient(
    authKey: key,
    onUsage: (tokens) {
      final limit = ref.read(gigaChatLimitProvider.notifier);
      unawaited(limit.spent(tokens));
      unawaited(limit.refresh());
    },
  );
  ref.onDispose(client.close);
  return client;
});

/// Нейросеть Джарвиса; без ключа — null, и Джарвис отвечает правилами.
final jarvisBrainProvider = Provider<JarvisBrain?>((ref) {
  final client = ref.watch(gigaChatClientProvider);
  if (client == null) return null;
  return JarvisBrain(
    client: client,
    executor: ref.watch(jarvisExecutorProvider),
    online: ref.watch(jarvisOnlineProvider),
  );
});
