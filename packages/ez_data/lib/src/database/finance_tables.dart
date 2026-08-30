import 'package:drift/drift.dart';

@DataClassName('FinanceEntryRow')
class FinanceEntries extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get amount => text()();
  TextColumn get currencyCode => text()();
  TextColumn get category => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get occurredOn => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
