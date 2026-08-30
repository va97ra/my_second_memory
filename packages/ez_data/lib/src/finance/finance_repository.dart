import 'package:ez_domain/ez_domain.dart';

abstract interface class FinanceRepository {
  Future<List<FinanceEntry>> loadAll();
  Future<void> replaceAll(List<FinanceEntry> entries);
}
