# Gymk — جيمك

Android Flutter app for a small gym owner, with an Egyptian Arabic RTL interface.
See [docs/PRD.md](docs/PRD.md), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and
[docs/TASKS.md](docs/TASKS.md) for product rules, structure, open decisions and progress.

## Current state

All four gym destinations are implemented: searchable/filterable members,
calendar-month subscriptions and renewal/history correction, daily drop-ins, and
monthly cash collected. Settings edit the gym name and future default prices;
sign-out warns about observed pending changes. Each owner has an isolated tenant.
See [Phase 5](docs/verification/PHASE_5.md),
[Phase 6](docs/verification/PHASE_6.md), and
[Phase 7](docs/verification/PHASE_7.md) for delivered feature checks, and
[Phase 8](docs/verification/PHASE_8.md) for final regression/artifact evidence.
On 29 October 2026 the owner confirmed successful real Google-account login,
session retention after close/reopen and sign-out returning to Login. See the
follow-up in [Phase 4 evidence](docs/verification/PHASE_4.md).

## Local setup and verification

Verified toolchain: Flutter 3.47.1 stable / Dart 3.13.1 with the existing Android SDK
and Gradle configuration.

```powershell
flutter pub get
flutter run
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze --no-pub
flutter test --no-pub
```

Arabic localization is generated from `lib/l10n/app_ar.arb`. Cairo 400/600/700 and
its SIL license are bundled in `assets/fonts/`; that folder's README records the
source. Normal rendering requires no font/image download.

The debug-only `/foundation` component/form preview performs no gym data writes.
The application runtime now guards it with authentication, like the shell routes.

The shell selects mobile below 600 logical pixels and tablet at/above 600 from
bounded available width. Both modes share route history; open forms retain their
body/controllers when the composition changes.

## Android icon and build

`flutter_launcher_icons.yaml` generates Android mipmaps from the supplied opaque
square `assets/images/logo.png`, without adaptive layers or other platforms.

```powershell
flutter pub get
dart run flutter_launcher_icons
flutter build apk --debug --no-pub
```

On Windows, Kotlin incremental compilation can fail when the package cache is on
C: and this workspace is on E:. Project-local `android/gradle.properties` disables
Kotlin incremental compilation and uses the in-process compiler. Ordinary
`flutter run`, IDE launches and builds use these settings automatically. Builds
may take longer; no global toolchain or package versions were changed. The
plugins' future Built-in Kotlin migration warning is separate from that cache
failure and is currently nonblocking.

```powershell
flutter build apk --release
```

When switching from debug/integration builds to release, allow Flutter's normal
dependency/tooling refresh. With this Flutter version, `--no-pub` can retain a
debug-generated Android plugin registrant that references `integration_test`,
while the release Gradle classpath correctly excludes that dev dependency.
The ordinary release command regenerates the release registrant. Keep
`integration_test` in dev_dependencies and never hand-edit generated Java.

## Android identity, Firebase and private signing

The Android namespace/application ID is `dev.tahahassan.gymk`. Firebase project
`gymk-app` registers it as `1:525961543594:android:e2daf8fbbd33c03209f5d3`.
`google-services.json`, `firebase_options.dart` and `firebase.json` agree. The
downloaded Google config preserves the old app registration and includes the new
app's debug/upload Android OAuth clients and web OAuth client.

Registered SHA-1 fingerprints (confirmed against Gradle signingReport):

- Debug: `DD:36:5C:1C:85:EC:57:FE:D6:7E:12:96:82:34:FD:4D:B1:2B:14:04`
- Upload/release: `89:E7:8F:D9:AA:32:3E:44:35:2F:AF:44:23:BF:EB:53:EF:83:7A:8A`

The existing private local signing inputs are:
`C:\Users\SAmE7 ELgenDY\.gymk\signing\gymk-upload.jks`, alias `gymk-upload`.
Ignored `android/key.properties` holds the local path and passwords. Back up both
privately; neither is in Git. On another machine, restore them securely and adjust
`storeFile` in the ignored properties file. Required properties are `storeFile`,
`storePassword`, `keyAlias`, and `keyPassword`. Release tasks require these inputs
and never fall back to debug signing. Debug builds use the existing debug key.

The owner completed the real Google-account Android check on 29 October 2026:
sign in with a real Google account and reach members, close/reopen the application
and confirm the session remains, then sign out from settings and confirm login
returns. The owner's explicit “All three succeeded” is manual runtime evidence;
cancellation/retry and downloaded offline-session behavior also have automated
coverage. This does not claim manual Google testing on every build/device.
No production rules deployment or store publication has been performed or
authorized. Before live business use, production rules need a separately
authorized deployment; local emulator success does not establish deployed rules.

## Product and offline boundaries

- Whole EGP only; default prices may be zero, recorded payments must be positive.
- One calendar month with end-of-month clamping and exclusive expiry. Early
  renewal extends the current continuous expiry. Manual future starts are blocked.
  Gaps/future-only coverage are expired today; corrections preserve other dates.
- Monthly cash uses recorded local payment/session dates, independent of coverage;
  counts are payment records. Edits and permanent deletion revise historical totals.
- Firestore SDK persistence is the only durable application-data store. Already
  downloaded data works offline; an empty unverified cache cannot establish an
  empty gym or zero monthly cash. There is no full-account download guarantee.
- Forms finish after observed local application; persistent shell feedback shows
  observed pending/rejected actions, including after forms close. This is not a
  global connectivity or full-account synchronization indicator. Session notices
  are memory only; SDK pending-write metadata survives process restart.
- Member deletion requires complete loaded history and at most 200 subscriptions
  (201 atomic document deletes). Incomplete/oversized histories are blocked.
  Larger cascades and cross-device coordination are outside MVP. Primarily use
  one phone; last-write-wins does not prevent cross-device business races.
- Signing out disposes tenant memory and routes without clearing SDK persistence
  or promising that pending changes have uploaded. Returning to the same owner
  can resume the SDK queue; another owner never receives their repository paths.

## Isolated Android session verification

Start the Firebase Auth/Firestore emulators against `demo-gymk` (never production).
On this machine, the default Java executable fails; use a process-local JDK:

```powershell
$env:JAVA_HOME='E:/Programs/Java/jdk-17'
$env:PATH="$env:JAVA_HOME/bin;$env:PATH"
firebase emulators:start --only 'auth,firestore' --project demo-gymk --config firebase.json
```

Use a disposable Android emulator with no live gym account/data. Native fixture
targets replace the installed app and normally uninstall it when finished. On
the dedicated verification device `emulator-5556`, in another terminal:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/auth_session_test.dart -d emulator-5556
```

Other native targets cover `data_provider_test.dart`,
`member_subscription_test.dart`, `member_ui_test.dart`, `dropin_report_test.dart`,
and `settings_sign_out_test.dart`. Anonymous identities (and a linked emulator-only
return-account fixture) are test fixtures; product sign-in remains Google only.

Rules tests in `tool/firestore_rules` require `npm ci`, then
`$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'; npm test`.
Run them sequentially with native tests: rules tests clear the demo project data.

The actual process-death suite uses two drive targets with `--keep-app-running`
so Flutter does not uninstall the application and erase its SDK cache:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/offline_restart_seed_test.dart -d emulator-5556 --keep-app-running
firebase emulators:export build/verification/restart-export --project demo-gymk --force
adb -s emulator-5556 shell am force-stop dev.tahahassan.gymk
# Stop the Firebase emulators; retain the exported Auth + Firestore baseline.
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/offline_restart_resume_test.dart -d emulator-5556 --keep-app-running
# When GYMK_RESTART_WAITING_FOR_SERVICES appears, restart services in another
# terminal using the same process-local JDK and --import path:
firebase emulators:start --only 'auth,firestore' --project demo-gymk --config firebase.json --import build/verification/restart-export
```

The resume test first asserts cached records/queued writes while services are
down, then waits up to two minutes for reconnection/server confirmation and
checks rejection rollback. `GYMK_RESTART_VERIFIED` marks success.

To include actual Android airplane mode, add
`--dart-define=GYMK_AIRPLANE_GATE=true` to the seed command. After
`GYMK_RESTART_READY_FOR_AIRPLANE`, acknowledge the test gate from another terminal:

```powershell
adb -s emulator-5556 forward tcp:19877 tcp:9877
adb -s emulator-5556 shell cmd connectivity airplane-mode enable
adb -s emulator-5556 shell svc wifi disable
adb -s emulator-5556 shell svc data disable
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:19877/ready
adb -s emulator-5556 forward --remove tcp:19877
```

Keep airplane mode enabled through force-stop and cached-state restoration.
At the resume marker, disable airplane mode and re-enable Wi-Fi/mobile data
with the corresponding `disable`/`enable` commands before importing services.
These are disposable-device verification steps, not application settings.
If the CLI export stalls while discovering the local hub, its installed local
API can export the same fixture without contacting a production project:

```powershell
$fixtureExport = Join-Path (Get-Location) 'build/verification/restart-export'
$fixtureBody = @{path=$fixtureExport; initiatedBy='gymk-verification'} | ConvertTo-Json
Invoke-RestMethod http://127.0.0.1:4400/_admin/export -Method Post -ContentType application/json -Body $fixtureBody
```

For actual OS size, font scale, rotation and split-screen checks, run
`os_window_test.dart` on the disposable `emulator-5556` with output redirected to
`build/verification/phase8-os-windows.log`. Concurrently run:

```powershell
powershell -File tool/verify_android_windows.ps1 -DeviceId emulator-5556
```

The helper coordinates screenshots after native assertions and restores display
settings. Its last step resizes the actual Android split stage to tablet width;
Android 36's diagnostic split-exit command does not reliably restore stage bounds
in this image. It is deliberately restricted to this disposable device. Full widget
screen/form/dialog tests separately cover widths 320–1280, 599/600/601, RTL,
keyboard insets and 1×/2× text. See the Phase 8 record for actual executed results.
