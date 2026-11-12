import 'package:ez_domain/ez_domain.dart';

abstract interface class FinanceRepository {
  Future<List<FinanceEntry>> loadAll();
  Future<void> replaceAll(List<FinanceEntry> entries);

  /// Записывает новые и изменённые операции, не трогая остальные: правка
  /// одной операции не переписывает весь журнал.
  Future<void> upsertAll(List<FinanceEntry> entries);

  Future<void> deleteAll(List<String> ids);
}
