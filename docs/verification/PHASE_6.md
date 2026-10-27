# Phase 6 — Drop-ins and monthly cash collected

Scope: GYM-601–604 and GYM-690. Starting main and origin/main both matched Phase 5
receipt 3767b04037163754672f21ff6cdecbe0f1a6d48c, with a clean worktree.

## Implemented

- Quick entry with optional name, captured/default amount and an explicit today's
  recording date, independently of the browsed day. Local midnight/resume changes
  today without moving a historical selection or discarding draft input. A save
  crossing midnight requires confirmation of the refreshed date.
- Previous-day browsing, ID-preserving name/amount/date correction and confirmed
  permanent deletion. A date correction moves the same record between day/month
  projections. Blank names render as بدون اسم. Stable intents and immediate guards
  apply; local completion resets quick entry without waiting for cloud recovery.
- Reports count payment records and sum subscription paidAt/drop-in date within
  calendar-month boundaries. Coverage dates never determine cash month. BigInt
  accumulation and locale-based exact formatting avoid signed-integer overflow;
  persisted individual amounts remain whole-EGP integers. No chart/server counter.
- Month selection, one emphasized total, subscription and drop-in summaries, clear
  incomplete-cache labels and observed pending input notices, including deletes
  whose rows disappeared. Data stays visible on read errors; no authoritative zero
  claim comes from an unverified cache.
- Mobile stacking and responsive tablet side-by-side entry/list and report cards.
  Shared controllers and state live above layout replacement. Clock is now injected
  directly at the session composition boundary; features do not obtain dependencies
  from another feature Cubit. Removed redundant subscription-form stream consumers;
  the repository already owns all source listeners and submission rechecks its
  current projection. Settings-prefill read errors remain independent of payment
  submission and cannot accidentally unlock a busy form.

## Verification

Existing Windows Flutter 3.47.1 / Dart 3.13.1, Android Medium_Phone emulator-5554,
Auth/Firestore emulators under demo-gymk. No live business data or deployment.

- Full Flutter suite: 145 tests passed (17 added). Pure/Cubit cases cover December
  and year bounds, November payment for December coverage, record counts, integer
  sums beyond signed 64 bits, exact display, live corrections/removals, incomplete
  cache/error preservation, pending deletion, localized amounts, optional names,
  stable retry, duplicate taps, midnight reconfirmation and historical day context.
- Widget cases cover phone/tablet at 390/600/1024, 1×/2× text, long Arabic names,
  599/600/601/1024 draft/controller continuity with keyboard insets, retained day
  and month, month picker/navigation, recorded today's date and live report values.
- Native dropin_report_test passes: online preload and known totals, offline quick
  entry, cross-month date correction, deletion, subscription amount correction,
  rejected payment-date edit with rollback in the selected report month, member
  cascade leaving independent drop-ins, actual Arabic quick form/keyboard,
  controller continuity phone→tablet→phone, and offline form completion/report UI.
- The first UI assertion ran before the SDK local snapshot arrived; the test now
  explicitly waits for that typed projection rather than equating animation
  settlement with data completion. Re-run passes. The emulator was restarted when
  it was no longer connected; Auth/Firestore services remained available.
- Formatting, clean static analysis and git diff --check are delivery gates.
  Final delivery details follow below. Existing platform Kotlin-migration warning
  remains nonblocking. One earlier successful native run logged a cancelled watch
  stream/protobuf warning during teardown; business assertions and reconnect checks
  had passed. This is not treated as production-backend evidence.

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/dropin_report_test.dart -d emulator-5554 --no-pub --android-project-arg=kotlin.incremental=false --android-project-arg=kotlin.compiler.execution.strategy=in-process --no-android-gradle-daemon
```

Logs are ignored under build/verification. No dependencies, settings configuration,
signing material or approved artwork were replaced. The read-only code-review and
UI cleanup skills were applied with AGENTS.md precedence. Final format check on
166 Dart files, clean analysis, 145 tests and the final native rerun pass. The
native UI test explicitly sets coherent logical keyboard insets when overriding
TestFlutterView viewport/density; an intermediate run exposed the mismatch between
real keyboard physical insets and the simulated viewport. It now preserves focus
and can reach Save. Actual OS rotation/window checks remain the Phase 8 gate.
Normal commit/push/remote-SHA audit follows; Phase 7 continues afterward.

Implementation `332ed6b96a086b9454daa142b3daf895c09f4539` was committed and pushed
normally to origin/main. Remote SHA matched local HEAD exactly; the remaining
worktree was clean. GYM-690 is complete. This receipt is pushed and remotely
verified before Phase 7 changes. Production deployment/publication are untouched.
