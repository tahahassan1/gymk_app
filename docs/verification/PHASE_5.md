# Phase 5 — Members and monthly subscriptions

Scope: GYM-501–505 and delivery checkpoint GYM-590. The latest user instruction
authorizes continuation through Phase 8. Initial local/remote main both matched
57c5a985dc48222e3fe64f76dd934c0c972b4b3f; the worktree was clean and there is one
worktree. Existing configuration, signing inputs and assets were preserved.

## Delivered behavior

- Lazy searchable/filterable member list, current coverage/status and honest
  incomplete/read-error feedback. A local-midnight timer and resume observer
  refresh date-sensitive state; owners cancel timers and subscriptions on close.
- Add/edit member, optional string phone, member search with inline creation and
  selection, shared bounded forms with controllers above layout replacement.
- Settings-prefilled whole-EGP subscription payments, automatic continuous-expiry
  renewal, editable nonfuture manual start, calendar-month preview and stale-preview
  reconfirmation. Stable IDs and immediate guards prevent duplicate submissions.
  Corrections preserve payment/member references and unchanged automatic future
  starts. Stale edits fail explicitly. Both modal and direct-route entry work.
- Details and history, ordinary correction and confirmed permanent deletion.
  Coverage recalculates without shifting remaining historical dates. Local form
  completion does not wait for cloud acknowledgement; session feedback outlives forms.
- MemberDeletionCoordinator checks complete member/history reads and a bounded
  200-subscription history. Repository submission rechecks IDs under the same-member
  mutation gate. Exactly one batch deletes at most 201 documents; there is no split
  fallback. Independent drop-ins remain. Read-observation uncertainty keeps the
  member gate until the remote outcome rather than allowing conflicting writes.

## Cascade boundary

Inspected installed cloud_firestore 7.1.0 WriteBatch implementation and native
Firestore 27.1.0 behavior. Current [Firebase quotas](https://firebase.google.com/docs/firestore/quotas)
specify a 10 MiB request bound and 20 rule document accesses for batched requests;
the 500 field-transformation limit is not a batch-document limit. Current
[batch guidance](https://firebase.google.com/docs/firestore/manage-data/transactions)
also warns about index/request size. Our 200-subscription limit is a conservative
application boundary, not a claimed universal backend maximum. Deletes contain
bounded document paths; subscription fields are fixed scalar values. Delete rules
perform no get/exists lookups. The actual 201-delete boundary passed on Android
against the emulator. Larger histories and cross-device cascade races are outside
the accepted MVP; completeness is not carried across process restarts.

## Verification

Windows, Flutter 3.47.1 / Dart 3.13.1, Medium_Phone emulator-5554. Local Firebase
Auth 9099 and Firestore 8080 under demo-gymk, with process-local JDK 17. No live
business data or production rules deployment is involved.

- Full Flutter suite: 128 tests passed. Added seven business-flow tests and eight
  UI cases. Covers trimmed/localized input, local completion, stable retry,
  duplicate prevention, October/November/December extension, changed previews,
  date rollover, future amount-only edits, stale edits, missing members,
  middle/only deletion and incomplete/oversized/conflicting cascades.
- UI tests: Arabic long names and bidi phone, 390/600/1024 at 1×/2×; 599/600/601
  search continuity; same controllers with keyboard insets and resize; inline
  member creation→selection→subscription. Existing 500-member projection and
  auth/session tests remain green. Lists use the shared repository, no row queries.
- Native member_subscription_test passed: offline member correction and renewal,
  one stable payment with the correct recording month, offline subscription
  correction/deletion, a rejected immutable payment-date change and rollback,
  and atomic member+200-subscription removal with independent drop-in retained.
- Native member_ui_test passed: real Arabic app/form rendering, keyboard-open
  member entry, draft/controller continuity across phone/tablet viewports, offline
  local form closure, details→renewal and amount continuity on resize.
- Formatting and static analysis are checked for delivery; final commands and
  delivery SHA are recorded below. Test-run setup issues were corrected in test
  helpers; no production lifecycle success was inferred from those failures.

Native command (for each target above):

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/member_subscription_test.dart -d emulator-5554 --no-pub --android-project-arg=kotlin.incremental=false --android-project-arg=kotlin.compiler.execution.strategy=in-process --no-android-gradle-daemon
```

The same command with member_ui_test.dart executes the actual UI scenario. Local
logs are ignored under build/verification. The existing Kotlin migration warning
is nonblocking; global toolchain configuration was not changed.

## Review and delivery

Applied flutter-cubit, flutter-ui-cleanup and the read-only flutter-code-review
checklist with AGENTS.md precedence. Repository/provider SDK boundaries remain;
no Cubit-to-Cubit subscriptions, extra store, package, events, soft deletion or
private signing content were introduced. Reusable UI sections have their own files.
Phase 8 owns the complete width/accessibility and process-restart matrix.

Final format check (141 Dart files), clean analysis, full 128-test suite and
git diff --check pass. Native business and UI scenarios both passed. Staged
review and normal push/remote-SHA audit follow this record.
Real Google OAuth remains separate: the user has asked for the three test steps;
no successful result has yet been recorded.
