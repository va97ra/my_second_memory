import 'package:drift/drift.dart';

@DataClassName('MemoryItemRow')
class MemoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get body => text().withDefault(const Constant(''))();
  IntColumn get timeMinutes => integer().nullable()();
  DateTimeColumn get memoryDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get priority => integer().withDefault(const Constant(0))();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get remindAt => dateTime().nullable()();
  TextColumn get reminderSoundUri => text().nullable()();
  TextColumn get reminderSoundName => text().nullable()();
  TextColumn get repeatRule => text().nullable()();
  TextColumn get projectId => text().nullable()();
  TextColumn get personIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get placeId => text().nullable()();
  TextColumn get audioPath => text().nullable()();
  IntColumn get audioDurationSeconds => integer().nullable()();
  TextColumn get imagePathsJson => text().withDefault(const Constant('[]'))();
  TextColumn get transcript => text().nullable()();
  TextColumn get seriesId => text().nullable()();
  IntColumn get amountMinor => integer().nullable()();
  TextColumn get paymentCategory => text().nullable()();
  IntColumn get birthYear => integer().nullable()();
  BoolColumn get isGeneratedOccurrence =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RecurrenceSeriesRow')
class RecurrenceSeriesRows extends Table {
  TextColumn get id => text()();
  TextColumn get frequency => text()();
  TextColumn get templateJson => text()();
  DateTimeColumn get startDate => dateTime()();
  TextColumn get originItemId => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get generatedThrough => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get historyThrough => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('RecurrenceOccurrenceExceptionRow')
class RecurrenceOccurrenceExceptionRows extends Table {
  TextColumn get id => text()();
  TextColumn get seriesId => text()();
  DateTimeColumn get occurrenceDate => dateTime()();
  TextColumn get kind => text()();
  TextColumn get itemJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SecureEntityRow')
class SecureEntities extends Table {
  TextColumn get kind => text()();
  TextColumn get rowKey => text()();
  TextColumn get lookupKey => text()();
  TextColumn get encryptedPayload => text()();

  @override
  Set<Column<Object>> get primaryKey => {rowKey};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {kind, lookupKey},
      ];
}
