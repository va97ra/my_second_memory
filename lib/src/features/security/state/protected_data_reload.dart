import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounts/accounts.dart';
import '../../memory_items/memory_items.dart';
import '../../recurrence/recurrence.dart';
import '../../shift_schedules/shift_schedules.dart';

/// Перечитывает всё, что хранится под ключом PIN.
///
/// Включение и отключение PIN переписывают защищённые данные новым ключом.
/// До этого вызова репозитории и контроллеры держат в памяти прежние —
/// расшифрованные ключом, которого больше нет.
void reloadProtectedData(WidgetRef ref) {
  ref.invalidate(memoryRepositoryProvider);
  ref.invalidate(memoryItemsControllerProvider);
  ref.invalidate(shiftScheduleRepositoryProvider);
  ref.invalidate(shiftSchedulesControllerProvider);
  ref.invalidate(accountRepositoryProvider);
  ref.invalidate(accountsControllerProvider);
  ref.invalidate(recurrenceRepositoryProvider);
  ref.invalidate(recurrenceExceptionRepositoryProvider);
  ref.invalidate(recurrenceExceptionControllerProvider);
  ref.invalidate(recurrenceSeriesControllerProvider);
}
