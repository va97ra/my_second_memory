/// Инфраструктура, общая для всего приложения.
///
/// Здесь нет ни одной продуктовой сущности: только строки интерфейса, выбор
/// локали и последовательная очередь задач. Пакет ничего не знает ни о
/// записях, ни о хранилище.
library;

export 'src/async/sequential_task_queue.dart';
export 'src/format/clock_format.dart';
export 'src/localization/app_strings.dart';
