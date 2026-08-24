import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// По умолчанию наблюдатель ничего не делает: приложение без синхронизации
/// обязано работать полностью. `main` подменяет его, когда sync включён.
final syncMutationObserverProvider = Provider<SyncMutationObserver>(
  (ref) => const NoopSyncMutationObserver(),
);
