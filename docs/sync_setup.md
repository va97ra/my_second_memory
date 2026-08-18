# Encrypted synchronization setup

The app keeps plaintext on the device only. Supabase stores encrypted entity
payloads, timestamps, deletion markers, and opaque entity identifiers.

## Supabase project

1. Create a Supabase project.
2. Run `supabase/migrations/202608180001_encrypted_sync.sql` in the SQL editor.
   Existing projects created with the first migration must also run
   `supabase/migrations/202608180002_sync_accounts_and_shifts.sql`.
3. In Authentication, enable email/password sign-in. Decide whether email
   confirmation is required before distributing the app.
4. Enable the Google provider with a Google OAuth Web client. Its authorized
   redirect URI must be the Supabase callback URL shown in the provider form.
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

For public email/password registration, configure a custom SMTP provider in
Authentication > Emails > SMTP Settings. Supabase's built-in mailer is only
suited to testing, accepts a restricted set of recipient addresses, and has a
very low send limit. Signup and resend requests use the app callback URL so a
confirmation link returns to the Sync app.

## Android distributions

Android has two independently installable distributions:

- `simple` — `com.va97ra.ezhednevnikv2`, without cloud synchronization;
- `sync` — `com.va97ra.ezhednevnikv2.sync`, with encrypted synchronization.

The normal Android default is `simple`. Release artifacts can be built with:

```powershell
flutter build apk --release --flavor simple
flutter build apk --release --flavor sync
flutter build appbundle --release --flavor sync
```

Because the package identifiers differ, Android keeps separate local app data
for the two distributions and allows them to be installed side by side.

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
