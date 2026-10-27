# Phase 4 — Authentication and tenant lifecycle

Scope: GYM-401, GYM-402, GYM-403 and delivery tracking for GYM-490.
The user explicitly narrowed the current work to Phase 4. Phases 5–8 are not
implemented here. Their destinations still display the existing preparation UI.

## Implemented behavior

- Google sign-in uses the installed 7.x API, initializes once after success,
  permits retry after failed initialization, treats cancellation as cancellation,
  and prevents duplicate submissions. Firebase's identity stream owns restoration.
- AuthCubit creates a captured-UID repository per session. It clears tenant state
  before asynchronous disposal, ignores late results from previous identities,
  accepts existing cached settings offline, and offers bounded recovery for an
  empty unverified cache. First setup creates `جيمك` with both prices zero only
  after server-confirmed absence; its provider transaction preserves existing data.
- Authentication guards shell, nested routes and the debug preview. Session
  changes reset navigation, discard old forms/dialogs and close tenant Cubits and
  repository listeners. Providers and Cubits remain above adaptive layout branches.
- Mobile/tablet sign-in shares the action/state and supplied branding. A compact
  shell banner shows observed pending operations and retained rejections, including
  action/name context after a record disappears. It distinguishes local application
  from acknowledgement and makes no whole-account synchronization/connectivity claim.
- Android namespace, application ID, activity path, FlutterFire mappings and fetched
  Google config now agree on `dev.tahahassan.gymk`. Main-manifest INTERNET permission
  is present. Existing logo/icon, project configuration and old Firebase registration
  are preserved. Private release signing replaces the template debug fallback.

## Verification

Environment: Windows, Flutter 3.47.1 / Dart 3.13.1, Medium_Phone Android emulator
`emulator-5554`, Firebase Auth 9099 / Firestore 8080 emulators under `demo-gymk`.
No integration fixture writes to the live Firebase project.

- Formatting: `dart format --output=none --set-exit-if-changed lib test integration_test`.
- Analysis: `flutter analyze --no-pub` reports no issues.
- `flutter test --no-pub`: 113 tests pass, including 27 Phase 4 auth/feedback tests.
  Coverage includes double-submit/cancel/error, cached restoration, confirmed versus
  unverified absence, initial defaults, bootstrap rejection/retry, late old-session
  completion and cleanup. UI checks cover RTL widths 320/599/600/601/768/1024 at
  text scales 1 and 2 in short windows, in-flight action resize, account navigation
  and form reset, setup recovery, persistent feedback and dismissing its message.
- A regression initially exposed an open root-navigator feedback dialog retaining
  the previous account's names. Presentation now removes imperative overlays before
  session navigation; the account-switch regression passes.
- Gradle `:app:signingReport --no-daemon` passes. Debug and release certificates
  match the new app's two remotely registered SHA-1 hashes. Firebase CLI
  `apps:android:sha:list` independently confirms both registrations. The fetched
  `google-services.json` contains both new Android OAuth clients and the web client.
- Final main-entry debug APK build passes using the documented Kotlin workaround.
  Earlier main-entry debug installation/launch succeeded and the phone login screen
  was visually inspected with intact logo and readable Arabic. Native session
  integration rebuilt/installed the same production Android package successfully.
  Final artifact inspection confirms the package/activity, Arabic label, INTERNET
  permission and debug signing certificate. The APK is available at
  `build/app/outputs/flutter-apk/app-debug.apk` for the owner's Google sign-in check.
  There are no keyboard fields on the changed login/setup screens. The widget
  checks and native viewport transition cover the applicable adaptive behavior;
  the complete physical-device UI matrix remains Phase 8.

Native session scenario command:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/auth_session_test.dart -d emulator-5554 --no-pub --android-project-arg=kotlin.incremental=false --android-project-arg=kotlin.compiler.execution.strategy=in-process --no-android-gradle-daemon
```

The actual native Auth/Firestore adapters are used with anonymous **test fixtures**;
the product has no anonymous sign-in action. The scenario checks initial bootstrap,
custom prices surviving a repeated online login and offline session restoration,
cached A records and pending feedback, route/state continuity at tablet width,
then sign-out and account B with no A data, feedback or open dialog. Owned Cubits
close and the old repository releases its cached references. These checks establish
the scoped lifecycle, not the fate of every SDK-queued write after sign-out.

The existing Windows C:/E: Kotlin workaround remains per-command. Firebase
emulators use process-local `JAVA_HOME=E:/Programs/Java/jdk-17`; Gradle uses the
configured Android Studio JBR. No global toolchain settings were changed. The
existing plugin Kotlin-migration warning is nonblocking. Logs/screenshots/APKs
remain ignored under `build/verification/` and `build/app/outputs/`.

## Private signing and remaining verification

Firebase Android app: `1:525961543594:android:e2daf8fbbd33c03209f5d3`.

- Debug SHA-1: `DD:36:5C:1C:85:EC:57:FE:D6:7E:12:96:82:34:FD:4D:B1:2B:14:04`
- Upload SHA-1: `89:E7:8F:D9:AA:32:3E:44:35:2F:AF:44:23:BF:EB:53:EF:83:7A:8A`

Private local keystore: `C:\Users\SAmE7 ELgenDY\.gymk\signing\gymk-upload.jks`,
alias `gymk-upload`. Its generated passwords and path are in ignored
`android/key.properties`. Back up these two private files securely. No passwords,
keystore or private key contents are committed. README documents local setup.

The emulator has no Google accounts. The user explicitly replied, “I will test it
don't worry,” taking responsibility for the remaining real Google sign-in/consent
check. **Actual Google OAuth success is not verified here.** GYM-401 and the full
GYM-490 verification checkpoint therefore remain unchecked pending that result;
the implemented code and available checks can still be committed and pushed.
Configuration agreement and anonymous emulator authentication do not close this gate.

No production rules deployment, release APK verification, store publication,
Phase 7 sign-out warning UX, Phase 8 process-restart/offline matrix, or later gym
feature completion is claimed. The final release artifact remains Phase 8 work.

## Review and delivery

The project Cubit, UI cleanup and read-only review skills were applied with
AGENTS.md precedence. Cubits use typed repositories, immutable independent fields,
owned subscriptions and constructor injection. SDK interaction stays in providers;
localized failures and navigation stay in Presentation. No new dependency,
additional durable store or event-based Bloc is introduced in Phase 4.

Final format/analysis and 113-test suite pass. The native session scenario passes,
including the open-dialog teardown regression. `git diff --check` and the staged
review pass; only Phase 4 files and their documentation are included. Private
signing material is excluded. Implementation SHA/push receipt follows remote
verification; GYM-490 remains open solely for the outstanding Google OAuth result.
