---
name: flutter-ui-cleanup
description: Keep Flutter UI modular and performant by extracting bloated, deeply nested widgets into focused components. Use when writing or refactoring any widget/screen file, when a build() method is getting long or deeply nested, when a widget is duplicated across screens, or on phrases like "clean up this widget", "this widget is too big", "split this widget", "refactor this screen". Also use before finishing a UI change to check for unnecessary rebuilds.
allowed-tools: Read Write Edit Glob Grep
---

# Scalable & Clean Flutter UI Organization

Maintain modular, performant Flutter UI code by splitting complex, deeply nested widgets into
well-organized, focused components. This keeps separation of concerns intact, enables reuse, and
prevents UI file bloat.

## Core Guidelines

### 1. Complexity & Nesting Limits

- **Avoid deep nesting:** a widget should generally not exceed 4–5 levels of nesting. Beyond that,
  extract a section.
- **Length is a signal, not a rule:** extract a widget when it handles a distinct visual section or
  grows past roughly 150 lines (excluding boilerplate, styling, and constructor params). There is no
  hard line-count threshold — never split a widget purely to hit a number.

### 2. Separation & Locality Strategy

Every extracted widget gets its own file — never declare a sub-widget as a private class inside the
parent's file. Place that file at the narrowest scope that satisfies its usage.

**First, detect the project's architecture** (check `AGENTS.md` or the existing folder structure):

- **Clean Architecture** (has a `presentation/` layer separating UI from domain/data): widgets go in
  `lib/features/{feature_name}/presentation/ui/widgets/`.
- **Bloc presentation pattern** (no separate `presentation/` layer, UI sits directly under the feature):
  widgets go in `lib/features/{feature_name}/ui/widgets/`.

Then apply:

- **Single-use sub-widget:** if the widget is only used inside one parent, give it a public
  `StatelessWidget` (e.g. `HeaderSection`, no `_` prefix) in its own file inside that feature's
  `widgets/` folder (per the path above). Import it into the parent file.
- **Feature-shared widget:** if it is used by multiple screens inside the _same_ feature, it goes in
  that same feature's `widgets/` folder (not scoped to one screen).
- **Layout variants:** if the widget is a screen scaffold variant (mobile/tablet/desktop), it belongs in
  a `layouts/` folder alongside that feature's `widgets/` folder (`presentation/ui/layouts/` for Clean
  Architecture, `ui/layouts/` for Bloc presentation pattern).
- **Global core widget:** if it is used across 2 or more distinct features, move its file to
  `lib/core/widgets/` (or a themed subfolder such as `lib/core/widgets/table/`) — same for both
  architectures.
- Per `AGENTS.md`, anything reused in 2+ places belongs in `core/` — check there before creating a new
  shared widget.
- One widget class per file; the file name is the `snake_case` of the class name.

### 3. Atomic Widgets Exemption

Core/atomic widgets (highly customized text fields, buttons, dropdowns) legitimately need extensive
constructor params. They are exempt from length concerns as long as the size comes from
configuration/boilerplate rather than deeply nested UI logic.

### 4. "Dumb" UI Components

- Extracted sub-widgets must be dumb: unaware of global state and business logic.
- Pass data down through constructor parameters.
- Bubble interactions up through callbacks (`VoidCallback`, `ValueChanged<T>`).
- No business logic in the UI layer (`AGENTS.md`: ui → logic → data). State observation only, via
  `BlocBuilder`/`BlocSelector` scoped to the smallest widget that needs it — never at the top of the tree.

### 5. Styling & Safety (per `AGENTS.md`)

- Never hard-code `TextStyle` or colors — use `AppStyles` and `AppColors`. Note that every `AppStyles`
  accessor takes a `BuildContext` (e.g. `AppStyles.style14B(context)`); only add a new style there if it
  will be used more than once.
- Prefer `const` constructors for extracted widgets.
- Never create `TextEditingController`, `AnimationController`, or `FocusNode` inside `build()`; create them
  in `State` and dispose them in `dispose()`.
- No hard-coded route names or DB keys — use `AppRoutes` / `DBKeys`.

---

## Refactoring Example

### ❌ Before (Deeply Nested & Mixed Responsibilities)

```dart
class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Deeply nested header UI
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [ ... ],
            ),
          ),
          // Complex Action Buttons
          Expanded(
            child: ListView( ... ),
          ),
        ],
      ),
    );
  }
}
```

### ✅ After (Clean, Separate Files, Callback-Driven)

```dart
// lib/features/profile/ui/profile_screen.dart
// (Clean Architecture: lib/features/profile/presentation/ui/profile_screen.dart)
import 'package:my_app/features/profile/ui/widgets/profile_header.dart';
import 'package:my_app/features/profile/ui/widgets/action_list.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ProfileHeader(
            userName: 'User',
            onEditTapped: () => _handleEdit(context),
          ),
          const Expanded(
            child: ActionList(),
          ),
        ],
      ),
    );
  }

  void _handleEdit(BuildContext context) {
    // Logic handled here or delegated to the State Manager (Cubit/BLoC)
  }
}
```

```dart
// lib/features/profile/ui/widgets/profile_header.dart
class ProfileHeader extends StatelessWidget {
  final String userName;
  final VoidCallback onEditTapped;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.onEditTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(userName, style: AppStyles.style14B(context)),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEditTapped,
          ),
        ],
      ),
    );
  }
}
```

```dart
// lib/features/profile/ui/widgets/action_list.dart
class ActionList extends StatelessWidget {
  const ActionList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      // List implementation
    );
  }
}
```

## Actionable Instructions

When writing or refactoring Flutter UI code, you MUST:

1. Scan for nesting deeper than 4 levels or bloated `build()` methods.
2. Extract distinct UI sections into their own public `StatelessWidget` classes, each in its own file
   (no `_` prefix, no private classes) at the narrowest scope per the Separation & Locality Strategy.
3. Import each extracted widget back into the parent file.
4. Add `const` constructors (with `super.key`) to extracted widgets.
5. Keep extracted widgets decoupled: parameters in, callbacks out, no direct state-management access.
6. Only promote a widget's file to `lib/core/widgets/` when it is genuinely used across multiple
   separate feature domains.
7. Apply `AppStyles` / `AppColors` — never hard-coded text styles or colors.