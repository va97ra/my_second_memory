# Encrypted synchronization setup

The app keeps plaintext on the device only. Supabase stores encrypted entity
payloads, timestamps, deletion markers, and opaque entity identifiers.

## Supabase project

1. Create a Supabase project.
2. Run every SQL file from `supabase/migrations` in filename order. Existing
   projects must also apply newly added migrations: each of the entity ones
   drops and rebuilds the whole `sync_entity_kind_supported` constraint, so
   running only the newest of those is enough to catch a project up. The
   finance migration is what allows encrypted `finance_entry` rows, and the
   tools migration adds `tool_calculation` and `tool_bookmark`. A missing kind
   is not a partial failure: uploads travel in one `apply_sync_changes` call,
   so a single rejected row aborts the whole run and nothing synchronizes at
   all.

   `202609090001_sync_media.sql` is different and must be applied on its own:
   it creates the private `sync-media` bucket and the four policies that keep
   every account inside its own folder. Without it records still synchronize
   and attachments simply never travel — every run reports the files as
   undelivered.

   Attachments count against a quota of their own. The free Supabase plan has
   two separate ones: 500 MB of database, which is where record snapshots
   live, and 1 GB of file storage, which is where the bucket lives. The
   500 MB shown on the project dashboard is the database and says nothing
   about attachments. Egress on the free plan is 5 GB per month. A few hundred
   phone photographs are enough to reach the 1 GB.
3. In Authentication, enable the Google provider with a Google OAuth Web
   client. Its authorized redirect URI must be the Supabase callback URL shown
   in the provider form. Google is the only way into the cloud: the app has no
   email or password sign-in.
4. Turn on account linking by verified email address. Accounts created by
   email before the app dropped that sign-in keep their data only if a Google
   sign-in with the same address resolves to the same user.
5. Add the following Supabase Auth redirect URL:

```text
io.supabase.ezhednevnik://login-callback/
```

The production project URL and publishable key are bundled in
`SyncBackendConfig`. They are public client values protected by row-level
security. A different Supabase project can still be selected at build time:

```powershell
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=PUBLIC_KEY
```

Use the same defines for Android and release builds. Never put a
`service_role`, Supabase secret key, or Google OAuth client secret in the
application.

Android registers the callback in the single application manifest. The Windows runner
forwards callback launches to the existing tray process, and the Inno Setup
installer registers the custom URI scheme for the current user.

## Android distribution

RuStore takes `com.va97ra.ezhednevnikv2` with encrypted synchronization. The
former `simple` edition was retired on 30 August 2026 and the build has no
flavors left. Release artifacts are built with:

```powershell
flutter build apk --release
flutter build appbundle --release
```

## Security model

- Supabase Auth and row-level security isolate each account.
- A random 256-bit vault key encrypts records with AES-256-GCM before upload.
- The vault key is wrapped by a key derived from the synchronization password.
- Each connected device stores the vault key in platform secure storage.
- The local application PIN remains independent on every device.
- Deletions are synchronized as tombstones so an offline device cannot restore
  deleted records accidentally.

The app synchronizes memory records, shift schedules (including colors,
vacations, and alarm settings), saved accounts, and the attachments of
records — photographs and voice notes.

Attachments travel apart from records. A record snapshot is a short string, a
photograph is megabytes, and they cannot share a table that every run reads in
full: files live in the private `sync-media` bucket and a record points at one
by file name. The name is the same on every device, which is why a record
stores the name and never a path — a path belongs to one device only. Bytes are
encrypted with the vault key before upload, exactly like record snapshots; the
name itself is readable and says only the kind of attachment and the moment it
was taken, which `updated_at` already reveals.

On-device encryption is a separate, local matter: with a PIN set the file is
stored encrypted under the app key, without a PIN it is stored plain, and the
record is not told either way. A failed transfer does not abort the run — the
count of undelivered files is shown next to the last synchronization time and
the next run retries them.

The web build has no files: a photograph there stays a string inside the record
and travels with it.
