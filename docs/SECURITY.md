# Security & privacy

## Threat model

EarnLens protects against casual access to an unlocked device and accidental exposure (screen
sharing, app switcher, lock-screen notifications). It does not defend against an attacker with
root/jailbreak access or a compromised OS.

## PIN

- 4–8 digits; trivial PINs (repeated digits, straight sequences) are refused.
- Stored only as a verifier: **PBKDF2-HMAC-SHA256, 150,000 iterations, 16-byte random salt per
  PIN**, 256-bit output, in the platform secure store (Android Keystore-backed encrypted prefs,
  iOS Keychain). Derivation runs off the UI thread (`compute`).
- Constant-time comparison.
- Rate limiting persisted in the secure store (survives restarts): 4 free failures, then lockouts of
  30 s, 60 s, 120 s … capped at 1 hour.
- The PIN, amounts and other financial data are never logged.
- Auto-lock: immediately, after 1/5/15 minutes in the background, or only on restart.
- **Forgot PIN**: there is no server, so recovery is either (a) biometric re-authentication (if it
  was enabled) followed by setting a new PIN, or (b) erasing all local data and restoring a backup.
  The UI explains both consequences.

## Account PIN

An individual account can also have its own PIN, on top of the app PIN. Setting one requires an
app PIN.

- It uses the same verifier scheme, rate limiting and lockout as the app PIN, under its own
  secure-store keys (`account.<id>.pin.*`).
- While locked, the account's records are not even loaded (the account scope is empty).
- Combined accounts ask for the PIN of every protected member.
- Unlocks end when the app locks.
- Reminders and the home-screen widget never show a protected account's amounts or names.
- Deleting the account, or "Delete all data", removes its verifier.

Accounts are local data sets, not separate logins or cloud identities. See MULTI_ACCOUNTS.md.

## Biometrics

Optional; offered only when the device supports it and a PIN exists. Enabling it requires a
successful biometric check. On Android the app uses `FlutterFragmentActivity` and AppCompat themes
as required by `local_auth`. Not available on the web (the UI says so).

## Privacy mode

- Amounts are masked (`••••••`) until the user taps the eye icon; masking resets on lock.
- Android: `FLAG_SECURE` hides the app-switcher preview and blocks screenshots.
- All platforms: an overlay covers the UI when the app becomes inactive.
- Notifications and the home-screen widget omit amounts (widget masking is a separate toggle).
- Notifications use private lock-screen visibility on Android.

## Data at rest — residual risk

The PIN controls access to the app UI; **it does not encrypt the database file**. On Android and
iOS the database is inside the app sandbox, protected by OS file-based encryption while the device
is locked. On a rooted device, or on the web (browser storage), the data is readable by anyone with
access to that storage. Mitigations: sandboxing, Android cloud/device-transfer backup disabled for
app data (`data_extraction_rules.xml`, `allowBackup=false`), and encrypted backups. Full database
encryption (SQLCipher) is a documented future option.

## Backups

Optional password → PBKDF2-HMAC-SHA256 (210,000 iterations, random salt) → AES-256-GCM
(authenticated). A wrong password or any modification fails authentication. SHA-256 over the
payload is verified on restore. Losing the password makes the backup unrecoverable — the UI warns.
Backups never contain the PIN.

## Permissions

Android requests only `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` (re-arm reminders) and
`USE_BIOMETRIC`. **No internet permission is declared.** Files are saved/opened through the system
document picker, so no storage permission is needed.

## No tracking

No analytics, crash reporting, advertising SDKs, accounts or remote configuration. Nothing leaves
the device unless the user exports or shares a file.
