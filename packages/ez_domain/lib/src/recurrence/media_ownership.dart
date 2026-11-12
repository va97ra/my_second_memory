import '../memory/memory_item.dart';
import 'recurrence_occurrence_exception.dart';
import 'recurrence_series.dart';

/// Все ссылки на вложения, которые держат данные человека.
///
/// Фото и голос лежат не только в записях: у повторяющейся записи строки нет,
/// её вложения живут в шаблоне серии, а правка одной даты несёт свои. Кто
/// решает, чей файл, — синхронизация, резервная копия, уборка, шифрование при
/// включении PIN, — спрашивает здесь: правило, которое знает только о
/// записях, теряло вложения повторов во всех пяти местах сразу.
///
/// Удалённое вхождение — отметка `skipped` — помнит запись лишь затем, чтобы
/// узнавать её по исходной дате. Её вложения больше никто не увидит, и
/// владельцем она не считается.
Set<String> mediaReferencesOf({
  required Iterable<MemoryItem> items,
  required Iterable<RecurrenceSeries> series,
  required Iterable<RecurrenceOccurrenceException> exceptions,
}) =>
    {
      for (final item in items) ...item.mediaReferences,
      for (final value in series) ...value.template.mediaReferences,
      for (final exception in exceptions)
        if (!exception.isSkipped) ...?exception.item?.mediaReferences,
    };
