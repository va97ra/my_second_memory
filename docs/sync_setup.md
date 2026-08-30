# Encrypted synchronization setup

The app keeps plaintext on the device only. Supabase stores encrypted entity
payloads, timestamps, deletion markers, and opaque entity identifiers.

## Supabase project

1. Create a Supabase project.
2. Run every SQL file from `supabase/migrations` in filename order. Existing
   projects must also apply newly added migrations; the finance migration is
   what allows encrypted `finance_entry` rows and their deletion tombstones.
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

Android registers the callback only for the `sync` flavor. The Windows runner
forwards callback launches to the existing tray process, and the Inno Setup
installer registers the custom URI scheme for the current user.

## Android distribution

RuStore uses the `sync` flavor (`com.va97ra.ezhednevnikv2`) with encrypted
synchronization. The former `simple` edition is no longer a release target.
Release artifacts are built with:

```powershell
flutter build apk --release --flavor sync
flutter build appbundle --release --flavor sync
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
vacations, and alarm settings), and saved accounts. Account fields remain
encrypted with the vault key. Media files themselves remain device-local;
record metadata and local media paths can synchronize, but another device
cannot download a file that was never uploaded.
