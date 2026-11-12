import 'package:ez_core/ez_core.dart';
import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../app/local_storage_scope_provider.dart';
import '../../security/security.dart';
import '../../sync/sync.dart';
import 'finance_month_ledger.dart';
import 'finance_preferences.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final session = ref.watch(securitySessionProvider);
  final storage = ref.watch(localStorageScopeProvider);
  final plainRepository = storage.financeRepository;
  if (session.hasPin && session.cipher != null) {
    return EncryptedFinanceRepository(
      store: EncryptedJsonStore(cipher: session.cipher!),
      plainRepository: plainRepository,
      backend: storage.secureEntityBackend,
    );
  }
  return plainRepository;
});

final financeControllerProvider =
    StateNotifierProvider<FinanceController, List<FinanceEntry>>((ref) {
  return FinanceController(
    ref.watch(financeRepositoryProvider),
    ref.watch(syncMutationObserverProvider),
  );
});

/// Одна операция по идентификатору: правка другой её карточку не трогает.
final financeEntryByIdProvider =
    Provider.family<FinanceEntry?, String>((ref, id) {
  return ref.watch(
    financeControllerProvider.select((entries) {
      for (final entry in entries) {
        if (entry.id == id) return entry;
      }
      return null;
    }),
  );
});

final financeMonthLedgerProvider = Provider<FinanceMonthLedger>((ref) {
  final currency = ref.watch(financeCurrencyProvider);
  final month = ref.watch(financeMonthProvider);
  final entries = ref.watch(financeControllerProvider);
  return FinanceMonthLedger.build(
    allEntries: entries,
    currencyCode: currency,
    month: month,
  );
});

final visibleFinanceEntriesProvider = Provider<List<FinanceEntry>>((ref) {
  return ref.watch(financeMonthLedgerProvider).entries;
});

final financeSummaryProvider = Provider<FinanceSummary>((ref) {
  return ref.watch(financeMonthLedgerProvider).summary;
});

class FinanceController extends StateNotifier<List<FinanceEntry>> {
  FinanceController(this._repository, [this._sync]) : super(const []) {
    _loadFuture = _load();
  }

  final FinanceRepository _repository;
  final SyncMutationObserver? _sync;

  /// Записи в хранилище идут по одной и в том порядке, в каком сделаны
  /// правки: в хранилище уходит разница, и две правки одной операции,
  /// легшие в обратном порядке, оставили бы старую.
  final _writes = SequentialTaskQueue();
  late final Future<void> _loadFuture;

  Future<void> load() => _loadFuture;

  Future<void> _load() async {
    state = _sorted(await _repository.loadAll());
  }

  Future<void> add(FinanceEntry entry) async {
    await _loadFuture;
    state = _sorted([...state, entry]);
    await _writes.add(() => _repository.upsertAll([entry]));
    _sync?.financeEntriesChanged();
  }

  Future<void> update(FinanceEntry entry) async {
    await _loadFuture;
    state = _sorted([
      for (final current in state)
        if (current.id == entry.id) entry else current,
    ]);
    await _writes.add(() => _repository.upsertAll([entry]));
    _sync?.financeEntriesChanged();
  }

  Future<void> delete(String id) async {
    await _loadFuture;
    final deletedAt = DateTime.now();
    state = [
      for (final entry in state)
        if (entry.id != id) entry
    ];
    await _writes.add(() => _repository.deleteAll([id]));
    await _sync?.financeEntryDeleted(id, deletedAt);
  }

  Future<void> replaceAll(List<FinanceEntry> entries) async {
    await _loadFuture;
    await _replaceState(entries);
  }

  Future<void> replaceAllFromSync(
    List<FinanceEntry> entries, {
    required List<FinanceEntry> baseline,
  }) async {
    await _loadFuture;
    await _replaceState(mergeSyncedEntities(
      incoming: entries,
      current: state,
      baseline: baseline,
      idOf: (entry) => entry.id,
      updatedAtOf: (entry) => entry.updatedAt,
    ));
  }

  /// Подменяет журнал целиком, а в хранилище пишет только разницу. Прежнее
  /// состояние и есть то, что там лежит: каждая правка стоит в очереди
  /// записи вместе с собой.
  Future<void> _replaceState(List<FinanceEntry> entries) async {
    final stored = state;
    state = _sorted(entries);
    final changes = listChanges(
      before: stored,
      after: state,
      idOf: (entry) => entry.id,
      toJson: (entry) => entry.toJson(),
    );
    await _writes.add(() async {
      await _repository.upsertAll(changes.upserts);
      await _repository.deleteAll(changes.removedIds);
    });
  }

  List<FinanceEntry> _sorted(List<FinanceEntry> entries) {
    return [...entries]..sort((a, b) {
        final date = b.occurredOn.compareTo(a.occurredOn);
        return date != 0 ? date : b.createdAt.compareTo(a.createdAt);
      });
  }
}
