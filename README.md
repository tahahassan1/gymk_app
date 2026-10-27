# Gymk — جيمك

Android Flutter app for a small gym owner, with an Egyptian Arabic RTL interface.
See [docs/PRD.md](docs/PRD.md), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and
[docs/TASKS.md](docs/TASKS.md) for product rules, structure, open decisions and progress.

## Current state

Phases 1–3 provide the Arabic adaptive foundation, calendar/coverage and whole-EGP
policies, and tenant-scoped Firestore repositories with offline mutation tracking.
Phase 4 adds Google/Firebase authentication, restored sessions, safe first-account
settings, tenant routing and persistent pending/rejection feedback. The owner will
perform the remaining real Google sign-in check; see
[Phase 4 evidence](docs/verification/PHASE_4.md) for its exact verification status.
Gym feature destinations remain explicit scaffolding for Phases 5–7. Work stops
after Phase 4; this is not a release-ready complete gym-management app.

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

On this Windows machine, Kotlin incremental compilation failed with the package
cache on C: and workspace on E:. This per-command workaround avoids changing
project Gradle versions or global configuration:

```powershell
flutter build apk --debug --no-pub --android-project-arg=kotlin.incremental=false --android-project-arg=kotlin.compiler.execution.strategy=in-process --no-android-gradle-daemon
```

## Android identity, Firebase and private signing

The Android namespace/application ID is `dev.tahahassan.gymk`. Firebase project
`gymk-app` registers it as `1:525961543594:android:e2daf8fbbd33c03209f5d3`.
`google-services.json`, `firebase_options.dart` and `firebase.json` agree. The
downloaded Google config preserves the old app registration and includes the new
app's debug/upload Android OAuth clients and web OAuth client.

Registered SHA-1 fingerprints (confirmed against Gradle signingReport):

- Debug: `DD:36:5C:1C:85:EC:57:FE:D6:7E:12:96:82:34:FD:4D:B1:2B:14:04`
- Upload/release: `89:E7:8F:D9:AA:32:3E:44:35:2F:AF:44:23:BF:EB:53:EF:83:7A:8A`

Private local signing inputs were created because no keystore existed:
`C:\Users\SAmE7 ELgenDY\.gymk\signing\gymk-upload.jks`, alias `gymk-upload`.
Ignored `android/key.properties` holds the local path and passwords. Back up both
privately; neither is in Git. On another machine, restore them securely and adjust
`storeFile` in the ignored properties file. Required properties are `storeFile`,
`storePassword`, `keyAlias`, and `keyPassword`. Release tasks require these inputs
and never fall back to debug signing. Debug builds use the existing debug key.

Actual Google consent/sign-in remains the owner's manual check on Android. Verify
entry into the shell, cancel/retry, then restart offline after settings have been
downloaded. A configuration match or emulator-auth test does not prove live OAuth.
No production rules deployment or store publication has been performed. Final
release-artifact verification remains Phase 8.

## Isolated Android session verification

Start the Firebase Auth/Firestore emulators against `demo-gymk` (never production).
On this machine, the default Java executable fails; use a process-local JDK:

```powershell
$env:JAVA_HOME='E:/Programs/Java/jdk-17'
$env:PATH="$env:JAVA_HOME/bin;$env:PATH"
firebase emulators:start --only 'auth,firestore' --project demo-gymk --config firebase.json
```

With Android emulator `emulator-5554` running, in another terminal:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/auth_session_test.dart -d emulator-5554 --no-pub --android-project-arg=kotlin.incremental=false --android-project-arg=kotlin.compiler.execution.strategy=in-process --no-android-gradle-daemon
```

This uses anonymous identities only as isolated test fixtures. Product sign-in is
Google only. Tests cover safe bootstrap, repeated login, offline restoration,
pending changes, resize and account-scope teardown; they do not claim real OAuth
or process-restart/full-app offline verification.
