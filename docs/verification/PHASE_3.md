# Phase 3 verification — 27 October 2026

Scope: GYM-301–305 and its delivery checkpoint. User now authorizes all remaining
phases. Starting Git state was clean, with local/remote `main` both at Phase 2
receipt `8ce31d1859cc86071fc2f22e2630eaadd5767c5f`.

## Confirmed decisions and implementation

- D02: Gregorian `YYYY-MM-DD` coverage/session/payment dates; `paidAt` is the local
  recording date. `createdAt` is timestamp metadata, normalized to UTC when decoded.
- D04: compact persistent shell pending/error feedback. D06: fixed three days for
  MVP. D07: guarded complete-history, single-batch cascade boundary; larger or
  cross-device coordination is outside MVP. D08: temporary name `جيمك`, both initial
  prices zero. Product/architecture/design/task documents were reconciled.
- Immutable feature models preserve document/member/payment references on edits;
  serializers live at the provider boundary. Invalid records become typed errors,
  not empty successful lists. Whole-EGP/zero-purpose validation stays shared.
- One account-scoped typed `GymRepository` owns four replayed source streams and
  the mutation registry. This is a bounded gym aggregate with explicit resource
  methods, not a generic CRUD framework. Feature models remain in their features;
  the shared provider/repository implementation is in `app/session/data/`.
- Cached data stays visible after errors, but a failed read revokes completeness.
  New repository lifetimes do not inherit server confirmation from the SDK cache.
  SDK cancellation is preserved through map/transform adapters; close clears cached
  tenant references, and retry replaces source listeners without duplication.
- The first real MembersCubit consumes typed repositories, indexes subscriptions,
  keeps independent immutable read/query/filter/failure state, and cancels its
  subscriptions. Constructor/factory injection, explicit nullable clearing and one
  date read per list calculation are tested. No member screen is delivered here.
- Stable operation IDs, immutable notices, handled write futures and a per-member
  local mutation gate distinguish local application from eventual acknowledgement
  or rejection. A disappearing deleted row does not erase its pending operation.
  Local read-confirmation failure is not mislabeled as cloud rejection.
- Actual startup initializes Firebase and configures Firestore persistence/unlimited
  cache before repositories. Arabic loading/error/retry uses existing assets/theme.
- Owner-only schema rules validate defaults versus payments, actual calendar dates,
  clamped one-month periods, immutable references, and allowed fields. Firebase
  configuration was extended additively with local auth/Firestore emulators. No
  indexes are needed for the current full-collection reads. No rules deployment.

## Checks and evidence

Resolved existing toolchain: Flutter 3.47.1 / Dart 3.13.1; cloud_firestore 7.1.0,
firebase_auth 7.0.1, google_sign_in 7.2.0, native Firestore 27.1.0. Compatible
versions were resolved by `flutter pub add`; Google integration is Phase 4 work.

| Check | Result |
| --- | --- |
| Format check on `lib test integration_test test_driver` | Passed. |
| `flutter analyze --no-pub` | Passed, no issues. |
| `flutter test --no-pub --reporter expanded` | Passed, 86 tests (31 added). |
| Rules tests (`npm test` in `tool/firestore_rules`, emulator host set) | Six groups passed, including dozens of rejected input/access cases. |
| `npm audit --audit-level=high` in rules tooling | Zero vulnerabilities after the compatible grpc-js override. |
| Android integration through `flutter drive`, command below | Passed on `emulator-5554` / Medium_Phone. |
| `git diff --check` | Passed. |

The Android scenario calls the actual Firebase bootstrap and checks persistence
settings. All business test reads/writes use a separate named Firebase app pointed
at local `demo-gymk` auth/Firestore emulators, never live gym data. It verifies:

1. Empty offline cache is unverified; an offline member write reaches local
   application before cloud acknowledgement, then acknowledges after reconnect.
2. Repeated first-account bootstrap preserves existing settings.
3. An offline correction is locally applied; rules later reject it, the registry
   retains the affected-action failure, and the SDK rolls the record back.
4. Repeating one drop-in intent yields one record. Offline deletion removes the row
   while its operation remains pending, then acknowledges after reconnect.
5. Repository close completes without waiting for another snapshot. Reopening from
   cached history remains incomplete until server confirmation.
6. Sign-out/account B reads cannot display account A's cached member list.

Four startup widget cases cover phone/tablet at 1×/2× text, loading/failure/retry,
RTL, and single initialization/router creation across resize. State tests cover
failure preservation/clearing, search/filter/date refresh, fresh route factories,
500-member projection, listener retry/cancellation and late results.

## Environment and fixes found by verification

The default `java -version` process crashes on this machine. Firebase CLI 14.2.0
works with JDK 17 selected for its process only. Start local emulators with:

```powershell
$env:JAVA_HOME = 'E:/Programs/Java/jdk-17'
$env:PATH = "$env:JAVA_HOME/bin;$env:PATH"
firebase emulators:start --only 'auth,firestore' --project demo-gymk
```

The existing C:/E: Kotlin cache issue recurred under `flutter test` because that
command does not expose the required project arguments. The standard integration
driver successfully uses the already documented per-command workaround:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/data_provider_test.dart -d emulator-5554 --no-pub --android-project-arg=kotlin.incremental=false --android-project-arg=kotlin.compiler.execution.strategy=in-process --no-android-gradle-daemon
```

No global or project Gradle settings were changed for this workaround. The existing
Flutter/plugin Kotlin migration warning remains nonblocking. A debug-only manifest
permits cleartext localhost emulator traffic; release behavior is not relaxed.

Verification caught and fixed UTC/local timestamp representation, retrying a
previously final subscription field, async-generator cancellation delaying tenant
teardown, and stale completeness after a failed read. Focused regressions cover
these cases. Logs/APKs remain ignored under `build/verification/`.

## Review and delivery

Applied the project Cubit, UI cleanup and read-only code-review skills with
AGENTS.md precedence. No Bloc/events, use-case layer, second store, responsive
package, widget business rules or private signing material is included. Cubits
own their listeners; tenant repositories own SDK sources and eventual write errors.

User also confirmed production package `dev.tahahassan.gymk` and explicitly requested
new SHA-1/Firebase configuration. Independent Phase 4 preparation registered the
new Android app and debug/upload fingerprints and generated private local signing
inputs. The downloaded production config is ignored; coordinated local package
replacement, release signing and actual Google sign-in verification are Phase 4.
No Google OAuth, full app UI, process-restart persistence or production release
success is claimed by this phase.

Implementation commit/push and remote SHA receipt are pending.
