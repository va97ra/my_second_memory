import 'local_recurrence_repository.dart';
import 'recurrence_repository.dart';

RecurrenceRepository createRecurrenceRepository() {
  return const LocalRecurrenceRepository();
}
