import 'dart:async';

import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Что хозяин просил Джарвиса запомнить: «я живу в Казани», «мама любит
/// белые розы». Хранится только на этом телефоне; видно и стирается в
/// настройках Джарвиса.
final jarvisFactsProvider =
    StateNotifierProvider<JarvisFactsController, List<String>>(
  (ref) => JarvisFactsController(),
);

class JarvisFactsController extends StateNotifier<List<String>> {
  JarvisFactsController() : super(const []) {
    _loaded = _load();
  }

  static const _key = 'jarvis_facts_v1';

  /// Больше не нужно: память о человеке, а не дневник.
  static const _limit = 100;

  late final Future<void> _loaded;

  Future<void> _load() async {
    final saved = (await SharedPreferences.getInstance()).getStringList(_key);
    if (mounted && saved != null) state = saved;
  }

  /// Запомнить. То же самое второй раз не дублируется.
  Future<void> add(String fact) async {
    await _loaded;
    final said = fact.trim();
    if (said.isEmpty) return;
    final same = said.toLowerCase();
    final kept = [
      for (final known in state)
        if (known.toLowerCase() != same) known,
      said,
    ];
    await _save(kept.length > _limit ? kept.sublist(kept.length - _limit) : kept);
  }

  /// Забыть то, о чём спросили; возвращает забытое или null.
  Future<String?> forget(String query) async {
    await _loaded;
    final found = state.contains(query) ? query : factFor(query, state);
    if (found == null) return null;
    await _save([
      for (final known in state)
        if (known != found) known,
    ]);
    return found;
  }

  Future<void> _save(List<String> facts) async {
    state = facts;
    await (await SharedPreferences.getInstance()).setStringList(_key, facts);
  }
}
