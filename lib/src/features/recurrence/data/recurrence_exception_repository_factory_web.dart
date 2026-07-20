import 'local_recurrence_exception_repository.dart';
import 'recurrence_exception_repository.dart';

RecurrenceExceptionRepository createRecurrenceExceptionRepository() {
  return const LocalRecurrenceExceptionRepository();
}
