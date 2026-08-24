import 'package:ez_data/ez_data.dart';
import 'package:ez_domain/ez_domain.dart';

/// Напоминания записей.
///
/// Ни одна ошибка планировщика не роняет сохранение: запись человека важнее
/// уведомления о ней, а расписание уведомлений всё равно пересобирается при
/// следующем запуске. Поэтому здесь каждый вызов проглатывает свой отказ — и
/// это единственное место, где такое разрешено.
class MemoryReminders {
  const MemoryReminders(this._scheduler);

  final ReminderScheduler? _scheduler;

  Future<void> schedule(MemoryItem item) async {
    try {
      await _scheduler?.schedule(item);
    } catch (_) {
      // Android вправе отказать в уведомлении; запись уже сохранена.
    }
  }

  /// Расставляет напоминания пачке записей, уступая кадр каждые восемь: иначе
  /// загрузка большого списка подвешивает первый экран.
  Future<void> scheduleAll(Iterable<MemoryItem> items) async {
    var scheduled = 0;
    for (final item in items.where(hasFutureReminder)) {
      await schedule(item);
      if (++scheduled % 8 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  Future<void> cancel(String id) async {
    try {
      await _scheduler?.cancel(id);
    } catch (_) {
      // Местные данные всё равно главнее расписания уведомлений.
    }
  }

  Future<void> reconcile(List<MemoryItem> items) async {
    try {
      await _scheduler?.reconcile(items);
    } catch (_) {
      // Следующий запуск или следующая правка повторят пересборку.
    }
  }
}

/// Напоминание имеет смысл только у живой записи и только пока его время не
/// прошло.
bool hasFutureReminder(MemoryItem item) =>
    item.status == MemoryStatus.active &&
    item.remindAt?.isAfter(DateTime.now()) == true;
