/// Хранилище на SQLite.
///
/// Отдельный вход, потому что здесь `dart:ffi` и `dart:io`: в вебе этого нет.
/// Приложение обращается сюда только через фабрику хранилища, которая
/// подключается условным импортом; напрямую этот вход нужен тестам базы.
library;

export 'src/database/app_database.dart';
export 'src/database/drift_secure_entity_backend.dart';
export 'src/database/memory_tables.dart';
export 'src/memory/sqlite_memory_repository.dart';
export 'src/recurrence/sqlite_recurrence_exception_repository.dart';
export 'src/recurrence/sqlite_recurrence_repository.dart';
