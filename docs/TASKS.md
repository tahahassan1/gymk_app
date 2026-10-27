# Gymk — Implementation Tasks

Planning baseline: 27 October 2026. Platform: Android. UI: Egyptian Arabic, RTL.

This checklist tracks verified implementation. Phases 1–3 are delivered; Phase 4
implementation is delivered. The latest user request authorizes all remaining
phases (5–8), with the existing verified
commit/push checkpoints. Deployment and store publication remain separate.

## Sources and working rules

- Read [AGENTS.md](../AGENTS.md), [PRD.md](PRD.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [DESIGN_STYLE.md](DESIGN_STYLE.md) before implementation. No nested AGENTS.md or previous TASKS.md was found.
- PRD owns scope, ARCHITECTURE owns technical structure, DESIGN_STYLE owns visuals, and the latest user instructions take precedence. This file tracks work and evidence; it does not approve the recommendations in those documents.
- Use Presentation → Business Logic → Data (Repository → Data Provider), with Cubit exclusively. Cubits consume typed repositories and pure policies. No Bloc subclasses/events, mandatory use cases, ViewModels, second durable database, or responsive packages.
- Keep Cubits in `business_logic/cubit/`, policies in `business_logic/policies/`, and feature views/layouts/widgets under `presentation/`. Add files when needed, not empty scaffolding for every future feature.
- Read the applicable project skills before implementation and run their compatible checks. The inspected `.agents/skills/flutter-cubit/SKILL.md` conflicts with AGENTS.md: its mandatory use cases, `presentation/cubit/` location, and loading/error union template do not apply. Use immutable independent state fields that preserve cached data, nullable-field clearing, and sealed types only for exclusive alternatives. Its `core/di/` example yields to `lib/app/di.dart`.
- `.agents/skills/flutter-ui-cleanup/SKILL.md` provides useful extraction/controller/rebuild guidance, but its alternate folder mappings yield to the paths above. Phase 1 supplies `AppColors` and `AppRoutes`; do not invent the skill's other example contracts (`AppStyles`, `DBKeys`). `.agents/skills/flutter-code-review/SKILL.md` is the final read-only self-review checklist.
- Preserve unrelated changes. The pre-Phase-1 baseline below is historical. At Phase 2 start, local HEAD and remote `main` both matched `4f12849eb4fdc24959434ee8c9280cbde1aeb604`, with a clean worktree. Do not reset, clean, or regenerate the project.
- Keep IDs stable. Check a task only after its acceptance criteria and verification pass; record commands, outcomes, and any blocked runtime checks beneath that task. Partial work stays unchecked. Add dependency changes explicitly.
- Phase numbers organize delivery; listed task dependencies determine readiness, without blanket barriers requiring every earlier CRUD flow. In particular, initial GYM-603 report work may start when its read contracts are ready; GYM-604 verifies later CRUD integration. Remaining phases are now authorized, but verification gates remain in force.

## Planning baseline (before Phase 1)

| Area | Actual state |
| --- | --- |
| App | `lib/main.dart` is the generated Flutter counter demo. `lib/firebase_options.dart` is the only other Dart application file. No feature, theme, localization, adaptive layout, router, DI, Cubit, repository, or policy implementation exists. |
| Tests | `test/widget_test.dart` only tests the demo counter. No business, Cubit, rules, or integration tests exist. |
| Dependencies | `pubspec.yaml` declares Dart `^3.13.1`, `cupertino_icons: ^1.0.8`, `firebase_core: ^5.1.0`, and `flutter_lints: ^6.0.0`. Lockfile resolves Firebase Core to 5.1.0. Auth, Firestore, Google sign-in, flutter_bloc, GetIt, routing, intl, Lottie, and launcher-icon tooling are not declared. Flutter localization tooling is not configured. |
| Toolchain | Installed Flutter 3.47.1 stable / Dart 3.13.1. Java, Node, and Firebase CLI are discoverable. Android SDK is configured through local properties. CLI discovery does not establish emulator/service readiness. |
| Firebase | Android options, `android/app/google-services.json`, Google Services Gradle wiring, and `firebase.json` exist for `gymk-app`. Bootstrap does not initialize Firebase. Local JSON has a web OAuth client (type 3); no Android OAuth client entry was found. Google provider enablement, signing fingerprints, live Firestore setup, and deployed rules were not verified. Preserve these files. |
| Security/config | No `firestore.rules`, `firestore.indexes.json`, or emulator configuration exists. Existing `firebase.json` contains Flutter platform mappings only. |
| Android | Application ID and namespace are `com.example.gymk_app`; label is `gymk_app`. Manifest uses `@mipmap/ic_launcher`, whose inspected image is Flutter's default icon. INTERNET permission is in debug/profile manifests, absent from main. Release currently uses debug signing. |
| Build configuration | AGP 9.1.0, Kotlin plugin 2.4.0, Gradle wrapper 9.3.1, and Java target 17 are present. Compatibility/build success has not been established; do not overwrite these versions speculatively. |
| Brand image | `assets/images/logo.png`: 1254 × 1254, opaque RGB, yellow/black Arabic logo with dumbbell and light background. Visually inspected. It is the available square brand image for the Android icon; there is no separately named icon asset. Preserve it intact. |
| Loading animation | `assets/lotties/loading.json`: 1200 × 650, 60 fps, frames 0–144 (2.4 seconds), two embedded raster assets, no external image paths in its asset list. JSON structure inspected; Flutter playback not tested. |
| Missing asset wiring | No active asset or font declarations in pubspec. No Cairo font files, separate transparent foreground, or adaptive icon background layers were found. |
| Documentation | The three required docs exist, with no competing duplicates found. README remains the Flutter starter text. |
| Runtime access | `adb devices -l` returned no connected devices. `emulator -list-avds` returned `Medium_Phone`; it was not launched. No Android, offline, Firebase, or UI runtime checks were performed. |

Baseline verification performed during planning:

- `flutter analyze --no-pub` — passed, no issues.
- `flutter test --no-pub` — passed, one counter smoke test. This is not evidence of gym behavior.
- Asset dimensions, image appearance, Lottie metadata, dependency declarations, Android wiring, and local Firebase configuration were inspected. No package additions, asset generation, deployment, or application code changes were made.

## Decisions and prerequisites to resolve

Unresolved proposals below remain proposals. Resolved decisions are recorded in
PRD and the corresponding architecture/design contract before dependent tasks
are marked complete. Independent work can proceed.

| ID | Unresolved item and existing guidance | Gate / next action |
| --- | --- | --- |
| D01 | Resolved by user, 27 October 2026: whole EGP, zero decimal places, scale 1. The stored integer unit is one pound, not a piastre. | Applied in GYM-203 and documented in PRD/ARCHITECTURE/DESIGN_STYLE. Actual initial prices remain D08; no currency picker is authorized. |
| D02 | Resolved by user, 27 October 2026: Gregorian `YYYY-MM-DD` strings for coverage/session dates and `paidAt`; payment date is the local recording date. `createdAt` is a client timestamp. | Apply in codecs/rules/reports. No payment-date editor. |
| D03 | Resolved by user, 27 October 2026: prohibit manual future starts, exempt automatic early renewal. If records remain but today is uncovered, including future-only history, classify as expired and renew from today. Preserve remaining dates; no upcoming status. | Applied in GYM-202. Current expiry requires coverage containing today; past expiry and future history ranges remain separate facts. Later forms must distinguish a newly selected manual start from an unchanged automatic future start during amount correction. |
| D04 | Resolved by user, 27 October 2026: compact persistent pending/error feedback in the shared shell. | Track observed session mutations and rejected actions; never infer global sync/connectivity. |
| D05 | Resolved by user, 27 October 2026: allow zero default prices; subscription/drop-in payment records must be positive. Negative/invalid amounts are rejected. | Applied in GYM-203 with explicit amount purpose. GYM-305 rules and later forms must use the same distinction. |
| D06 | Resolved by user, 27 October 2026: three days fixed for MVP; no settings control. | Keep the centralized policy threshold. |
| D07 | Resolved boundary, 27 October 2026: guarded complete-history single-batch member deletion; block incomplete/oversized history. Larger cascades and cross-device coordination are outside MVP. | GYM-505 still verifies actual SDK/backend limits and documents the implemented guard; never silently split batches. |
| D08 | Resolved by user, 27 October 2026: both initial prices are zero; any temporary name is acceptable (`جيمك` selected). | Create only on server-confirmed absence; preserve existing settings. Owners edit these values through settings. |
| D09 | Asset prerequisite, satisfied in Phase 1: Cairo 400/600/700 and SIL license are bundled from Google Fonts. DESIGN_STYLE's older future-icon wording yields to AGENTS.md and the existing square logo. | GYM-102/105 reuse `assets/images/logo.png` and `assets/lotties/loading.json`; no new artwork or transparency conversion. This resolves an asset prerequisite, not a product choice. |
| D10 | Production ID `dev.tahahassan.gymk` is configured with its new Firebase Android registration and registered debug/upload SHA-1s. Private local signing inputs were created and Gradle verified both fingerprints. | Configuration/signing coordination is complete. The user will perform real Google sign-in; no successful OAuth result is recorded yet. Final release-artifact verification remains Phase 8. See verification/PHASE_4.md. |

Documentation conflicts to reconcile: PRD's blanket offline promise must retain the confirmed limits for first download, unverified cache, and safe cascades. DESIGN_STYLE's phone-focused guidance and bottom tabs extend to two layouts with the same four destinations; AGENTS.md/ARCHITECTURE require mobile/tablet compositions now. No new product decision is needed for those confirmed constraints.

## Verification contract for every task

Run formatting on changed Dart files, static analysis, and focused tests appropriate to the change. Use repository fakes for Cubit behavior; Firebase emulators and Android integration for SDK behavior. Do not mark runtime requirements passed based on source review. Add only necessary test tooling when the corresponding task starts.

Every UI task below inherits the applicable parts of **UI-V**. Scale verification to the changed behavior: run the full breakpoint/continuity harness for adaptive-shell changes, representative phone/tablet and relevant state tests for a new screen, and focused affected-component checks for a small visual edit. Pure model/policy changes need focused unit tests, not a UI/device matrix. The complete width/state matrix is a Phase 8 regression gate, not a repeated requirement for every edit.

- **Composition:** mobile below 600 logical pixels and tablet at/above 600, through shared `AppAdaptiveLayout`/`AppBreakpoints`. Select once from bounded full screen/shell width and keep navigation and content in the same mode. Use only Flutter framework layout APIs; build only the selected branch.
- **Responsive/RTL:** cover changed layouts at representative phone/tablet widths and text scales 1.0 and 2.0; use 599/600/601 for selector/shell changes. Exercise keyboard insets for changed forms, short landscape where relevant, long Arabic names, mixed numeric strings, safe areas and at least 48px touch targets. The comprehensive 320/360/390/430/599/600/601/768/1024/1280 matrix belongs to GYM-802. No overflow or clipped controls; use bounded forms and scrolling.
- **Continuity:** resize across 599↔600 and rotate while the feature is in use. Preserve relevant destination/history/scroll, selected member/day/month, query/filter, entered form values, and pending operation IDs. No new Cubit, listener, submission, or repeated one-time effect because a layout rebuilds.
- **Feedback:** verify applicable initial-loading, usable cached data, confirmed-empty, filtered-empty, incomplete-cache, read-error, validation, submitting, locally applied/pending, acknowledged, and rejected/rollback states. Inapplicable states may be recorded as such. Keep cached data readable; use the supplied logo Lottie for suitable screen-level loading, not each button. Never claim authoritative emptiness/zero from an unverified cache or cloud success from local application.
- **Evidence:** record focused widget coverage and relevant Android visual/interaction checks. Keyboard/rotation checks apply to forms/layout changes; persistence checks belong to actual SDK/data changes. Do not demand Firebase verification for a theme-only change or rerun the entire app matrix without a relevant change or failure. Missing required device/service access remains an explicit verification blocker.

### Phase commit-and-push protocol

Each phase has an explicit delivery task (GYM-190 through GYM-890). After its implementation tasks pass their proportional checks, update this checklist with actual evidence, run `git diff --check`, review and stage only the phase's files plus necessary existing project baseline, inspect the staged diff, and create a descriptive phase commit. Push normally to the configured branch/upstream without force; verify the remote branch SHA with `git ls-remote` matches local HEAD and review the remaining worktree. Record the implementation commit and push outcome. A follow-up documentation receipt commit is allowed after remote verification; push and verify that receipt too. If verification, commit, credentials or push fails, leave the relevant task/checkpoint unchecked and report the exact blocker. A local commit is not a completed push checkpoint. No deployment or store publishing is implied.

## Phase 1 — Arabic, adaptive application foundation

Delivered implementation phase. Currency, payment encoding, and future-only coverage decisions did not block this phase; missing font acquisition gated GYM-102 only.

### GYM-101 — Establish the app composition and required foundation dependencies

- [x] Verified complete
- **Depends on:** none.
- **Scope/components:** `pubspec.yaml`, lockfile, `lib/main.dart`, `lib/app/app.dart`, `lib/app/di.dart`, baseline tests.
- **Acceptance:** replace the demo entry point with app composition; add compatible flutter_bloc, GetIt, go_router, localization/intl, and Lottie dependencies as needed. Preserve existing Firebase/Android configuration. No Bloc subclasses, event files, responsive packages, generated use-case layer, or duplicate persistence. Dependency ownership and route/form factory convention are explicit; do not create unused feature scaffolding.
- **Verification:** resolve against installed Flutter/Dart; format/analyze and run an updated app-start smoke test. Verify counter-specific expectations are replaced with actual startup assertions, not simply removed.
- **Evidence:** dependency resolution, Arabic startup/recovery tests, formatting and analysis passed; see [Phase 1 verification](verification/PHASE_1.md). Firebase/Android registration preserved; no feature Cubits or data flows introduced.

### GYM-102 — Bundle branding/fonts and create the Arabic visual foundation

- [x] Verified complete
- **Depends on:** GYM-101; asset prerequisite D09.
- **Scope/components:** pubspec assets/fonts, licensed Cairo files, `lib/core/theme/`, `lib/core/ui/`, Arabic localization resources.
- **Acceptance:** locally bundled Cairo 400/600/700 and license; Egyptian Arabic RTL MaterialApp and localized date controls; semantic light-theme tokens from DESIGN_STYLE, directional spacing and centralized formatting boundaries. Reusable button/input/feedback/sheet/deletion primitives remain small and accessible. Reuse the actual logo and loading JSON without cropping/redrawing; reduced-motion handling and readable initialization-error copy. UI-V applies to the foundation preview/startup surface; no currency assumption.
- **Verification:** focused widget checks for Arabic RTL, asset loading and scaled text; render the Lottie on Android and inspect logo proportions, contrast, font fallback, and motion behavior. Normal rendering must work without font/image downloads.
- **Evidence:** bundled Cairo/static assets/license, real Android Lottie playback and focused-field/date-control contrast reviewed; reduced-motion, RTL, 2× text, dialogs/date picker and keyboard-inset tests passed. No currency/default-price decision was made.

### GYM-103 — Implement one adaptive layout policy

- [x] Verified complete
- **Depends on:** GYM-101.
- **Scope/components:** `lib/core/ui/adaptive/`, selector/widget tests.
- **Acceptance:** one named 600px breakpoint; bounded `LayoutBuilder`, lazy mobile/tablet callbacks, same application mode passed to shell content. Local pane constraints never reclassify device mode. State-owning hosts stay above replaceable branches. UI-V applies to the selector harness.
- **Verification:** meaningful tests at 599/600/601, selected-builder-only execution, unbounded-width failure, and form/state identity across resize. Listener/submission counts apply when those flows are introduced; Phase 1 creates none.
- **Evidence:** boundary/lazy-builder/bounded-width tests passed. At 600 the narrower content pane retains tablet mode. Real emulator resize retained the open form and typed draft.

### GYM-104 — Build the shared four-destination navigation shell

- [x] Verified complete
- **Depends on:** GYM-102, GYM-103.
- **Scope/components:** `lib/app/router.dart`, app shell/navigation, shared form host.
- **Acceptance:** same members/drop-ins/statistics/settings routes and branch history in mobile bottom navigation and tablet composition, with details/form route support. Shared form host, selections and controllers survive layout replacement. Unimplemented destinations are development scaffolding only and do not count as delivered features. UI-V applies, especially navigation and open-form continuity; final auth redirects belong to GYM-403.
- **Verification:** widget navigation/back-history tests and resize while a shared form is open. Check RTL tab/rail labels and constrained tablet content on Android.
- **Evidence:** four routes, member-detail/subscription route scaffolding and modal form host implemented. Tests preserve nested branch history across tab changes and 599↔600 resizing; emulator phone/tablet shell and open-form continuity inspected. Destinations explicitly remain unfinished, not delivered gym features.

### GYM-105 — Configure reproducible Android branding

- [x] Verified complete
- **Depends on:** GYM-101.
- **Scope/components:** `pubspec.yaml`, root launcher-icon configuration, Android mipmaps/manifest.
- **Acceptance:** compatible `flutter_launcher_icons` dev_dependency; Android-only generation from `assets/images/logo.png`; label `جيمك`; correct `@mipmap/ic_launcher` references. Keep the opaque square intact and omit adaptive layers because suitable foreground/background assets are absent. Preserve Firebase/package registration.
- **Verification:** `flutter pub get`, `dart run flutter_launcher_icons`, inspect generated density resources and merged manifest, build/install an Android debug APK and inspect launcher legibility/cropping. Record actual device evidence; generation alone is insufficient.
- **Evidence:** launcher generation, final debug build/install and AAPT manifest/resource checks passed. Five mipmap densities use the supplied uncropped square; Arabic app label and native launch artwork inspected. This Windows machine needs the documented per-command Kotlin workaround; project Gradle versions/configuration are unchanged.

### GYM-190 — Verify, commit and push Phase 1

- [x] Verified complete
- **Depends on:** GYM-101, GYM-102, GYM-103, GYM-104, GYM-105.
- **Scope/components:** Phase 1 files, verification evidence and this checklist.
- **Acceptance:** follow the phase commit-and-push protocol; keep unresolved product decisions open; no Phase 2+ implementation.
- **Verification:** reviewed staged diff, successful phase commit/push, matching local/remote branch SHA, and recorded remaining worktree state.
- **Evidence:** implementation commit `89c154d7c6469beeb015e2f3cbb208451d207b71` pushed to `origin/main` in the private [gymk_app repository](https://github.com/tahahassan1/gymk_app). `git ls-remote --heads origin main` matched local HEAD; the worktree was clean. This documentation receipt is committed/pushed and checked by the same protocol. No Phase 2+ implementation was started.

## Phase 2 — Pure calendar, coverage, and money rules

Authorized scope starts at GYM-201. D01, D03 and D05 were resolved explicitly by
the user before dependent behavior was implemented. Persisted date encoding D02
belongs to Phase 3 and remains unresolved; no codec or Firebase work is included.

### GYM-201 — Add injectable time and calendar-month arithmetic

- [x] Verified complete
- **Depends on:** GYM-101.
- **Scope/components:** `lib/core/time/`, pure policy tests.
- **Acceptance:** validated date-only value, injectable local-date Clock, ordering/day differences independent of DST elapsed hours, exclusive expiry, and clamped calendar-month addition. No Flutter/Firebase imports in pure rules; persisted encoding remains gated by D02.
- **Verification:** invalid dates, leap/non-leap 31 January, repeated clamping through March, December/year rollover, exclusive end, and calendar-day differences around DST transitions.
- **Evidence:** `DateOnly`, injectable `Clock`/local `SystemClock`, six date tests and half-open coverage tests pass. Explicit offset samples demonstrate 23/25-hour elapsed days still count as one calendar day. Formatting/analysis and all 55 tests pass; see [Phase 2 verification](verification/PHASE_2.md). No persisted codec added.

### GYM-202 — Implement coverage/status and renewal previews

- [x] Verified complete
- **Depends on:** GYM-201; D03 for unresolved cases.
- **Scope/components:** subscriptions/members `business_logic/policies/`, focused pure tests.
- **Acceptance:** merge adjacent/overlapping coverage, derive current status and overall continuous expiry, central three-day boundary, no-subscription handling, default expired/first start to today. Early renewal extends existing coverage; edits/deletes preserve other records' dates. Complete future-only/gapped label and renewal semantics only after D03 is resolved. No stored status/authoritative member expiry.
- **Verification:** 26 October→26 November, renewal on 10 November→26 December; repeated early renewals; 4/3/1/0 remaining days; overlap, middle/latest deletion and gap/future-only cases under the resolved decision.
- **Evidence:** three coverage tests and 17 subscription-policy cases pass: October/November/December extension, repeated/leap clamping, 4/3/1/0-day statuses, history edits/deletes, gaps/future-only expiry, manual-future rejection with automatic-renewal exemption, and injected-date rollover. Policies preserve input dates and use one clock read per assessment/preview. Later Cubit scheduling/forms are not implemented.

### GYM-203 — Implement precise amount parsing and validation

- [x] Verified complete
- **Depends on:** GYM-101; D01, D05.
- **Scope/components:** shared money/input value helpers, presentation formatting boundary, pure tests.
- **Acceptance:** store/sum integer minor units; parse Western and Arabic-Indic digits and supported decimal separators without binary floating-point totals; reject invalid/nonfinite/negative values and enforce the resolved zero policy. Currency/scale is centralized; no widget-level price policy.
- **Verification:** exact decimal conversion, fractional precision, localized digits, malformed/empty input, zero policy, and integer totals that expose floating-point rounding errors.
- **Evidence:** eight money/formatting tests pass for whole EGP (scale 1), localized digits, exact zero-only decimal suffixes, rejected nonzero fractions, invalid/nonfinite/negative input, zero defaults versus positive records, signed-64-bit overflow and exact large-integer totals/output. Presentation formats Arabic currency with Western digits and bidi isolation. No defaults, payment records or report calculator created.

### GYM-290 — Verify, commit and push Phase 2

- [x] Verified complete
- **Depends on:** GYM-201, GYM-202, GYM-203.
- **Scope/components:** Phase 2 files and verification record.
- **Acceptance:** follow the phase commit-and-push protocol after focused policy/amount tests; no unrelated UI matrix.
- **Verification:** successful checks, reviewed commit, successful push and matching local/remote branch SHA.

- **Evidence:** reviewed implementation commit `eaddbcea6ecfe159df82187b6a8e8db6e2bf956c` pushed normally to `origin/main`. `git ls-remote origin refs/heads/main` matched local HEAD; `git status --short --branch` showed a clean worktree with no ahead/behind count. Formatting, analysis, 34 focused tests and all 55 suite tests passed. This documentation receipt records that verified checkpoint and follows the same push/SHA verification protocol.

## Phase 3 — Typed data, offline contracts, and security

### GYM-301 — Define models/codecs and the Firebase provider boundary

- [x] Verified complete
- **Depends on:** GYM-101, GYM-201; D02 for persisted date codecs only.
- **Scope/components:** feature `data/models/`, `data/providers/`, `data/repositories/`, `lib/core/errors/`, bootstrap and preserved Firebase files.
- **Acceptance:** typed members/settings/subscriptions/drop-ins and repository interfaces; monetary fields are integer minor units, independent of monetary input parsing, currency formatting and initial default values. Document IDs are authoritative, references immutable. Providers own SDK serialization and captured-UID paths under the existing flat schema. Configure persistence/unlimited cache before first Firestore use; initialize Firebase using existing Android options. Typed read envelopes expose cache/completeness/pending metadata without leaking snapshots into widgets. Initialization has recoverable failure UI (UI-V).
- **Verification:** codec round trips, malformed records, immutable references, UID path tests, bootstrap success/failure with fakes; Android Firebase initialization and persistence configuration. Confirm compatible FlutterFire versions at implementation time.
- **Evidence:** immutable models/date codecs, typed `GymRepository`/captured-UID provider and recoverable initialization delivered. Four startup widget cases cover phone/tablet at 1×/2× text. Android integration invokes the actual bootstrap and verifies persistence/unlimited cache, using isolated emulators for all test data. See [Phase 3 verification](verification/PHASE_3.md).

### GYM-302 — Share tenant read streams and completeness projections

- [x] Verified complete
- **Depends on:** GYM-301.
- **Scope/components:** repository implementations, `lib/app/session/` read projection.
- **Acceptance:** one session source per required settings/member/subscription/drop-in dataset; index subscriptions by member without per-row queries. Preserve data during refresh/errors and distinguish cache-only/incomplete from server-confirmed complete. Full-session drop-in reads retain historical report coverage. Account disposal cancels listeners; no second durable cache or fake connectivity inference.
- **Verification:** repository fakes/provider tests for shared listener counts, partial/empty/cache/server transitions, stream failures, cancellation and late results. Integration must demonstrate cached cold-start does not assert full completeness.
- **Evidence:** one shared listener for each of settings/members/subscriptions/drop-ins, replay/retry and cancellation tests pass; members use an indexed history projection. Errors retain data but revoke completeness. Native SDK verifies cached-empty and reopened cached history stay unverified, immediate teardown and account A→B isolation. No per-row Firebase queries or second store.

### GYM-303 — Introduce immutable Cubit state/lifetime conventions through real consumers

- [x] Verified complete
- **Depends on:** GYM-302.
- **Scope/components:** first feature/session Cubits and factories in `lib/app/di.dart`; repository fakes.
- **Acceptance:** independent read/data/filter/submission/failure fields; explicit nullable clearing, handled stream errors and owned subscription/timer cleanup. Factories for route/form Cubits, constructor injection, no Cubit-to-Cubit subscriptions. Establish these through needed consumers, not generic state/CRUD frameworks.
- **Verification:** fake-stream tests show cached data survives errors/mutations, failure can clear, close cancels resources and ignores late results, and reopening a route obtains the intended lifetime.
- **Evidence:** first real `MembersCubit` and immutable independent state, explicit nullable failure clearing, handled stream errors and owned subscription cleanup. Repository-fake tests cover search/filter/date reassessment and 500 members with one date read per calculation; DI factory test proves a reopened route gets a fresh Cubit for the supplied tenant. Members UI and rollover scheduling remain Phase 5 work.

### GYM-304 — Track local writes through acknowledgement or rejection

- [x] Verified complete
- **Depends on:** GYM-302.
- **Scope/components:** repository mutation handles, current-session operation tracking and per-member mutation coordination.
- **Acceptance:** stable intent/document IDs, immediate double-submit guard, local stream application separate from cloud acknowledgement, handled write Futures after form closure, affected-action errors and rollback. Retry uncertain acceptance with the same ID. Serialize conflicting same-member operations. Track pending deletions even after rows disappear; Firestore remains the only durable queue. Do not promise a global pending count after restart.
- **Verification:** fake-driven submission/duplicate/serialization tests; Android integration validates installed SDK behavior while offline, form release after local application, eventual rejection after form close, and retry without duplicate payments. These SDK cases must pass before core forms are marked complete.
- **Evidence:** immutable operation notices and stable-ID mutation handles distinguish submitted/local/acknowledged/rejected outcomes; per-member gate releases after local application. Six focused mutation tests plus native offline save, rejection/rollback after local completion, duplicate-intent single record, and pending deletion after row disappearance pass. Eventual errors stay owned by the tenant repository; no persistent queue added.

### GYM-305 — Add schema-validating rules and emulator coverage

- [x] Verified complete
- **Depends on:** GYM-301; D05.
- **Scope/components:** `firestore.rules`, `firestore.indexes.json` only as actual queries require, additive `firebase.json` emulator/rules configuration, rules tests.
- **Acceptance:** owner-only reads/create/update/permanent-delete, unauthenticated/cross-UID denial, valid money/types/names/date encodings and immutable member references. Model and rules validation agree. Preserve existing Flutter mappings; isolate emulator fixtures from live data. Rules do not claim robust multi-device cascade integrity.
- **Verification:** emulator tests for own valid CRUD, every collection and settings path, cross-tenant denial, malformed fields and forbidden reference changes. Queued rejection/rollback integration with GYM-304 is verified in GYM-801, without blocking initial rules. Do not deploy as part of this local task.
- **Evidence:** six emulator groups pass for valid CRUD, owner/unauthenticated/cross-UID boundaries, whole positive records versus zero defaults, calendar dates/clamped one-month coverage, immutable references and atomic deletion. Additive emulator/rules configuration preserves Flutter mappings. Test-tool dependency audit reports zero vulnerabilities. Rules are not deployed.

### GYM-390 — Verify, commit and push Phase 3

- [x] Verified complete
- **Depends on:** GYM-301, GYM-302, GYM-303, GYM-304, GYM-305.
- **Scope/components:** Phase 3 files and verification record.
- **Acceptance:** follow the phase commit-and-push protocol after data/state/rules and required SDK checks.
- **Verification:** successful checks, reviewed commit, successful push and matching local/remote branch SHA.
- **Evidence:** implementation `cf543f859e9deebc92e39581f3109412f8949d31` pushed normally to `origin/main`; remote SHA matched local HEAD and worktree was clean. This documentation receipt follows the same push/SHA protocol.

## Phase 4 — Google authentication and tenant lifecycle

### GYM-401 — Implement Google sign-in and restore sessions

- [ ] Verified complete
- **Evidence/status:** implemented; auth fake tests and adaptive RTL login checks pass, and native Firebase session restoration passes. Package/configuration and both registered SHA-1s agree. The user will test real Google sign-in; this runtime gate remains unverified. See [Phase 4 evidence](verification/PHASE_4.md).
- **Depends on:** GYM-102, GYM-301; setup prerequisite D10.
- **Scope/components:** auth data/provider/repository, `business_logic/cubit/`, sign-in view/mobile/tablet layouts, Android permissions/configuration.
- **Acceptance:** compatible Google sign-in/Firebase Auth APIs, a single Google action, cancellation/retry/first-use internet feedback, restored authenticated session offline. Mobile uses a readable stacked surface; tablet uses bounded content with the same action/state. Preserve supplied branding. Add main-manifest network permission for release functionality. UI-V applies; sign-in progress/error survives resize without duplicate requests.
- **Verification:** Cubit fake-auth tests for cancel/error/double-submit/restore, login UI tests; actual Android Google sign-in verifies provider, signing fingerprints and package/OAuth consistency. Existing config files alone do not satisfy this task.

### GYM-402 — Bootstrap first-account settings safely

- [x] Verified complete
- **Evidence:** fake tests cover existing/absent settings, repeat identities, permission recovery and unverified cache absence. The isolated Android native scenario verifies bootstrap, retained custom prices on repeated login and offline restoration. See [Phase 4 evidence](verification/PHASE_4.md). GYM-401's real Google consent check remains separately open.
- **Depends on:** GYM-302, GYM-304, GYM-305, GYM-401; D01, D05, D08.
- **Scope/components:** settings repository/provider, authenticated bootstrap state and loading/recovery UI.
- **Acceptance:** create the settings map only after server-confirmed absence, with resolved initial values. Never replace existing prices/name on login or mistake an empty offline cache for a missing user. Initial online setup is separate from ordinary restored offline use. UI-V applies to setup/loading/retry/incomplete states.
- **Verification:** tests for existing account, absent account, repeated bootstrap, permission failure and cache-only absence; Android/emulator integration proves repeated login preserves settings and offline restoration does not overwrite them.

### GYM-403 — Wire auth redirects, scoped sessions, and mutation feedback

- [x] Verified complete
- **Evidence:** widget regressions verify nested navigation/form/dialog teardown and persistent feedback across resize; Android native A→sign-out→B with cached A rows and an offline pending change passes, including old Cubit disposal and no previous account feedback/dialog. Sign-out warning UX remains GYM-702. See [Phase 4 evidence](verification/PHASE_4.md).
- **Depends on:** GYM-104, GYM-303, GYM-304, GYM-402; D04 for indicator presentation.
- **Scope/components:** router redirects, DI/session scope, presentation listeners and pending/rejection feedback.
- **Acceptance:** captured UID per tenant scope; cancel/dispose old Cubits, projections and listeners on account change; reset tenant navigation/forms. No prior gym data flashes in the next account. Present accurate local/pending/rejected feedback, with optional indicator only as resolved. Effects fire once; no writes from route/layout builders. UI-V applies to restored/loading/error sessions and feedback across both shell compositions.
- **Verification:** fake-auth account-switch and effect-deduplication tests; device/emulator account A→sign-out→B with cached A data, in-flight operations and route resize. Sign-out UX is completed in GYM-702.

### GYM-490 — Verify, commit and push Phase 4

- [ ] Verified complete
- **Status:** implementation `d59e592` was committed, pushed normally and verified against the remote SHA with a clean worktree. The fully verified checkpoint remains open until the user's real Google sign-in result closes GYM-401. See [Phase 4 evidence](verification/PHASE_4.md); no configuration-only OAuth claim is made.
- **Depends on:** GYM-401, GYM-402, GYM-403.
- **Scope/components:** Phase 4 files and verification record.
- **Acceptance:** follow the phase commit-and-push protocol after auth/session and relevant UI checks.
- **Verification:** successful checks, reviewed commit, successful push and matching local/remote branch SHA.

## Phase 5 — Members and monthly subscriptions

### GYM-501 — Deliver the members list, search, and filters

- [x] Verified complete
- **Evidence:** 128-test suite, clean format/analysis and two native Android scenarios; see [Phase 5 verification](verification/PHASE_5.md).
- **Depends on:** GYM-202, GYM-302, GYM-303, GYM-403; D03 for exceptional coverage display.
- **Scope/components:** members list Cubit, view, mobile/tablet layouts and focused row/filter widgets.
- **Acceptance:** lazy list with name/status/expiry; local name search; All/Active/Expiring soon/Expired filters; add-member and new-subscription entry points. Mobile stacks controls/list; tablet uses available width for bounded controls and wider rows without a new device classifier. Recompute date-sensitive status on resume/local midnight, using injected Clock and cleaned-up timers. UI-V applies, including query/filter/scroll continuity, no-subscription display, cache-incomplete versus confirmed-empty, and preserving readable rows during mutation.
- **Verification:** Cubit tests for filters/search/date rollover/resume/errors; widget resize/state tests and Arabic long-name cases. Seed hundreds of members to inspect list/search responsiveness and listener counts; no per-row Firebase reads.

### GYM-502 — Deliver add/edit member and inline member selection

- [x] Verified complete
- **Evidence:** 128-test suite, clean format/analysis and two native Android scenarios; see [Phase 5 verification](verification/PHASE_5.md).
- **Depends on:** GYM-104, GYM-304, GYM-501.
- **Scope/components:** member form/picker Cubits and shared form body, mobile sheets/tablet bounded forms.
- **Acceptance:** trimmed required name, optional string phone with bidi isolation; stable-ID create/edit with immediate submission guard. New subscription opens member search and can add/select a member in the same flow. Preserve parent flow input and selection, return the newly created member, and keep controllers/form state above layout changes. UI-V applies, including validation, filtered-empty, incomplete lookup, pending/rejected writes and keyboard scrolling.
- **Verification:** repository-fake tests for add/edit/double tap/retry; widget flow picker→add→selected member with parent values intact; Android offline local-save, rejection, keyboard and breakpoint checks.

### GYM-503 — Deliver new subscriptions and early renewal

- [x] Verified complete
- **Evidence:** 128-test suite, clean format/analysis and two native Android scenarios; see [Phase 5 verification](verification/PHASE_5.md).
- **Depends on:** GYM-202, GYM-203, GYM-304, GYM-502; D01, D02, D03, D05.
- **Scope/components:** subscription form Cubit/policy integration, shared form widget and mobile/tablet form hosts.
- **Acceptance:** amount prefilled from current settings and editable; editable start, computed one-month end, current/new expiry preview. First/expired starts today; early renewal starts at current continuous expiry. Re-evaluate before submission and require fresh confirmation if preview becomes stale. Stable payment intent, payment recording date independent of coverage, no payment-date editor. UI-V applies; an open form and pending write survive resize, and offline completion follows local application without claiming cloud success.
- **Verification:** tested October/November/December example, leap/clamped dates, localized amount input, duplicate taps, concurrent same-member change, stale preview and retry. Device test saves offline, closes the form, reconnects and verifies one record and correct payment month.

### GYM-504 — Deliver details/history and subscription correction

- [x] Verified complete
- **Evidence:** 128-test suite, clean format/analysis and two native Android scenarios; see [Phase 5 verification](verification/PHASE_5.md).
- **Depends on:** GYM-501, GYM-503; D03.
- **Scope/components:** member details Cubit/view/layouts, history widgets, subscription edit/delete form/dialog.
- **Acceptance:** member info, status/current expiry, prominent renewal and complete history with amount/payment/coverage dates. Mobile stacks detail/history; tablet composes summary/history without changing route state. Edit amount/start and recompute only that record's end; preserve its ID/member/payment date. Permanent delete requires confirmation and updates coverage and report inputs without altering other dates. UI-V applies to missing/deleted member, incomplete history, pending/rejection and selection/form continuity.
- **Verification:** tests for editing amount/start, deleting newest/middle/only period, future-only resolved behavior, immutable references, date rollover, missing member and stale edit. Android offline edit/delete and resize with an edit form open; verify projections update together.

### GYM-505 — Implement guarded permanent member cascade

- [x] Verified complete
- **Evidence:** 128-test suite, clean format/analysis and two native Android scenarios; see [Phase 5 verification](verification/PHASE_5.md).
- **Depends on:** GYM-304, GYM-305, GYM-504; D07 supported boundary.
- **Scope/components:** narrowly scoped `MemberDeletionCoordinator`, repository/provider atomic batch capability, details deletion UI.
- **Acceptance:** explicit confirmation names the member and warns that all subscriptions and historical statistics change. Enumerate complete subscription history, coordinate same-member mutations, and delete member plus every related subscription in one supported atomic batch. Block incomplete/oversized deletion with actionable Arabic feedback; independent drop-ins stay unchanged. Handle local removal and later rollback, with no soft delete/undo or silent multi-batch fallback. UI-V applies to dialogs, blocked/pending/rejected states, and resize while confirmation/submission is active.
- **Verification:** fake tests for completeness/limits/conflicting renewal/double submit; emulator/device verifies atomic success or rejection, no orphan subscriptions within supported single-device operation, unaffected drop-ins and changed totals. Verify installed SDK/backend request limits before setting guards; document unsupported multi-device races.

### GYM-590 — Verify, commit and push Phase 5

- [ ] Verified complete
- **Depends on:** GYM-501, GYM-502, GYM-503, GYM-504, GYM-505.
- **Scope/components:** Phase 5 files and verification record.
- **Acceptance:** follow the phase commit-and-push protocol after member/subscription/cascade checks.
- **Verification:** successful checks, reviewed commit, successful push and matching local/remote branch SHA.

## Phase 6 — Drop-ins and monthly cash collected

### GYM-601 — Deliver drop-in quick entry and day browsing

- [ ] Verified complete
- **Depends on:** GYM-203, GYM-304, GYM-403; D01, D05.
- **Scope/components:** drop-in form/day-list Cubits, view/mobile/tablet layouts and widgets.
- **Acceptance:** optional name, settings-prefilled amount, one quick record action, today's list and previous-day browsing. Blank names display `بدون اسم`; records are independent of members. Mobile stacks form/list; tablet can compose bounded entry beside results. UI-V applies; selected day/scroll/draft persist and confirmed empty is distinguished from incomplete cached results. Recording from a historical-day view must follow an explicit date context; do not silently backdate a new quick entry.
- **Verification:** fake-repository form/day tests, midnight/resume behavior, date context, double tap/retry and local pending/rejection. Android offline add, browse loaded prior days, resize while typing and keyboard usability.

### GYM-602 — Deliver drop-in editing and permanent deletion

- [ ] Verified complete
- **Depends on:** GYM-601.
- **Scope/components:** drop-in edit form/dialog, Cubit mutations and repository integration.
- **Acceptance:** edit name/amount/session date; retain ID; delete only after confirmation. Date edits move the entry between day/month projections; pending deletion/rejection remains observable after the row disappears. UI-V applies to mobile/tablet shared forms, destructive dialogs, selected-day/draft continuity and rollback.
- **Verification:** fake tests for move between days/months, amount correction, confirmation/double-submit/rejection; Android offline edit/delete and reconnect, showing the corresponding projection/report inputs change.

### GYM-603 — Deliver local monthly reports

- [ ] Verified complete
- **Depends on:** GYM-104, GYM-201, GYM-302, GYM-303; D01 for currency display, D02 for persisted payment-date integration.
- **Scope/components:** statistics pure calculator, month Cubit, view/mobile/tablet layouts.
- **Acceptance:** month picker; subscription income/count, drop-in income/count, and `إجمالي المتحصلات`. Counts are records, not unique members; integer sums use payment/session dates and start-inclusive/end-exclusive month bounds. Recompute from the shared projection when records change; live CRUD/cascade integration is the separate GYM-604 gate. Mobile stacks summaries; tablet arranges the same summaries in available space. UI-V applies, especially selected-month continuity, pending totals, incomplete data labels and authoritative zero only for verified empty input. No charts/profit/export or server counters.
- **Verification:** pure tests for December/year boundaries, multiple renewals per member, November payment covering December, exact integer amounts and changed/removed records supplied by fakes. Cubit/widget tests for month selection, stream errors, cache completeness and resize; compare known seeded totals. Initial calculator/read-only report work can start once these dependencies are ready; it does not wait for CRUD screens or monetary input parsing.

### GYM-604 — Verify live report updates from correction/deletion flows

- [ ] Verified complete
- **Depends on:** GYM-603, GYM-503, GYM-504, GYM-505, GYM-602.
- **Scope/components:** report integration tests and existing shared projections.
- **Acceptance:** subscription/drop-in create, edit, delete and member cascade update visible totals/counts for affected months, including pending/rejected writes. No second report data source or UI expansion. UI checks target changed totals and selected-month continuity only.
- **Verification:** emulator/device integration with known records verifies cross-month edits, member cascade, rejected write rollback and online/offline totals. This later integration gate does not delay initial GYM-603 work.

### GYM-690 — Verify, commit and push Phase 6

- [ ] Verified complete
- **Depends on:** GYM-601, GYM-602, GYM-603, GYM-604.
- **Scope/components:** Phase 6 files and verification record.
- **Acceptance:** follow the phase commit-and-push protocol after drop-in/report and later CRUD integration checks.
- **Verification:** successful checks, reviewed commit, successful push and matching local/remote branch SHA.

## Phase 7 — Settings and safe sign-out

### GYM-701 — Deliver gym/default-price editing

- [ ] Verified complete
- **Depends on:** GYM-203, GYM-304, GYM-402, GYM-403; D01, D05, D08.
- **Scope/components:** settings Cubit/view/layouts, reusable settings form.
- **Acceptance:** gym name, default subscription price and default drop-in price, with clear save behavior. Changes affect future prefills, never historical payments or an already edited draft. Mobile scrolling form and bounded tablet composition share one state. UI-V applies to initial/incomplete/error data, dirty draft, local save/pending/rejection and keyboard/resize preservation. No currency picker, threshold control, cache tools, or theme settings are added.
- **Verification:** fake-repository tests for validation/save/retry and remote stream updates versus dirty drafts; widget continuity tests; Android offline defaults update and subsequent subscription/drop-in prefill checks.

### GYM-702 — Deliver sign-out with pending-change handling

- [ ] Verified complete
- **Depends on:** GYM-304, GYM-403, GYM-701.
- **Scope/components:** auth/session lifecycle and settings sign-out presentation.
- **Acceptance:** known pending changes trigger clear warning and offer to stay signed in. Explicit continuation tears down tenant memory/routes/listeners without erasing SDK persistence or claiming upload success. Any wait-for-sync option is cancellable and never blocks indefinitely offline. UI-V applies to mobile/tablet dialogs, pending/error states and resize without repeated sign-out.
- **Verification:** fake tests for stay/continue/cancel-wait and disposal; Android integration with offline pending create/delete, sign-out and another account login. Verify prior gym data is never rendered and document observed SDK queue behavior without promising a global queue count.

### GYM-790 — Verify, commit and push Phase 7

- [ ] Verified complete
- **Depends on:** GYM-701, GYM-702.
- **Scope/components:** Phase 7 files and verification record.
- **Acceptance:** follow the phase commit-and-push protocol after settings/sign-out and relevant UI checks.
- **Verification:** successful checks, reviewed commit, successful push and matching local/remote branch SHA.

## Phase 8 — End-to-end verification and Android delivery readiness

### GYM-801 — Verify persistence, rejection recovery, and tenant isolation end to end

- [ ] Verified complete
- **Depends on:** GYM-305, GYM-505, GYM-604, GYM-702.
- **Scope/components:** `integration_test/`, emulator fixtures/rules tests, Android verification record.
- **Acceptance:** online preload→airplane-mode read/add/edit/renew/delete→process restart→reconnect yields correct local and server records/totals. Fresh install and unverified empty cache remain honest; rejected queued writes roll back with affected-action feedback after forms close. A/B account isolation and listener cleanup hold. No duplicate stable intents or custom durable queue.
- **Verification:** execute Firebase Emulator Suite plus Android integration; record environment, steps, commands and actual outcomes, including cascade limits and sign-out pending behavior. Do not treat Firebase/Auth emulator behavior as proof of real Google OAuth sign-in.

### GYM-802 — Verify both layouts, continuity, and accessibility across the app

- [ ] Verified complete
- **Depends on:** GYM-104, GYM-105, GYM-501, GYM-502, GYM-503, GYM-504, GYM-505, GYM-601, GYM-602, GYM-603, GYM-701, GYM-702.
- **Scope/components:** cross-feature widget tests and Android phone/tablet-window verification.
- **Acceptance:** execute UI-V for every delivered screen/form/dialog, including 599/600/601 transitions during search, member selection, day/month changes, typing, and pending writes. Same features/actions in both modes; no clipped Arabic, inaccessible targets, repeated effects or state/listener resets. Confirm calm list styling and supplied loading/icon artwork in actual rendering.
- **Verification:** record a screen/state matrix with pass/fail evidence for required widths, text scaling, keyboard, landscape, rotation/split-screen, RTL/bidi and reduced motion. Profile representative hundreds-member search/list behavior only if observed performance requires investigation; fix failures in their owning feature tasks.

### GYM-803 — Close release decisions and verify the Android artifact

- [ ] Verified complete
- **Depends on:** GYM-801, GYM-802; unresolved D01–D08 and D10 closed or explicitly documented as an accepted supported boundary.
- **Scope/components:** production Android identity/signing, existing Firebase mappings, README/setup instructions and verification evidence.
- **Acceptance:** production identity/signing and Google registration agree; release network permission, launcher resources and Arabic label are correct. Firebase rules/index configuration matches actual repository queries. Record supported single-device/offline/batch limitations, resolved product choices, setup commands and outstanding external prerequisites. No task is complete solely because files exist; no privileged credentials are committed. Local readiness does not authorize deployment or store publication.
- **Verification:** final format check, `flutter analyze`, full focused suite, rules/emulator suite and debug/release Android build/install with the appropriate credentials available. Run the project's read-only flutter-code-review checklist. Report exact missing signing/service/device prerequisites instead of claiming a release check passed.

### GYM-890 — Verify, commit and push Phase 8

- [ ] Verified complete
- **Depends on:** GYM-801, GYM-802, GYM-803.
- **Scope/components:** Phase 8 fixes/artifacts and final verification record.
- **Acceptance:** follow the phase commit-and-push protocol after the complete release-readiness regression gate. Publishing/deployment still requires separate authorization.
- **Verification:** successful final checks, reviewed commit, successful push and matching local/remote branch SHA.

## Current handoff

- **Implemented:** Phases 1–3 delivered; Phase 4 authentication/session implementation is ready. Gym feature destinations remain scaffolding. D01–D09 are resolved/satisfied; D10 package, Firebase registration and private local signing coordination are complete.
- **Verification:** Phase 4 has 113 passing Flutter tests, clean analysis/formatting and a passing native Android auth/session scenario. See [verification/PHASE_4.md](verification/PHASE_4.md). Phase 3 rules/native evidence remains in [verification/PHASE_3.md](verification/PHASE_3.md). Actual Google OAuth is assigned to the user and remains unverified; no full-app or release-artifact success is claimed.
- **Delivery:** GYM-190 (`89c154d`, receipt `4f12849`), GYM-290 (`eaddbce`, receipt `8ce31d1`) and GYM-390 (`cf543f8`, receipt `cbb77e8`) are pushed and remotely verified. Phase 4 implementation `d59e592` is also pushed and remotely verified; its full verification gate remains open as recorded above.
- **Active scope:** complete ALL remaining tasks through Phase 8, superseding the
  earlier Phase 4 stop. GYM-401/GYM-490 await the actual Google OAuth result;
  independent later work continues.
- **In progress:** Phase 5 implementation has 128 passing tests and two passing
  native Android scenarios. See [Phase 5 evidence](verification/PHASE_5.md).
