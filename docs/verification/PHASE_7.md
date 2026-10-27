# Phase 7 — Settings and safe sign-out

Scope: GYM-701, GYM-702 and GYM-790. Starting local/remote main matched Phase 6
receipt bc6454f7ada7e52044d806244e7829aa1c8652c4, with a clean worktree.

## Behavior

- Gym name and whole-EGP default prices, including zero, with explicit Save.
  Immutable independent read/draft/submission fields preserve usable data and
  edited drafts. Remote updates replace only a clean draft; stale dirty saves
  require reviewing/reloading the latest settings. Negative/fractional prices fail.
- Current defaults prefill new subscription/drop-in intents. Historical payments
  and already edited payment drafts remain unchanged. Save completes on observed
  local application and permits the next offline settings edit. Eventual rejection
  preserves the desired retryable draft and stable operation ID while the shell
  retains affected-action feedback. Read errors do not unlock an in-flight save.
- Scrolling mobile fields and bounded/tablet account composition share controllers,
  Cubit and form subtree across layout replacement, including keyboard-open drafts.
- Sign-out checks observed mutation and snapshot pending information at action time.
  The warning offers stay/continue; it never asserts that a write reached the cloud.
  Dismissing or staying performs no sign-out. Confirmation is guarded against
  repeated dialogs. Continuing uses the existing auth teardown without clearing
  Firestore persistence. There is no wait-for-sync option, so cancel-wait is N/A.
- Idempotent sign-out already in a null identity now clears its busy state even
  when the identity source correctly emits no duplicate null event.

## Verification

Existing Flutter/Dart and Android emulator with demo-gymk Auth/Firestore services.
No live account/business data is used; product authentication remains Google-only.

- Settings Cubit tests cover zero/localized/default validation, remote updates vs
  dirty drafts, stale save/reload, duplicate submission, another offline edit after
  local completion, eventual rejection/retry with the same ID, new prefills vs
  edited drafts, cached read errors and recovery.
- Seven UI cases cover 390/600/1024 at 1×/2×, long Arabic gym names, controller and
  draft continuity with 280px keyboard insets, actual save, pending sign-out stay/
  continue, dialog continuity across 600px and one sign-out effect. An auth regression
  verifies already-signed-out busy cleanup. Full suite totals 159 tests.
- Native settings_sign_out_test passes. It saves defaults 300/50 offline and
  verifies new form prefills, queues an A member create and delete, chooses stay,
  resizes the dialog and continues sign-out. Old members/settings Cubits close and
  old names disappear. B starts empty with its own initial zero prices. Returning
  to A acknowledges the retained create/delete/settings queue, verified by server
  reads. An emulator-only linked email credential lets the fixture return to the
  same A identity; it is not a product sign-in option or a privileged credential.
- This run observes native Firestore 27.1.0 retaining A's queued mutations across
  A→B→A. It does not promise a global queue count, acknowledgement at sign-out,
  persistence after uninstall, or complete multi-device coordination.
- The first native run expected an incorrect login label; the exact existing
  Arabic label was corrected in the test and the complete rerun passed. A fake
  already-null auth fixture also exposed the busy cleanup regression above.
- Static analysis is clean. Formatting, full suite, git diff --check, read-only
  flutter-code-review and UI cleanup checks are delivery gates below. No package,
  store, artwork or signing configuration was changed.

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/settings_sign_out_test.dart -d emulator-5554 --no-pub --android-project-arg=kotlin.incremental=false --android-project-arg=kotlin.compiler.execution.strategy=in-process --no-android-gradle-daemon
```

Native viewport changes here use coherent TestFlutterView dimensions/insets;
Phase 8 still owns actual OS window/rotation and the complete accessibility matrix.
Logs are ignored under build/verification. No real Google OAuth success, production
rules deployment or store publication is inferred. Final delivery audit follows.

Final delivery checks: 178 Dart files pass the formatting check, static analysis
is clean, the full 159-test suite passes, and git diff --check passes. Read-only
review confirms repository/provider boundaries, stable mutation IDs, explicit
stream cleanup, independent failures and no credential/configuration changes.
Staged review and normal push/remote-SHA audit follow this record.
