# Gymk — جيمك

Android Flutter app for a small gym owner, with an Egyptian Arabic RTL interface.
See [docs/PRD.md](docs/PRD.md), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), and
[docs/TASKS.md](docs/TASKS.md) for product rules, structure, open decisions and progress.

## Current state

Phase 1 provides locally bundled Cairo and brand assets, theme/components,
four-route navigation, mobile/tablet compositions, shared form hosts and Android
launcher branding. Destinations explicitly show that their features are being
prepared. Authentication, Firebase initialization, repositories, gym records,
monetary input and reports belong to later phases. Existing Firebase configuration
is preserved.

## Local setup and verification

Verified toolchain: Flutter 3.47.1 stable / Dart 3.13.1 with the existing Android SDK
and Gradle configuration.

```powershell
flutter pub get
flutter run
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
```

Arabic localization is generated from `lib/l10n/app_ar.arb`. Cairo 400/600/700 and
its SIL license are bundled in `assets/fonts/`; that folder's README records the
source. Normal rendering requires no font/image download.

The debug-only component/form preview performs no gym data writes:

```powershell
flutter run --route=/foundation
```

The shell selects mobile below 600 logical pixels and tablet at/above 600 from
bounded available width. Both modes share route history; open forms retain their
body/controllers when the composition changes.

## Android icon and build

`flutter_launcher_icons.yaml` generates Android mipmaps from the supplied opaque
square `assets/images/logo.png`, without adaptive layers or other platforms.

```powershell
flutter pub get
dart run flutter_launcher_icons
flutter build apk --debug --no-pub
```

On this Windows machine, Kotlin incremental compilation failed with the package
cache on C: and workspace on E:. This per-command workaround avoids changing
project Gradle versions or global configuration:

```powershell
flutter build apk --debug --no-pub --android-project-arg=kotlin.incremental=false --android-project-arg=kotlin.compiler.execution.strategy=in-process --no-android-gradle-daemon
```

The app retains `com.example.gymk_app` and template debug signing. Production
identity/signing and live Google/Firebase setup remain unverified; a Phase 1 debug
build is not a production release.
