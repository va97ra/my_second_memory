import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  late final Future<void> _loadFuture;

  Future<void> load() => _loadFuture;

  Future<void> _load() async {
    state = _sorted(await _repository.loadAll());
  }

  Future<void> add(FinanceEntry entry) async {
    await _loadFuture;
    state = _sorted([...state, entry]);
    await _repository.replaceAll(state);
    _sync?.financeEntriesChanged();
  }

  Future<void> update(FinanceEntry entry) async {
    await _loadFuture;
    state = _sorted([
      for (final current in state)
        if (current.id == entry.id) entry else current,
    ]);
    await _repository.replaceAll(state);
    _sync?.financeEntriesChanged();
  }

  Future<void> delete(String id) async {
    await _loadFuture;
    final deletedAt = DateTime.now();
    state = [
      for (final entry in state)
        if (entry.id != id) entry
    ];
    await _repository.replaceAll(state);
    await _sync?.financeEntryDeleted(id, deletedAt);
  }

  Future<void> replaceAll(List<FinanceEntry> entries) async {
    await _loadFuture;
    state = _sorted(entries);
    await _repository.replaceAll(state);
  }

  Future<void> replaceAllFromSync(
    List<FinanceEntry> entries, {
    required List<FinanceEntry> baseline,
  }) async {
    await _loadFuture;
    final mergedById = {for (final entry in entries) entry.id: entry};
    final currentById = {for (final entry in state) entry.id: entry};
    final baselineById = {for (final entry in baseline) entry.id: entry};
    for (final id in baselineById.keys) {
      if (!currentById.containsKey(id)) mergedById.remove(id);
    }
    for (final current in currentById.values) {
      final before = baselineById[current.id];
      final changedDuringSync =
          before == null || current.updatedAt.isAfter(before.updatedAt);
      if (!changedDuringSync) continue;
      final incoming = mergedById[current.id];
      if (incoming == null || !incoming.updatedAt.isAfter(current.updatedAt)) {
        mergedById[current.id] = current;
      }
    }
    state = _sorted(mergedById.values.toList(growable: false));
    await _repository.replaceAll(state);
  }

  List<FinanceEntry> _sorted(List<FinanceEntry> entries) {
    return [...entries]..sort((a, b) {
        final date = b.occurredOn.compareTo(a.occurredOn);
        return date != 0 ? date : b.createdAt.compareTo(a.createdAt);
      });
  }
}
