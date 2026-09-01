-- Прогресс обучения синхронизируется отдельным видом сущности: одна запись
-- на пройденную тему. Пока эта миграция не применена, сервер отвергнет
-- запись такого вида, и синхронизация упадёт целиком — применять до
-- установки сборки, которая её пишет.

alter table public.sync_entities
drop constraint if exists sync_entity_kind_supported;

alter table public.sync_entities
add constraint sync_entity_kind_supported
check (
  entity_kind in (
    'memory_item',
    'shift_schedule',
    'account',
    'recurrence_series',
    'recurrence_exception',
    'finance_entry',
    'tool_calculation',
    'tool_bookmark',
    'learning_progress'
  )
);
