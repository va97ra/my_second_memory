import '../../../data/database/shared_app_database.dart';
import 'recurrence_repository.dart';
import 'sqlite_recurrence_repository.dart';

RecurrenceRepository createRecurrenceRepository() {
  return SqliteRecurrenceRepository(sharedAppDatabase, false);
}
