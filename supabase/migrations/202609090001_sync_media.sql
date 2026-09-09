-- Вложения записей: фотографии и голосовые заметки.
--
-- Слепок записи — короткая строка, снимок — мегабайты, и в одной таблице им
-- не место: синхронизация вычитывает sync_entities целиком на каждом прогоне.
-- Поэтому файлы лежат в приватном бакете, а связывает их с записью имя.
--
-- Байты приезжают уже зашифрованными ключом хранилища, как и слепки записей:
-- сервер их не читает и прочитать не может. Открыто только имя файла —
-- image_<время> или voice_<время>, то есть тип вложения и момент съёмки.

insert into storage.buckets (id, name, public)
values ('sync-media', 'sync-media', false)
on conflict (id) do nothing;

-- Каждый работает только со своей папкой <user_id>/…; первая часть пути и
-- есть опознание владельца.
drop policy if exists "users read own sync media" on storage.objects;
create policy "users read own sync media"
on storage.objects for select
to authenticated
using (
  bucket_id = 'sync-media'
  and (select auth.uid())::text = (storage.foldername(name))[1]
);

drop policy if exists "users upload own sync media" on storage.objects;
create policy "users upload own sync media"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'sync-media'
  and (select auth.uid())::text = (storage.foldername(name))[1]
);

-- Заливка одного и того же имени идёт с upsert: устройство, потерявшее ответ
-- сети, повторит её на следующем прогоне.
drop policy if exists "users replace own sync media" on storage.objects;
create policy "users replace own sync media"
on storage.objects for update
to authenticated
using (
  bucket_id = 'sync-media'
  and (select auth.uid())::text = (storage.foldername(name))[1]
)
with check (
  bucket_id = 'sync-media'
  and (select auth.uid())::text = (storage.foldername(name))[1]
);

drop policy if exists "users delete own sync media" on storage.objects;
create policy "users delete own sync media"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'sync-media'
  and (select auth.uid())::text = (storage.foldername(name))[1]
);
