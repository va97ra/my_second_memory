create table if not exists public.sync_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  key_salt text not null,
  wrapped_key text not null,
  key_verifier text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.sync_profiles enable row level security;

create policy "users read own sync profile"
on public.sync_profiles for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "users create own sync profile"
on public.sync_profiles for insert
to authenticated
with check ((select auth.uid()) = user_id);

create sequence if not exists public.sync_revision_seq;

create table if not exists public.sync_entities (
  user_id uuid not null references auth.users(id) on delete cascade,
  entity_kind text not null,
  entity_id text not null,
  encrypted_payload text,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  revision bigint not null default nextval('public.sync_revision_seq'),
  primary key (user_id, entity_kind, entity_id),
  constraint sync_entity_kind_supported check (entity_kind in ('memory_item')),
  constraint sync_entity_id_length check (length(entity_id) between 1 and 200),
  constraint sync_payload_or_deletion check (
    encrypted_payload is not null or deleted_at is not null
  )
);

create index if not exists sync_entities_user_revision_idx
on public.sync_entities (user_id, revision);

alter table public.sync_entities enable row level security;

create policy "users read own encrypted sync entities"
on public.sync_entities for select
to authenticated
using ((select auth.uid()) = user_id);

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

revoke all on public.sync_profiles from anon;
revoke all on public.sync_entities from anon;
revoke all on function public.apply_sync_changes(jsonb) from public, anon;
grant select, insert on public.sync_profiles to authenticated;
grant select on public.sync_entities to authenticated;
grant execute on function public.apply_sync_changes(jsonb) to authenticated;

alter table public.sync_entities replica identity full;
alter publication supabase_realtime add table public.sync_entities;
