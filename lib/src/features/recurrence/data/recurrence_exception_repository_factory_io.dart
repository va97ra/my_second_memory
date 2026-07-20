import '../../../data/database/shared_app_database.dart';
import 'recurrence_exception_repository.dart';
import 'sqlite_recurrence_exception_repository.dart';

RecurrenceExceptionRepository createRecurrenceExceptionRepository() {
  return SqliteRecurrenceExceptionRepository(sharedAppDatabase, false);
}
