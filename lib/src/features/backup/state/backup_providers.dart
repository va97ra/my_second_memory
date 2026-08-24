import 'package:ez_data/ez_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/state/accounts_controller.dart';
import '../../memory_items/state/memory_items_controller.dart';
import '../../recurrence/state/recurrence_controller.dart';
import '../../shift_schedules/state/shift_schedules_controller.dart';

/// Резервная копия собирается из тех же репозиториев, с которыми работает
/// приложение, поэтому она видит ровно те данные, что человек видит на экране.
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    memoryRepository: ref.watch(memoryRepositoryProvider),
    shiftScheduleRepository: ref.watch(shiftScheduleRepositoryProvider),
    accountRepository: ref.watch(accountRepositoryProvider),
    recurrenceRepository: ref.watch(recurrenceRepositoryProvider),
    recurrenceExceptionRepository:
        ref.watch(recurrenceExceptionRepositoryProvider),
  );
});

/// Перечитывает всё, что могло замениться при восстановлении.
///
/// Копия пишется прямо в репозитории, мимо контроллеров, поэтому их состояние
/// после восстановления устарело целиком.
void reloadRestoredData(WidgetRef ref) {
  ref.invalidate(memoryItemsControllerProvider);
  ref.invalidate(memoryItemsLoadProvider);
  ref.invalidate(shiftSchedulesControllerProvider);
  ref.invalidate(accountsControllerProvider);
  ref.invalidate(recurrenceExceptionControllerProvider);
  ref.invalidate(recurrenceSeriesControllerProvider);
  ref.invalidate(recurrenceLoadProvider);
}
