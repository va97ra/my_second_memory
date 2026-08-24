import 'memory_item.dart';
import 'memory_status.dart';

/// Ждёт ли запись напоминания.
///
/// Напоминание имеет смысл только у живой записи и только в будущем:
/// выполненная или архивная запись напоминать о себе не должна, а прошедшее
/// время уже не наступит.
bool wantsReminder(MemoryItem item, {DateTime? now}) {
  final remindAt = item.remindAt;
  return item.status == MemoryStatus.active &&
      remindAt != null &&
      remindAt.isAfter(now ?? DateTime.now());
}

/// Откуда взялось напоминание: у обычной записи и у вхождения повтора разные
/// источники, и согласование каждого не должно трогать чужие.
abstract final class ReminderSource {
  static const memory = 'memory_reminder';
  static const recurrence = 'recurrence_reminder';

  /// Источник, к которому относится запись.
  ///
  /// К повторам относится только спроецированное вхождение. Сама запись,
  /// ставшая шаблоном серии, остаётся обычной: её напоминание согласуется
  /// вместе с остальными записями, а не с проекциями.
  static String of(MemoryItem item) =>
      item.isGeneratedOccurrence && item.seriesId != null
          ? recurrence
          : memory;
}
