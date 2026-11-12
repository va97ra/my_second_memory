import 'package:ez_domain/ez_domain.dart';

/// Журнал после записи [incoming] — для хранилищ, которые держат его одним
/// списком и иначе как целиком записать не умеют.
List<FinanceEntry> upsertedEntries(
  List<FinanceEntry> stored,
  List<FinanceEntry> incoming,
) =>
    {
      for (final entry in stored) entry.id: entry,
      for (final entry in incoming) entry.id: entry,
    }.values.toList();

/// Журнал без операций [ids].
List<FinanceEntry> withoutEntries(List<FinanceEntry> stored, List<String> ids) {
  final removed = ids.toSet();
  return [
    for (final entry in stored)
      if (!removed.contains(entry.id)) entry,
  ];
}
