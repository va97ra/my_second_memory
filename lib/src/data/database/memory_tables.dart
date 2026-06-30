import 'package:drift/drift.dart';

class MemoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  DateTimeColumn get memoryDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get remindAt => dateTime().nullable()();
  TextColumn get repeatRule => text().nullable()();
  TextColumn get projectId => text().nullable()();
  TextColumn get personIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get placeId => text().nullable()();
  TextColumn get audioPath => text().nullable()();
  IntColumn get audioDurationSeconds => integer().nullable()();
  TextColumn get transcript => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
