# AGENTS.md — Gymk (جيمك)

## Project and scope

Build an Android Flutter app for a small gym owners to manage members, monthly subscriptions, individual drop-in sessions, and monthly cash collected. The interface is Egyptian Arabic and RTL. Each authenticated owner has one independent gym, primarily used from one phone.

Use the existing project, documents, skills, logo, icon, and loading animation. Inspect what is present before making changes. Do not recreate the project, overwrite configuration, or assume asset paths.

## Start every task with the relevant context

1. Read this file and any applicable nested AGENTS.md instructions.
2. Read `docs/ARCHITECTURE.md`, `docs/PRD.md`, and `docs/DESIGN_STYLE.md`. If filenames differ, locate the corresponding documents by title/content. Do not silently choose an obsolete duplicate or invent a missing document.
3. Read `docs/TASKS.md` when it exists, especially the current task, dependencies, and open decisions.
4. Discover the project's available skills, including `.agents/skills/` or another configured location. Read the relevant SKILL.md before using its workflow.
5. Inspect the affected code, dependency versions, existing repository contracts, and assets. Follow established conventions when they remain consistent with the confirmed decisions below.

The latest explicit user instruction takes precedence over project documents and skill suggestions. The PRD owns product scope; ARCHITECTURE owns technical structure; DESIGN_STYLE owns visual details; TASKS tracks implementation progress. This file summarizes confirmed cross-cutting decisions, not a replacement for those documents.

If a skill or an older document recommends Bloc subclasses, MVVM, mandatory use cases, a second local database, or responsive packages, follow the confirmed project decisions below instead. Report meaningful conflicts. Isolate genuine unresolved business decisions and continue independent work rather than silently inventing policy or blocking everything.

## Architecture: BLoC presentation pattern, Cubit exclusively

- Keep three layers: **Presentation → Business Logic → Data (Repository → Data Provider)**.
- Use **Cubit for every feature**, including authentication, live lists, statistics, and forms. Do not create Bloc subclasses, event classes, or event files.
- Keep Cubits in `lib/features/{feature}/business_logic/cubit/` and pure rules/calculators in `business_logic/policies/`.
- Keep views, mobile/tablet layouts, and reusable feature widgets in `presentation/views/`, `presentation/layouts/`, and `presentation/widgets/`.
- Keep models, repositories, and Firebase-facing providers in the feature's `data/` folders.
- Let views invoke Cubit methods. Let Cubits consume typed repositories and pure policies. Let data providers own Firebase SDK interaction and serialization.
- Inject dependencies with constructors. Resolve GetIt at composition boundaries; keep setup in `lib/app/di.dart` or the existing equivalent.
- Do not introduce ViewModel wrappers, a mandatory use-case layer, generic CRUD frameworks, or duplicate models without a concrete need.
- Do not inject or subscribe directly to another Cubit. Share repository streams; use presentation-level coordination only for real UI effects.
- Keep business rules, Firestore APIs, and monetary totals out of widget build methods.

`BlocProvider`, `BlocBuilder`, `BlocSelector`, and `BlocListener` from flutter_bloc are valid with Cubit. The prohibition concerns Bloc subclasses and event-based feature implementations, not these widgets or the package name.

## State and lifetime

- Use immutable state and intention-revealing Cubit methods. Prefer independent fields for read phase, existing data, search/filter/form values, submission state, and typed failure.
- Keep usable cached data visible during refresh and mutations. Do not force every feature into a sealed Initial/Loading/Loaded/Error union that discards existing data.
- Use sealed types where they express genuinely exclusive alternatives. Do not add Freezed/build_runner merely to scaffold a small feature; inspect existing project choices first.
- Ensure nullable state fields can be explicitly cleared by copyWith.
- Handle stream errors, cancel owned subscriptions/timers in close, and prevent emissions after disposal.
- Prevent double submission immediately. Serialize conflicting mutations for the same member and use stable IDs for create/retry intents.
- Use route/form Cubit factories. Keep tenant repositories and shared read projections scoped to a captured UID.
- On account changes dispose tenant listeners/state and prevent the previous gym's data from appearing in the next session.
- Keep navigation, dialogs, localized copy, and UI controllers in Presentation. Avoid repeating one-time effects on unrelated state emissions.

## Mobile/tablet adaptability and responsiveness

- Provide **two UI layout variants: mobile and tablet**, both inside Presentation. Share the same business rules, Cubit instances, repositories, and reusable components.
- Use the shared custom `AppAdaptiveLayout`, backed by Flutter `LayoutBuilder`, with centralized `AppBreakpoints` in `lib/core/ui/adaptive/` or the existing equivalent.
- Initial breakpoint: **available width <600 logical pixels → mobile; >=600 → tablet**. Keep the threshold in one named constant. Do not scatter independent device checks across features.
- Select the application mode from bounded available screen/shell width, not device model, physical pixels, or orientation alone. A narrow tablet window may use the mobile layout.
- Keep shell navigation and screen composition consistent with the selected mode. Do not reclassify a narrow pane inside a tablet layout as a separate device mode.
- Build only the selected layout subtree. Keep the state-owning Cubit/provider and shared form host above replaceable layout branches.
- Make each layout responsive using **Flutter framework APIs only**: constraints, Flex/Expanded/Flexible, Wrap, constrained widths, grids/slivers, scrolling, SafeArea, and relevant MediaQuery aspects.
- Do not add flutter_screenutil, responsive_framework, responsive_builder, sizer, adaptive-scaffold packages, or similar layout dependencies.
- Do not globally scale all dimensions or fonts from a reference screen size. Preserve readable text, touch targets, and system text scaling.
- Preserve selected destination/member, query, filters, selected month/day, form values, and pending writes when resizing or rotating. Never recreate Cubits, restart listeners, or submit writes because a layout builder runs.
- Handle narrow widths, short landscape windows, split-screen, keyboard insets, RTL, long names, and mixed-direction phone/date strings in both variants.

## Firebase and offline behavior

- Use Firebase Auth with Google sign-in and Firestore under `users/{uid}`. Keep account data isolated in both paths and Security Rules.
- Use **Firestore persistence as the only durable application-data store**. Do not add Hive, Drift, SQLite, or a custom persistent sync queue.
- Reuse session-level repository streams/projections rather than adding per-row queries or duplicate listeners.
- Distinguish local application, pending cloud acknowledgement, acknowledged writes, and rejection/rollback. Handle eventual write failures even after a form closes.
- Do not block normal offline forms indefinitely on cloud acknowledgement. Do not claim cloud success when only a local change is known.
- Cached data may be incomplete. An empty unverified cache is not proof of an empty gym or a zero-income month. Unlimited cache does not download the account automatically.
- Keep snapshot/cache metadata behind typed repository contracts. Cache origin alone is not a connectivity check.
- Preserve the documented single-device tradeoff. Last-write-wins does not prevent duplicate records or guarantee multi-device cascade integrity.

## Product invariants

- One subscription type: one **calendar month**, not a fixed 30-day duration and not alignment to the first of the month.
- Early renewal extends the current overall expiry by one month, preserving all remaining days. For an expired or first subscription, default the start to today.
- Clamp month arithmetic to the target month's last day. Use shared pure date/coverage policies; expiry is exclusive.
- Example: 26 October → 26 November; renewal on 10 November → new expiry 26 December. The payment counts in November.
- Derive member status from remaining subscription coverage, not a manually stored status or only the newest record's start date. Recompute date-sensitive state on resume/date rollover.
- Calculate monthly cash collected by payment/session date, independently of coverage periods. Store/sum integer minor units; formatting belongs at presentation boundaries.
- Support ordinary editing and **permanent deletion**. Do not add archiving, soft deletion, voidedAt, cancellation workflows, or a fake undo.
- Deleting a member must explicitly remove their subscription records. Respect the documented data-completeness and write-batch boundaries; do not silently claim an incomplete cascade succeeded.
- Deleting/editing records changes the corresponding status and historical totals. Do not silently shift other historical coverage dates.
- Keep currency, exact payment-date encoding, future-only/gapped coverage behavior, and other unresolved decisions visible until resolved in the project documents. Do not present suggested defaults as approved requirements.
- Do not expand the MVP with staff roles, attendance, debt/installments, multiple plans, notifications, charts, payment gateways, or another backend without a user request.

## Design and existing assets

- Follow DESIGN_STYLE: a clean management UI with restrained yellow-and-black neo-brutalist accents. Keep repeated lists calm and readable.
- Reuse theme tokens and shared components. Use clear Arabic labels and status text alongside color. Preserve RTL and bidi correctness.
- Use the supplied logo, square icon, and loading Lottie. Inspect actual files and paths; do not replace or regenerate approved artwork unnecessarily.
- Use the logo Lottie for suitable screen-level loading states. Do not cover readable cached data with a full-screen loader or put the full logo animation inside every small button.
- Configure the Android app icon with **flutter_launcher_icons as a dev_dependency**, using the existing square icon and a compatible package version. Use the actual asset path and a reproducible root config.
- Generate with `flutter pub get` and `dart run flutter_launcher_icons` when the toolchain is available. Verify Android resource/manifest references.
- Configure adaptive icon layers only when suitable foreground/background assets exist. Do not treat an opaque square image as a transparent foreground, crop Arabic letters, or invent missing assets.
- Keep icon generation Android-only unless scope changes. The ban on responsive packages does not prohibit flutter_launcher_icons or existing non-layout dependencies.

## Planning and TASKS.md

When asked to plan implementation, create or update `docs/TASKS.md` after inspecting actual progress. Do not start implementing features during a planning-only request.

Organize ordered phases with small independently verifiable tasks. Each task needs a stable ID, checkbox, outcome/scope, dependency IDs, affected components, acceptance criteria, and relevant verification. Record unresolved decisions explicitly.

Include mobile/tablet composition, responsive behavior, state continuity, RTL, and applicable loading/empty/incomplete/error/pending states in each feature's acceptance criteria; do not defer all tablet work to the end.

During implementation, work on the next authorized unblocked task, update the checklist after verification, and keep it consistent with the actual code. Never mark a task complete just because files exist, code was written, or checks were assumed to pass. Preserve previous progress; do not regenerate the checklist destructively each session.

## Verification and delivery

- Run project-appropriate formatting, static analysis, and focused tests when the toolchain is available. Inspect existing conventions before selecting commands or package versions.
- Prioritize meaningful cases: month boundaries/leap years, early renewal, expiry thresholds, edits/deletes, integer totals, duplicate submission, offline persistence, rejected writes, tenant isolation, and stream cleanup.
- For UI changes, verify breakpoint boundaries (599/600/601), representative phone/tablet widths, text scaling, keyboard-open forms, RTL, and state preservation during resize. Do not claim runtime checks based only on reading source.
- Use repository fakes for Cubit tests and Firebase emulators/device integration where needed. Avoid tests that only restate constructors/constants.
- If a command, SDK, Firebase setup, or device is unavailable, report the exact limitation and continue independent work. Do not claim checks passed or invent configuration/secrets.
- Preserve unrelated user changes. Avoid new dependencies and architectural layers without a concrete task requirement.
- Finish with a concise report of what changed, what was verified, and any remaining blockers or decisions. Distinguish implemented behavior from proposed work.
