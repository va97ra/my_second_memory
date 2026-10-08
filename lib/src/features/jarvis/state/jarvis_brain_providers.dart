import 'package:ez_data/ez_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'jarvis_brain.dart';
import 'jarvis_executor.dart';

/// Как Джарвис обращается к владельцу.
const jarvisAddress = 'сэр';

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
    _load();
  }

  final GigaChatKeyStore _store;

  Future<void> _load() async {
    final key = await _store.read();
    if (mounted) state = AsyncValue.data(key);
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
  final client = GigaChatClient(authKey: key);
  ref.onDispose(client.close);
  return client;
});

/// Нейросеть Джарвиса; без ключа — null, и Джарвис отвечает правилами.
final jarvisBrainProvider = Provider<JarvisBrain?>((ref) {
  final client = ref.watch(gigaChatClientProvider);
  if (client == null) return null;
  return JarvisBrain(client: client, executor: ref.watch(jarvisExecutorProvider));
});
