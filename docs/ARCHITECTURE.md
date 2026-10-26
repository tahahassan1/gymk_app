# Gymak — Application Architecture & Implementation Contract

Version: 0.0.1 · Flutter / Android · Firebase Auth + Cloud Firestore

## 1. Read this first

Read the current `PRD.md` for product behavior and `DESIGN_STYLE.md` for visual/interaction guidance. This document describes implementation structure, data ownership, and failure handling. It is a specification, not evidence that code or tests already exist.

Use **feature-first BLoC presentation pattern**, following the official Bloc architecture [1]: **Presentation → Business Logic → Data (Repository → Data Provider)**. Use GetIt for dependency injection. Use Firestore persistence as the only durable application-data store. Do not add Hive, SQLite, Drift, a custom sync engine, or a mandatory use-case layer.

Use Cubit for all feature flows, including repository streams, authentication, member lists, statistics, and forms. Do not create Bloc classes or event files. Expose intention-revealing Cubit methods for user actions, manage repository subscriptions within the Cubit, and emit immutable states.

Use two explicit UI layout variants, mobile and tablet, within the Presentation layer. Each variant must be responsive using Flutter framework APIs only. Select variants through one shared custom `AppAdaptiveLayout` built on Flutter `LayoutBuilder` and centralized width breakpoints. These are presentation variants, not additional business/data layers.

### Authority and unresolved decisions

- Confirmed product rules override convenience in the architecture: permanent deletion, no archive/void workflow, owner-only tenancy, one-month memberships, and early renewal preserving remaining time.
- Design defaults are defined in `DESIGN_STYLE.md`. The confirmed two-layout, framework-only adaptive requirement in this document overrides any earlier phone-only layout guidance in that design document.
- The PRD confirms whole EGP (scale 1), zero defaults, and positive payment records.
  Expiry-threshold configurability and a sync indicator remain open. Three days
  is the current rule with no settings control; compact pending/error feedback
  remains a presentation recommendation, not an approved indicator decision.
- The PRD's date-only wording conflicts with its description of `paidAt` as a moment. Section 6 proposes a precise encoding without adding a payment-date feature.
- Firestore cannot make data available offline before it has been fetched. Section 8 qualifies the PRD's broad offline promise; do not silently promise a capability the SDK cannot supply.
- Manual future starts are prohibited; automatic early renewal is exempt.
  Gap/future-only history is expired when today is uncovered, with renewal from
  today and remaining dates preserved (section 7). Cascades larger than one
  write batch remain unresolved (section 10).

## 2. Responsibilities and dependency direction

| Component | Responsibilities | Must not do |
| --- | --- | --- |
| View and mobile/tablet layouts | Render shared Cubit state, collect input, adapt presentation, navigate, show dialogs/snackbars | Query Firestore, calculate expiry, sum income |
| Cubit (Business Logic) | Form state, filtering/selection, user actions, combine repository data into UI state | Own Firebase documents or duplicate the SDK's durable write queue |
| Repository interface | Typed read streams and mutation contracts | Expose Firestore snapshots or widget types |
| Repository implementation (Data) | Typed models, transformations, errors, shared streams and mutation contracts | Navigate, display messages, or emit UI state |
| Firestore data provider (Data) | Tenant paths, raw SDK snapshots/maps, document writes, batch commits and SDK metadata | Own UI filters, labels, or membership-status decisions |
| Pure policy/calculator | Calendar arithmetic, coverage, member status, statistics | Import Flutter or Firebase |
| App composition | Initialize services, DI, auth/session scope, routes, theme | Become a global mutable business-state object |

Views invoke Cubit methods. Cubits depend on injected repositories, apply pure policies, and emit immutable state. Mobile and tablet layouts consume the same Cubit instance and repository projections. Repositories call data providers and return typed records. Streams carry data back up to state and UI. User actions travel down; state travels up.

No Cubit may depend on, subscribe directly to, or mutate another Cubit. Share repository streams for cross-feature data updates. For a genuine UI coordination effect, a presentation-level BlocListener may invoke a method on another Cubit without coupling their classes. Avoid cross-repository coupling too; coordinate multi-record business operations explicitly.

Use small Firebase-facing data providers as the SDK boundary. Separate providers by meaningful API/resource responsibility; do not create one provider per repository method. This boundary is intentional even when Firestore is the only backend. Do not add generic CRUD base classes, one-line use cases, or duplicate DTO/domain models for every simple record.

## 3. Project layout

The following is a path mapping, not a requirement to generate empty files in advance.

| Path | Contents |
| --- | --- |
| `lib/main.dart` | Bootstrap entry point |
| `lib/app/app.dart` | MaterialApp and localization |
| `lib/app/di.dart` | GetIt composition and session-scoped registrations |
| `lib/app/router.dart` | go_router routes and auth redirects |
| `lib/app/session/` | Authenticated-session lifecycle and shared read projection |
| `lib/core/theme/` | Design tokens and ThemeData |
| `lib/core/ui/` | Reusable visual components |
| `lib/core/ui/adaptive/` | Shared `AppAdaptiveLayout` and centralized `AppBreakpoints` |
| `lib/core/errors/` | Typed application failures and mapping |
| `lib/core/time/` | DateOnly, Clock, date codecs, month arithmetic |
| `lib/features/auth/` | Sign-in, AuthRepository/provider, auth/session Cubit |
| `lib/features/settings/` | Gym settings model, repository/provider, settings Cubit, view |
| `lib/features/members/` | Model, repository/provider, list/details Cubits, form Cubit, views |
| `lib/features/subscriptions/` | Model, repository/provider, pure policy, renewal form Cubit, sheet |
| `lib/features/dropins/` | Model, repository/provider, day-list Cubit, form Cubit, views |
| `lib/features/statistics/` | Pure calculator, month/report Cubit, view |
| `test/` | Business-policy and state-flow tests |
| `integration_test/` | Critical end-to-end offline/session flows |
| `firestore.rules` | Tenant isolation and record validation |
| `firestore.indexes.json` | Only indexes required by actual queries |

Within a feature use `data/models/`, `data/providers/`, `data/repositories/`, `business_logic/cubit/`, `business_logic/policies/`, `presentation/views/`, `presentation/layouts/`, and `presentation/widgets/`. Do not generate empty directories. Repositories/providers must not import business_logic or presentation; move universally shared value objects to core when needed. Cubits and pure policies must not import feature widgets or Firebase. Presentation consumes Cubit state and dispatches user intent. Avoid circular feature dependencies.

Example names: `Member`, `MemberRepository`, `FirestoreMemberRepository`, `MemberFirestoreProvider`, `MembersCubit`, `MembersState`, `MembersView`, `MembersMobileLayout`, `MembersTabletLayout`.

Example ownership: `MembersView` calls `MembersCubit.searchChanged(query)`; the Cubit updates its filter over a shared member projection and emits `MembersState`; `BlocBuilder` renders rows through the selected mobile or tablet layout. A `SubscriptionFormCubit` exposes `amountChanged`, `startDateChanged`, and `submit`. No event files are created. These are naming/ownership examples, not prescribed SDK signatures.

## 4. Packages and initialization

| Concern | Choice |
| --- | --- |
| State | Cubit exclusively, using `bloc` / `flutter_bloc`; no Bloc subclasses or event files |
| Responsive UI | Flutter framework widgets/APIs only; no responsive/adaptive packages |
| Adaptive layout selection | Shared custom `AppAdaptiveLayout` using `LayoutBuilder` and `AppBreakpoints` |
| DI | `get_it` |
| Backend | `firebase_core`, `firebase_auth`, `cloud_firestore` |
| Google sign-in | Compatible current `google_sign_in` integration with Firebase Auth |
| Navigation | `go_router` |
| Localization | Flutter localization tooling and `intl` |
| Equality | Immutable Dart models; `equatable` if useful |

Inspect the actual Flutter/Dart SDK and resolve compatible package versions at implementation time. Do not copy an old Google sign-in initialization API or guess package versions from this document. Code generation is optional; do not require Freezed merely for a few small models.

Bootstrap order: initialize Flutter bindings, initialize Firebase, configure Firestore persistence/cache before its first use, register app dependencies, restore auth state, then start the appropriate route/session scope. Provide a readable initialization failure instead of leaving a blank splash indefinitely.

## 5. State management, DI, and routes

### Cubit state and user actions

Prefer one immutable state object with explicit fields rather than a mutually exclusive loading/success/error class tree that loses existing data on every action. Typical fields: initial load phase, data, query/filter, action submission phase, and optional failure. Keep cached records visible while a new operation is pending.

Use `BlocBuilder`/selectors for rendering and `BlocListener` for one-time UI effects. A rebuild must not repeat a snackbar, dialog, navigation, write, or subscription. Local TextEditingControllers remain in the view and are disposed there. Cubits own submitted values/validation state, not BuildContext. Inject them with BlocProvider; use RepositoryProvider where appropriate at the composition boundary. BlocProvider-created instances are disposed by that provider; establish explicit ownership for externally created instances to avoid double-close or leaks.

Suggested components: `MembersCubit`, `MemberDetailsCubit`, `DropinsCubit`, `StatisticsCubit`, `AuthCubit`, `MemberFormCubit`, `SubscriptionFormCubit`, `DropinFormCubit`, and `SettingsCubit`. A tiny static view does not need a state container solely for symmetry.

Expose intention-revealing methods such as `watchMembers()`, `searchChanged(query)`, `filterChanged(filter)`, and `deleteMember(id)`. Keep states immutable. Manage repository StreamSubscriptions within the owning Cubit, handle stream errors, cancel subscriptions in close, and prevent emissions after disposal. Do not create event classes.

Be explicit about concurrency inside Cubit methods. Use submission guards and per-member coordination to serialize conflicting mutations, reject duplicate submission while an operation is pending, and allocate one ID per payment intent. A stale-result guard can protect asynchronous reads; it cannot undo a submitted payment write. Do not introduce Bloc event transformers.

### Session lifetime

- Firebase SDK objects and AuthRepository are app-scoped.
- Repositories with tenant paths, shared read projections, and subscriptions are scoped to the current UID.
- Route/form Cubits are factories, not app-wide singletons.
- Inject dependencies through constructors. Resolve GetIt at composition boundaries, not throughout widgets or business policies.
- Capture the UID when constructing a tenant repository; do not silently switch its paths when another user signs in.
- On session change cancel listeners, dispose Cubits and read projections, reset the tenant DI scope and navigation state, and clear in-memory form/data references.
- Never display a previous gym's cached in-memory list during another user's initial load.

Use a stateful navigation shell or equivalent to preserve the same four destination branches across both layouts. Mobile uses bottom navigation; tablet can use Flutter NavigationRail when space permits, retaining the same destinations, routes, selection, and navigation history. Routes include login, members, member details, drop-ins, statistics, and settings. Forms can be modal sheets on mobile and bounded dialogs/sheets on tablet, sharing one form body and submission logic. Router redirects follow auth state without performing writes from route builders.


### Adaptive and responsive Presentation contract

#### Two layout variants, one feature implementation

Provide a `MobileLayout` and a `TabletLayout` for each primary screen whose composition changes with available width. Keep them in `lib/features/{feature}/presentation/layouts/`, for example `MembersMobileLayout` and `MembersTabletLayout`.

Keep the feature entry view in `presentation/views/`. It owns the shared Cubit/provider boundary, one-time UI effects, and state that must survive layout replacement. It delegates visual composition to the shared adaptive selector. Reuse fields, lists, history rows, summaries, and form bodies from `presentation/widgets/`; do not duplicate whole features or create separate repositories/Cubits for each device layout. A small identical screen may share the same body between its two compositions; do not manufacture differences or empty layout classes.

- **Adaptive behavior:** choose a different composition, such as stacked content versus a multi-column arrangement, based on the shared width policy.
- **Responsive behavior:** let the chosen composition reflow, constrain content, wrap text, and adjust spacing within its available size.
- Both properties are required. A tablet layout is not a uniformly scaled mobile screen, and neither layout is a fixed-size canvas.
- Mobile/tablet names identify available-space modes, not hardware detection. A tablet in a narrow split-screen window may use the mobile layout; a sufficiently wide phone window may use the tablet layout.
- These two variants remain inside Presentation. Do not add a third application-architecture layer, desktop-only implementation, or a separate business-logic path.

#### Central breakpoints and shared selector

Use `AppBreakpoints` and `AppAdaptiveLayout` as the single source of layout-mode selection. Use logical pixels from finite parent width constraints, not physical pixels, device model, operating system, shortest-side hardware classification, or orientation alone.

Initial project breakpoint (an implementation default):

| Available width | Selected variant |
| --- | --- |
| Less than 600 logical pixels | Mobile |
| 600 logical pixels or greater | Tablet |

Exactly 600 selects tablet. Wider widths remain in the tablet variant, using fluid spacing, wrapping, column constraints, and readable maximum content widths. Do not introduce a third desktop mode. Keep 600 in one named constant; change that constant if real screen-content validation justifies a different threshold. Do not scatter `width < 600` checks or independent device selectors across features.

Place the shared selector at the bounded full screen/shell composition boundary, before fixed-width navigation or detail panes reduce the available content width. Use that same selected mode for shell navigation and screen composition. Do not accidentally reclassify a 400px pane inside the tablet layout as a mobile device layout. Local LayoutBuilders inside either layout may use their own constraints for responsive sizing without selecting a new application mode.

Use lazy builder callbacks so only the selected layout subtree is built. Do not render both alternatives with Offstage/IndexedStack just to keep application state alive. Keep durable feature state above the layout branch instead.

The following framework-only example defines the expected selection contract; it is illustrative source, not code already implemented or compiled in the project:

```dart
import 'package:flutter/widgets.dart';

abstract final class AppBreakpoints {
  static const double tablet = 600;
}

typedef AdaptiveLayoutWidgetBuilder = Widget Function(
  BuildContext context,
  BoxConstraints constraints,
);

class AppAdaptiveLayout extends StatelessWidget {
  const AppAdaptiveLayout({
    super.key,
    required this.mobileBuilder,
    required this.tabletBuilder,
  });

  final AdaptiveLayoutWidgetBuilder mobileBuilder;
  final AdaptiveLayoutWidgetBuilder tabletBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          throw FlutterError(
            'AppAdaptiveLayout requires a bounded parent width.',
          );
        }
        return constraints.maxWidth < AppBreakpoints.tablet
            ? mobileBuilder(context, constraints)
            : tabletBuilder(context, constraints);
      },
    );
  }
}
```

Use one selector at the appropriate composition boundary, for example:

```dart
AppAdaptiveLayout(
  mobileBuilder: (context, constraints) => const MembersMobileLayout(),
  tabletBuilder: (context, constraints) => const MembersTabletLayout(),
)
```

Place the feature's existing Cubit provider and UI-effect listener above that selector. Its layout children may consume the same Cubit with BlocBuilder/BlocSelector; do not construct a new Cubit in either builder. For a shared app shell, pass the selected layout mode into screen composition rather than implementing another breakpoint policy. Choose one composition ownership scheme consistently across routes.

#### Framework-only responsive implementation

Use Flutter's own `LayoutBuilder`, `SliverLayoutBuilder`, `MediaQuery` aspect APIs, `Flex`/`Row`/`Column`, `Expanded`, `Flexible`, `Wrap`, `ConstrainedBox`, `SizedBox`, `Padding`, `SafeArea`, and scrollable/sliver widgets as appropriate. Use grid delegates such as `SliverGridDelegateWithMaxCrossAxisExtent` where fluid column counts are useful. These are tools, not a requirement to use every one on every screen.

- Use parent constraints for local sizing; use `MediaQuery` aspect APIs for window-level information, text scaling, safe areas, and keyboard insets when needed.
- Bound text and forms to readable maximum widths on larger screens. Let lists, columns, and grids use the available area without oversized empty stretching.
- Preserve theme typography and touch-target minimums. Let system text scaling work; never globally scale all fonts, padding, heights, or icons against a reference design width.
- Handle short landscape windows and the onscreen keyboard with scrolling and safe-area/inset handling. A wide window can still have limited height.
- Keep Arabic RTL, long names, mixed-direction phone/date strings, and large text usable in both layouts.
- Keep the same data, features, and action semantics in both variants. Additional columns can reveal existing information; they must not invent new business capabilities.
- Do not add `flutter_screenutil`, `responsive_framework`, `responsive_builder`, `sizer`, adaptive-scaffold packages, or similar dependencies for layout adaptation or responsiveness. Existing non-layout packages such as flutter_bloc and go_router remain allowed.

#### Preserve state across resize and rotation

Crossing a breakpoint must not reset the selected destination, selected member, search query, filters, selected report month/day, entered form values, or pending mutation context. Keep state above replaceable layout subtrees in the existing Cubit or shared view/form host as appropriate. Keep controllers needed for the same open editing task in that stable host, or restore them deliberately from maintained form state.

Do not start repository listeners, reload data, submit writes, or create new Cubits because a layout builder runs. Avoid width-dependent keys on state-owning providers. Preserve relevant scroll positions with stable PageStorage keys/controllers where practical. When a sheet/dialog remains open during resizing, keep its entered values and safe constrained layout; do not dismiss or resubmit it automatically.

UI-owned selection and scroll state should not be moved into repositories merely to preserve it across layout changes. Do not retain both entire device UIs as a workaround for misplaced state ownership.

## 6. Data model and encoding

Keep all tenant-owned data under `users/{uid}`. Retain the PRD's flat child collections; subscriptions are not nested under member documents.

| Path | Model fields |
| --- | --- |
| `users/{uid}` | `settings: {gymName, defaultSubscriptionPrice, defaultDropinPrice}` |
| `users/{uid}/members/{id}` | `name`, optional `phone`, `createdAt` |
| `users/{uid}/subscriptions/{id}` | `memberId`, `startDate`, `endDate`, `amount`, `paidAt` |
| `users/{uid}/dropins/{id}` | optional `name`, `amount`, `date` |

Use the document ID as the typed model ID. Do not maintain a second conflicting ID field. Do not store member status or a second authoritative expiry on the member document. Derive them from subscription records.

### Proposed concrete encodings

- `startDate`, `endDate`, and drop-in `date`: validated, zero-padded Gregorian `YYYY-MM-DD` strings representing a calendar date. Firestore has no special date-only scalar.
- `paidAt`: the recording/payment calendar date in the same date-only encoding, assigned on form submission. This reconciles the PRD's date-only rule with its requirement that payment belongs to the recording month. If an exact payment instant is required later, explicitly revise this schema and the PRD together.
- `createdAt`: client recording timestamp, usable immediately offline; treat it as metadata rather than an authoritative membership/payment date.
- Optional `updatedAt` may be a timestamp when implementing edits. It is not an audit log.
- `amount` and default prices: integer whole EGP, scale 1 (the app's smallest
  accepted monetary unit). An integer 125 means EGP 125, not 1.25. The user
  confirmed this choice on 27 October 2026. No piastre conversion or floating-point
  sums. `GymkCurrency` centralizes the code and scale.
- The app-facing DateOnly value is separate from timestamps and knows how to
  compare and add a calendar month with end-of-month clamping. Persisted date
  codecs remain gated by the unresolved concrete encoding decision.

Use the device's local calendar date for this single-location MVP, behind an injectable Clock. A fixed gym timezone is a future decision if devices across timezones become supported. Never convert a date-only value to UTC midnight and back just to store or compare it.

Validate required trimmed names, valid dates and whole-EGP amounts. Defaults may
be zero; payment records must be positive. The pure amount policy parses digits
as integers without double conversion, accepting Western/Arabic-Indic/Persian
digits and `.`/Arabic decimal separators. A zero-only decimal suffix represents
an exact whole amount; nonzero fractional digits are rejected, never rounded.
Grouping separators and scientific notation are rejected. Values outside Android's
signed 64-bit integer range are rejected. Formatting belongs in Presentation.
Phone numbers are strings, not integers, and need not be unique. IDs and member
references are immutable during edits.

## 7. Pure membership and reporting policies

### Calendar arithmetic

Adding one month preserves the day number where possible and otherwise clamps to the target month's last day. It is not `Duration(days: 30)`, and default DateTime overflow behavior must not decide the result accidentally. Repeated additions apply to the resulting date; 31 January → 28 February → 28 March in a non-leap year, matching the PRD's current rule.

### Coverage and status

Use half-open periods: a recorded period covers `startDate <= today < endDate`. Compute remaining days as calendar-day differences, not rounded elapsed hours. Expiry is exclusive.

Normal early renewal creates the next adjacent period starting at the current overall expiry. For status, combine adjacent/overlapping periods into continuous coverage. An internal coverage calculation does not require a new product status or a user-facing scheduling feature.

| Situation | Result |
| --- | --- |
| No subscription records | No subscription |
| Current coverage with >3 days until its end | Active |
| Current coverage with 1–3 days until its end | Expiring soon |
| Records exist but no coverage contains today, including gaps/future-only history | Expired |

An early renewal must keep the member active now and extend the displayed overall expiry. Do not derive current status solely from the most recently created document's future `startDate`.

### Renewal command

1. Read the member's current in-session coverage projection.
2. Default start to current continuous coverage end if active, otherwise today.
3. Compute the new end with the calendar-month helper.
4. Preview current expiry and new expiry in the sheet.
5. On submission re-evaluate against the current projection; if another local change invalidates the displayed dates, update the preview and require a fresh confirmation.
6. Allocate a document ID once and submit one immutable record. Record `paidAt` from the submission date.

Example: joins 26 October, expires 26 November, renews 10 November → displayed expiry 26 December; the new payment counts in November.

### Edits and deletions

An edited subscription recomputes its own end from its start. A deleted subscription stops contributing to coverage and income. Do not silently change dates on other historical subscriptions; an early-renewal payment can already have a recorded period of its own.

Deleting or changing a middle period can leave a gap or future-only records.
Confirmed on 27 October 2026: preserve remaining dates; if no coverage contains
today, classify the membership as expired and default renewal to today. No
upcoming status. No records still means no subscription. The policy exposes
current expiry separately from latest past expiry and remaining date ranges;
future-only history has neither a current nor a past expiry.

Manual start selection must be today or earlier. Automatic early renewal can
start at the future continuous expiry. Do not globally reject future dates in
stored models or Security Rules: that would reject valid early renewals. An
amount-only correction must preserve an existing automatic future period without
treating its unchanged start as a newly selected manual date. Form integration
and record mutation remain Phase 5 work. A proposed period can connect remaining
coverage across a gap; preview its merged current expiry without shifting any
existing period's dates.

### Reporting

The calculator accepts a selected calendar month, subscription records, and drop-ins. Sum integer amounts and counts by each record's payment/session date. Use start-inclusive/end-exclusive month bounds. Statistics count subscription records, not unique members. Deleted records are absent; edits and deletions automatically change totals. No expenses, profit calculation, amortization, or server aggregate counters.

For date-only subtraction, use calendar components (for example UTC date objects created solely for arithmetic) so daylight-saving days do not produce off-by-one remaining-day counts.

## 8. Offline reads and dataset completeness

Firestore manages persistent cache and queued writes [3]. Configure the requested unlimited cache, but do not equate unlimited size with automatic download or permanent backup.

For the intended small-gym workload, maintain shared session listeners for settings, all members, all subscriptions, and drop-ins. Reuse these streams/projections across tabs instead of issuing per-row queries. Index subscriptions by member ID in memory. Filter member search and calculate reports locally.

Loading all drop-ins is an explicit simplicity tradeoff for the initial small dataset; do not silently introduce per-day pagination that breaks historical offline reports. If real usage makes the dataset too large, revise the read strategy and offline reporting requirements together.

### First session / new device

- First Google sign-in and initial server download need a connection.
- Attach all required listeners; preserve cached/local records while server data arrives.
- Track loading, cache-sourced data, server-confirmed completeness, and failures separately.
- A server-confirmed full-collection snapshot establishes completeness for that query at that moment. Cached snapshots after a cold start do not by themselves prove full account completeness.
- Do not display an unverified empty cache as “this gym has no members” or a complete zero-income month.
- On offline cold start, show usable cached records, but keep completeness conservative until verified. A previously fetched cache supports offline work; a fresh installation with no data cannot.
- Unlimited cache does not survive uninstall/app-data clearing and does not protect unsynced records from device loss.

Snapshot metadata such as cache origin and pending writes belongs in a repository envelope, not the domain model. Widgets never inspect Firebase metadata directly. Do not label `fromCache == true` as a definitive connectivity check.

Recompute date-sensitive membership status when the app resumes and at local date rollover, even if Firestore documents did not change. Inject Clock for deterministic tests.

## 9. Offline writes and local-versus-remote completion

The UI must not wait for server acknowledgement to finish normal offline actions. Firestore listeners expose local changes while the remote acknowledgement can remain pending. Validate the installed FlutterFire behavior in integration tests; do not assume an awaited write Future is an immediate durable local-save acknowledgement.

Define a repository-level mutation handle with a stable operation/document ID, observable local application, eventual remote acknowledgement, and failure. Exact Dart API design is left to implementation; the distinction is mandatory.

- Generate the document ID once per user intent. Disable double submission immediately.
- Submit through the SDK and observe the expected local stream change or operation-specific metadata. Release the form after local application, not after network recovery.
- Attach error handling to every write Future even when it is not awaited by the form. Do not use fire-and-forget with unhandled failures.
- Keep domain data sourced from repository streams, not a second manually maintained optimistic list.
- Retain enough in-session operation context to explain a rejected write. A rejected operation may roll back the local projection and must update its feedback.
- Reuse the same ID on retry when acceptance is uncertain. Do not create another payment every time a timeout occurs.
- Pending deletion can remove a row from local results; `hasPendingWrites` on a visible row is not a complete global tracker of all deletes. Track current-session mutation handles and do not promise an exact global pending count after process restart.
- The SDK owns durable pending writes. Do not build a parallel persistent queue or custom conflict resolver.

If the sync-indicator recommendation is accepted, expose conservative session-level states such as local changes pending, current observed data acknowledged, or failed action. Never say “all account data is synced” based solely on one listener.

## 10. Editing, permanent deletion, and cascade limits

Normal record edits and deletes go through the owning repository and remain available offline after data is loaded. There is no archive flag, deletedAt, voidedAt, deletion history, or undo facility.

Deleting a member must explicitly delete their flat subscription documents; deleting a document does not delete related records [5]. Put cross-collection cascade behavior in a narrowly scoped `MemberDeletionCoordinator` injected with the needed repository/data-write capability. It is a justified multi-record operation, not the start of a mandatory use-case layer.

Preferred small-gym flow:

1. Collect all known subscription IDs for the member from a verified complete subscription dataset.
2. Prevent new in-session renewals/edits for that member during submission.
3. Show the permanent-delete confirmation with cascade/statistics consequences.
4. Submit member + subscription deletions as one atomic write batch when it fits current SDK/backend request limits. Batched writes support offline use; transactions are not the offline solution [4].
5. Reflect local deletion from the stream, track remote result, and recompute statistics.

Do not assume the number of writes or request size is unlimited. Verify current SDK/backend limits. If a member's history cannot fit one batch, surface the limitation and require an explicitly designed resumable multi-batch or server-assisted flow before claiming support. Do not split it silently and still claim atomic deletion. This is a known implementation boundary to settle before production use, not a reason to add an unsolicited backend now.

Likewise, if the local history is incomplete, do not claim that all subscriptions were deleted. Keep cached read access available and require completion before a cascade that cannot be enumerated safely. This is a necessary qualification to the PRD's blanket offline wording.

Single-device ownership is the primary supported workflow. Another device can create a subscription during a deletion or independently renew the same member. Firestore last-write-wins handles competing writes to the same document; it does not prevent duplicate records or guarantee cross-device referential integrity. Do not claim otherwise. Robust multi-device deletion/renewal coordination is outside this MVP.

## 11. Authentication and sign-out

- Restore the existing Firebase session for offline use; do not force Google sign-in each launch.
- Distinguish first-use authentication errors from unavailable business-data snapshots.
- On first account setup, create settings only when absent; never reset existing prices on every login.
- Do not use an empty cache as proof that the user document does not exist on the server. Initial account creation is an online bootstrap concern.
- Sign-out should explain pending local changes when known and offer to remain signed in. If the user explicitly continues, do not claim those changes reached the cloud or erase SDK persistence as routine cleanup.
- Never wait indefinitely for pending writes to finish while offline. An optional wait-for-sync path must allow cancellation/back navigation.
- After sign-out tear down tenant memory/listeners and return to login. Verify account switching with cached data in integration tests.

## 12. Security and error handling

Ship Firestore rules that scope reads/writes to `request.auth.uid == uid`, deny unauthenticated and cross-tenant access, and allow the confirmed create/update/delete operations. Add practical schema/type validation for money, required names, date encodings, and immutable member references. Do not rely on UI validation alone. Keep user-facing policies and rule constraints consistent, especially for queued offline writes.

The PRD's broad owner rule is the isolation starting point, not complete field validation. Do not place privileged credentials in the app. Do not add a rule denying all delete operations.

Map SDK exceptions to typed failures such as validation, permission, auth/session, unavailable data, and rejected write. Show actionable Arabic copy from the presentation layer. Log useful diagnostic context without names, phone numbers, or payment details. Do not catch every exception and turn it into an empty successful list.

## 13. Performance and consistency

- Lazily render rows and keep filtered member projections out of widget build methods.
- Join loaded members and subscriptions using maps, avoiding a full scan per row.
- Share listeners within the session; navigation should not create duplicate permanent subscriptions.
- Preserve current data during background refresh and independent form submission.
- Keep money/date formatting centralized and separate from stored values.
- Use narrow widget rebuilds where they improve the list; profile before adding isolates or elaborate memoization.
- Query/report logic must use one consistent local projection so deleting a payment updates details, list state, and statistics together.

## 14. Meaningful verification

These are implementation acceptance cases, not tests that have already run.

| Area | Required cases |
| --- | --- |
| Calendar math | 31 Jan in leap/non-leap years; 31 Dec rollover; repeated clamped renewals |
| Status | End date exclusive; three-day boundary; no subscription; date rollover without new snapshots |
| Early renewal | 26 Oct → 26 Nov; renewal on 10 Nov → 26 Dec; multiple early renewals preserve days |
| History changes | Delete latest period; edit amount; middle-period gap handled without false active status |
| Reporting | Month/year boundaries; payment month independent of coverage; integer totals; deletes change income/counts |
| Input/state | Blank name; localized digits; double tap creates one record; sheet closes after local application offline |
| Offline | Preload online, airplane-mode reads/add/edit/delete/renew, restart, reconnect and verify eventual server state |
| Failures | Queued write rejected by rules, local rollback/error feedback; cached-empty differs from complete-empty |
| Security | Unauthenticated and another UID denied; own valid create/update/delete allowed |
| Session | Sign out with pending changes; sign in as another user; no previous gym's data rendered |
| Cascade | All member subscriptions removed within supported batch boundary; incomplete dataset never claimed complete |
| UI | Both mobile/tablet layouts; narrow RTL, large text, short landscape, keyboard-visible forms, long Arabic names, mixed phone/date strings |
| Adaptive selector | Widths 599/600/601 choose mobile/tablet/tablet; only the selected builder runs; bounded-width contract is respected |
| Resize continuity | Cross the breakpoint while searching, editing, selecting a member/month/day, and awaiting a write; no state reset, duplicate Cubit/listener, or resubmission |
| Responsive behavior | Widths 320/360/430/600/768/1024/1280; split-screen and rotation; no overflows/clipping; usable text scale and touch targets |

Use pure Dart tests for policies/calculators, Cubit tests with repository fakes for state flows, Firebase Emulator Suite for rules/queued write failures, and an Android integration run for actual persistence behavior. Avoid tests that merely repeat constructor assignments or widget constants.

## 15. Implementation sequence and agent guardrails

1. Bootstrap dependencies, theme tokens, Arabic localization, routing, session scope, shared breakpoints, and the framework-only adaptive layout builder.
2. Implement DateOnly, money conversion, renewal/status policies, and focused boundary tests.
3. Implement typed models, repositories, shared read projection, and auth/bootstrap completeness.
4. Build members, add/edit flows, details, renewal, and meaningful offline-write feedback.
5. Build drop-ins and local monthly reporting.
6. Add edit/delete flows, cascade handling, settings, and sign-out lifecycle.
7. Verify offline persistence, failure rollback, tenant isolation, both responsive layouts, breakpoint transitions, and UI accessibility.

Use Cubit exclusively; do not create Bloc subclasses or event files. Keep exactly two UI layout variants (mobile/tablet), selected through the shared breakpoint policy and responsive through Flutter framework APIs only. Do not substitute a static mock screen for working data flows. Do not silently expand to Clean Architecture with entities/use-cases/data-sources for every CRUD action. Do not add staff roles, charts, notifications, payment gateways, attendance, debt, multiple plans, or another database.

Before considering the app production-ready, reconcile the named PRD ambiguities rather than treating technical recommendations as user-approved scope. Keep the existing product simple while being honest about cached data and synchronization.

## 16. Primary technical references

References 1–5 checked on 26 October 2026; adaptive layout references 6–7 checked on 27 October 2026. These establish platform behavior; project-specific choices above remain this project's decisions.

1. [Bloc architecture — Presentation, Business Logic, Data](https://bloclibrary.dev/architecture/)
2. [Flutter architecture recommendations — supporting general engineering guidance](https://docs.flutter.dev/app-architecture/recommendations)
3. [Firestore offline data and snapshot metadata](https://firebase.google.com/docs/firestore/manage-data/enable-offline)
4. [Firestore transactions and batched writes](https://firebase.google.com/docs/firestore/manage-data/transactions)
5. [Firestore deletion behavior](https://firebase.google.com/docs/firestore/manage-data/delete-data)
6. [Flutter adaptive UI: measuring constraints and choosing layouts](https://docs.flutter.dev/ui/adaptive-responsive/general)
7. [Flutter LayoutBuilder API](https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html)
