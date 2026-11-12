-- Ревизии одного пользователя — в порядке фиксации.
--
-- Устройство дочитывает облако по курсору: строки с ревизией больше
-- последней прочитанной. Ревизия берётся из общей последовательности до
-- фиксации транзакции, и два устройства, пишущие одновременно, могли
-- зафиксировать их не по порядку: строка 104 появлялась после 105, и курсор,
-- уже стоящий на 105, её пропускал.
--
-- Блокировка на пользователя ставит записи одного пользователя друг за
-- другом: следующая берёт ревизию уже после фиксации предыдущей. Разные
-- пользователи друг друга не ждут. Тело функции, кроме блокировки, то же,
-- что в 202608180001_encrypted_sync.sql; старые сборки вызывают её так же.

create or replace function public.apply_sync_changes(p_changes jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  change jsonb;
  current_user_id uuid := (select auth.uid());
begin
  if current_user_id is null then
    raise exception 'Authentication is required';
  end if;

  if jsonb_typeof(p_changes) <> 'array' then
    raise exception 'p_changes must be a JSON array';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(current_user_id::text, 0));

  for change in select value from jsonb_array_elements(p_changes)
  loop
    insert into public.sync_entities (
      user_id,
      entity_kind,
      entity_id,
      encrypted_payload,
      updated_at,
      deleted_at
    ) values (
      current_user_id,
      change ->> 'entity_kind',
      change ->> 'entity_id',
      change ->> 'encrypted_payload',
      (change ->> 'updated_at')::timestamptz,
      nullif(change ->> 'deleted_at', '')::timestamptz
    )
    on conflict (user_id, entity_kind, entity_id) do update
    set encrypted_payload = excluded.encrypted_payload,
        updated_at = excluded.updated_at,
        deleted_at = excluded.deleted_at,
        revision = nextval('public.sync_revision_seq')
    where excluded.updated_at >= public.sync_entities.updated_at;
  end loop;
end;
$$;

revoke all on function public.apply_sync_changes(jsonb) from public, anon;
grant execute on function public.apply_sync_changes(jsonb) to authenticated;
