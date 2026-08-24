/// Хранение и платформенный ввод-вывод.
///
/// Пакет знает про базу, файлы, шифрование и облако, но ничего не знает про
/// виджеты и маршруты. Riverpod-провайдеры, которые собирают всё это вместе,
/// живут в приложении.
///
/// Реализации под конкретную платформу (`*_io.dart`, `*_web.dart`) наружу не
/// торчат: их подключают условные экспорты внутри пакета.
library;

export 'src/accounts/account_repository.dart';
export 'src/accounts/encrypted_account_repository.dart';
export 'src/accounts/local_account_repository.dart';
export 'src/backup/backup_file_saver.dart';
export 'src/backup/backup_media_store.dart';
export 'src/backup/backup_service.dart';
export 'src/backup/streaming_backup.dart';
export 'src/database/app_database.dart';
export 'src/database/drift_secure_entity_backend.dart';
export 'src/database/memory_tables.dart';
export 'src/media/media_storage.dart';
export 'src/memory/encrypted_memory_repository.dart';
export 'src/memory/local_memory_repository.dart';
export 'src/memory/memory_repository.dart';
export 'src/memory/sqlite_memory_repository.dart';
export 'src/notifications/notification_service.dart';
export 'src/recurrence/encrypted_recurrence_exception_repository.dart';
export 'src/recurrence/encrypted_recurrence_repository.dart';
export 'src/recurrence/local_recurrence_exception_repository.dart';
export 'src/recurrence/local_recurrence_repository.dart';
export 'src/recurrence/recurrence_exception_repository.dart';
export 'src/recurrence/recurrence_repository.dart';
export 'src/recurrence/sqlite_recurrence_exception_repository.dart';
export 'src/recurrence/sqlite_recurrence_repository.dart';
export 'src/security/app_cipher.dart';
export 'src/security/encrypted_json_store.dart';
export 'src/security/secure_entity_backend.dart';
export 'src/security/secure_entity_codec.dart';
export 'src/security/security_data_migration_service.dart';
export 'src/security/security_service.dart';
export 'src/shifts/encrypted_shift_schedule_repository.dart';
export 'src/shifts/local_shift_schedule_repository.dart';
export 'src/shifts/shift_schedule_repository.dart';
export 'src/storage/local_storage_scope.dart';
export 'src/storage/local_storage_scope_factory.dart';
export 'src/sync/app_sync_engine.dart';
export 'src/sync/encrypted_entity_sync_engine.dart';
export 'src/sync/supabase_sync_remote_store.dart';
export 'src/sync/sync_local_store.dart';
export 'src/sync/sync_remote_store.dart';
export 'src/sync/sync_vault_crypto.dart';
