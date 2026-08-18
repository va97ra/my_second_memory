alter table public.sync_entities
drop constraint if exists sync_entity_kind_supported;

alter table public.sync_entities
add constraint sync_entity_kind_supported
check (entity_kind in ('memory_item', 'shift_schedule', 'account'));
