# Phase 8 — Final regression and Android artifact evidence

Verification date: 29 October 2026. This record extends the delivered Phase 5–7
receipts; it does not replace their results or claim a production deployment.

## Scope and fixes

All four gym destinations are implemented. Phase 8 adds process-death/offline and
cross-feature regression evidence, and fixes failures exposed by those checks:

- An uncertain local-observation error no longer causes a retry to recapture a
  payment date, submit again through a still-held member gate, or remain stuck
  after acknowledgement. Forms reuse the submitted handle and immutable intent;
  inputs stay read-only until the outcome permits editing. Member locks release
  on actual local settlement/remote outcome, not uncertain observation failure.
- Settings preserve a retryable desired draft after late rejection, including
  rejection following uncertain local observation.
- Cubits close their emission stream before awaiting listener cleanup, preventing
  late events during tenant teardown. Owned listeners/timers still cancel.
- Search keeps its focused subtree across layout replacement. The member picker
  bounds long names and exposes the complete name through a tooltip/semantics.
- The persistent pending/rejection strip bounds text, retains an accessible
  details action, and scrolls within a bounded fraction of short shell height.
  Cached content and keyboard-open forms remain usable at large text sizes.
- Project-local Kotlin settings fix ordinary Windows builds when the package
  cache and workspace reside on different drives. Dependencies, Android/Firebase
  identity, signing inputs and approved artwork remain unchanged.

## Environment and isolation

Flutter 3.47.1 / Dart 3.13.1; Android SDK `E:/Programs/Android`; Android 36 Google
APIs/Play Store x86_64 emulator. The separately created, disposable
`Gymk_Verify_976635f4` AVD runs on `emulator-5556`; its files are under
`E:/taha/gymk-phase8-device-976635f4/avd`. The owner's other AVD/configuration and
Google-test installation were not used for fixture writes.
The verification AVD was stopped after checks. Automatic approval review rejected
removal of its temporary files with `blocked by policy`; those files are retained.
The original AVD/configuration remains untouched.

Firebase CLI 14.2.0 uses process-local JDK 17. Auth 9099 and Firestore 8080 bind
locally for **demo-gymk**, never live business data. Gradle retains the configured
Android Studio JBR. Anonymous/linked return-account identities are emulator-only
fixtures; product sign-in is Google only. Logs, exports, screenshots and APKs are
ignored under `build/verification/` or the normal Flutter output directories.

## Offline process restart and recovery

Both seed and resume targets pass. A second executed cycle also enables actual
Android airplane mode and explicitly disables Wi-Fi/mobile data before offline
mutations. `settings get global airplane_mode_on` returned `1`. Only an
ADB-forwarded test acknowledgement allows the seed target to continue after that
OS change. The resume process starts while airplane mode is still enabled and
both local Firebase services are stopped.

The scenario downloads settings, two members, subscription history and drop-ins,
then offline edits a member, creates another with a stable intent, renews early,
corrects/moves a drop-in across the month boundary, creates/deletes drop-ins, and
atomically deletes a member with their complete history. The host force-stops the
Android process. A different APK entry point restores Auth/Firestore persistence
without any test-side durable queue, ID file or second store.

Before reconnection, assertions verify two members/two subscriptions/two drop-ins,
the edited member, cascade removal, pending SDK metadata, unverified cache
completeness, preserved dates and November cash **215 EGP**. Coverage ends
exclusively on 26 December; the early-renewal payment remains 10 November. The
unverified restored cache correctly blocks a destructive member cascade.
Session operation notices are empty after process death, while SDK pending-write
metadata survives; neither is represented as a global synchronization count.

After the cached-state marker, the host disables airplane mode, restores radios
and imports the exported Auth/Firestore baseline. Explicit server reads confirm
the exact final records/counts, including one renewal rather than a duplicate.
An immutable-payment-date violation then applies locally, is rejected by rules,
rolls back and remains visible as an affected-action rejection after the form's
lifetime. November cash returns to 215 EGP.

Executed markers: `GYMK_RESTART_SEEDED`,
`GYMK_RESTART_WAITING_FOR_SERVICES`, `GYMK_RESTART_VERIFIED`; the final airplane
resume reports all tests passed. Logs: `phase8-airplane-seed.log`,
`phase8-airplane-state.txt`, `phase8-airplane-resume.log`, and the earlier
`phase8-restart-seed.log` / `phase8-restart-resume.log`.

Reproduction commands and the optional airplane gate are in README. Important
harness corrections: `flutter drive` normally uninstalls the app after completion;
`--keep-app-running` is required for both restart entry points to preserve SDK
storage. An earlier run without it could not restore the session and is not
treated as an application persistence failure. The CLI export's local hub
discovery stalled in this environment; the installed hub's local export endpoint
successfully exported the same demo fixture, with response `{"message":"OK"}`.

## UI and state matrix

`app_full_matrix_test.dart` executes every primary screen and ordinary
create/edit/delete-confirmation flow at all widths below, with text scales 1× and
2× (20 combinations). Every combination passes. It covers Arabic/RTL, long names,
mixed-direction phone/date/money fields, keyboard insets, picker/date/month
dialogs, validation, local saves, exact cash, settings and pending sign-out stay.

| Widths (logical pixels) | Executed coverage |
| --- | --- |
| 320, 360, 390, 430 | All screens, forms and relevant dialogs, at 1×/2× text |
| 599, 600, 601 | Same matrix across the mobile/tablet threshold |
| 768, 1024, 1280 | Same matrix in tablet composition |
| 840×390, 2×, keyboard 280 | Short landscape with observed pending feedback and open form |

Additional tests distinguish initial supplied Lottie loading, unverified empty
cache, cached read errors, confirmed empty, incomplete drop-ins and incomplete
report totals without authoritative zero. Foundation tests cover reduced-motion
static artwork. Representative Android tap-target/labeled-target semantics checks
pass. Focused feature tests preserve query/filter, selected member/day/month,
controllers, operation IDs and pending state across resize. A 400-member lazy
list retains its 1800px scroll position through 599→600→1024→601→599 without writes.
No per-row SDK query was introduced; the session repository still owns four
shared source streams, checked by repository lifetime tests.

Native OS window verification uses actual `wm` size/density, Android font scale,
rotation and split-screen; it does not override TestFlutterView dimensions.
The host captures display PNGs only after native assertions and validates PNG
dimensions. A real OS tap opens the Android keyboard, and native inset assertions
verify it is present. Source: `os_window_test.dart` and
`tool/verify_android_windows.ps1`.

Intermediate harness findings are retained honestly: a boot-time System UI ANR
obscured initial screenshots, so those images were rejected and the system dialog
was dismissed before clean rechecks. Continuing frame pumping while awaiting host
screenshots avoids stale compositor frames during rotation. Android 36's
diagnostic `exitSplitScreen` left inactive stage bounds, and a divider gesture
did not reliably restore the task in this image. The final matrix resizes the
actual split display from 1024 to 2048 pixels and explicitly resizes its Android
stage with `am task resize` (507→1019 logical pixels), verifying the same app pane moves
from mobile to tablet width with its draft intact. It does not claim that the
diagnostic exit command worked. One intermediate drive was
interrupted by starting the next target too early; it is excluded from passing
evidence. Native targets are subsequently run sequentially to completion.

## Final regression and Android artifacts

Final checks pass:

- `dart format --output=none --set-exit-if-changed lib test integration_test`:
  185 Dart files, no changes.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: **187 tests pass**. A final focused auth/lifetime run
  also passes 19 tests.
- Five native regression targets pass sequentially with exit 0:
  `data_provider`, `member_subscription`, `dropin_report`, `settings_sign_out`,
  and `auth_session`. These recheck rejection/rollback, the 201-delete boundary,
  cross-month totals, A-B-A retained queues and tenant/dialog teardown.
- The final OS-window target and its host helper both exit 0. Captures cover
  390, 599, 600, 601, 1024 logical widths, real keyboard, 2× Android text,
  840×390 rotation, and split panes 507→1019 with the same draft/controller.
  Clean screenshots were visually inspected; no system error dialog obscures them.
- Rules suite: all six groups pass with exit 0. It ran after native fixtures,
  since it intentionally clears the local demo project. Actual provider queries
  read the four owner-scoped sources without filters/orderBy/composite indexes;
  existing rules/configuration match them. No additional index is required.
- Ordinary `flutter build apk --debug --no-pub` passes; its archive installs and
  cold-launches the actual product entry point to Arabic Google login.
- Ordinary `flutter build apk --release` passes. The existing upload key signs
  it; install and two cold launches on Android 36 pass. The login screenshot was
  inspected, and filtered AndroidRuntime/Flutter error logs are empty.

An initial release command with `--no-pub` retained the debug-generated Java
registrant's `integration_test` entry, while release correctly excluded the dev
plugin. Local Flutter tooling inspection identified the generation boundary.
The normal release command regenerated the release registrant and passed without
changing dependencies, Gradle/plugin versions, generated Java by hand, or signing
inputs. README records the reproducible command and mode-switch qualification.
The separate future Built-in Kotlin plugin warning remains nonblocking.

`apksigner verify --verbose --print-certs` verifies both archives. Their certificate
SHA-1s match the registered debug and upload fingerprints from Phase 4. `aapt`
and direct APK inspection confirm package `dev.tahahassan.gymk` and activity
`dev.tahahassan.gymk.MainActivity`, Arabic
label `جيمك`, version `0.0.1+1`, min SDK 24, target SDK 36, INTERNET permission and
the expected Firebase Android app ID. Release is not debuggable and contains the
arm64 AOT library. Bundled logo/loading/fonts/license match the source bytes;
launcher-resource pixels match the generated approved icons (release resource
compression changes PNG encoding, not pixels).

| Local artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `build/verification/gymk-owner-check-debug.apk` | 215583298 | `90B46520413F9C629C84D1D08E1A0CCA66B2184087068FAC48C7BEDA6CB79197` |
| `build/verification/gymk-release.apk` | 60137465 | `186CC9005A1A69D43FE80F3A86D4EEA579D619E9FBECDC14421A9AC01C2403E5` |

These APKs are local ignored artifacts, not published downloads. Detailed local
logs include `phase8-tests-final.log`, `phase8-analysis-final.log`,
`phase8-native-*.log`, `phase8-os-windows.log`, `phase8-window-host.log`,
`phase8-rules.log`, build/install/signature/runtime logs and
`phase8-apk-metadata.json`.

On 29 October the owner explicitly reported
**“All three succeeded”** for real Google-account Android login to Members,
session retained after close/reopen, and sign-out returning to Login. The Phase 4
follow-up records this manual evidence and closes GYM-401/GYM-490. It is separate
from configuration/anonymous fixture results and does not claim manual Google
testing on every build/device. No production rules deployment or store publication
is authorized or performed.

## Read-only review and delivery

Applied the project's flutter-cubit, flutter-ui-cleanup and read-only
flutter-code-review skills, with AGENTS.md precedence. Reviewed immutable state,
explicit nullable clearing, stable intents, local versus remote outcomes, failure
handling, SDK/provider boundaries, captured UID ownership, stream/timer/controller
cleanup, selected-layout-only construction and accessible Arabic controls. The
existing GymkApp remains the single router owner. No new dependency, second store,
custom durable queue, Bloc/events, soft deletion, production deployment or private
credential changes are introduced. Signing files remain ignored/untracked.

`git diff --check` passes. Only Phase 8 code/tests/tooling, README/task/evidence
updates and the owner-reported Phase 4 closure are staged. Reviewed commit,
normal push, remote-SHA comparison and final worktree audit follow this record.
