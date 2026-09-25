# noo — Flutter client

The application itself. Everything Noo is lives here; the repository root holds
the build scripts and the documentation. Start at [../README.md](../README.md),
and see [../AGENTS.md](../AGENTS.md) for the architecture and the full
development guide.

## Working on it

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift + Riverpod codegen
flutter run -d linux
flutter test
```

Re-run the code generation after changing the database schema or an annotated
provider; `build_runner watch` does it continuously.

## Layout

```
lib/
├── core/          # constants, theming, errors, utilities
├── domain/        # entities and repository interfaces (pure Dart)
├── data/          # Drift database, repositories, sync and audio services
├── presentation/  # screens, widgets, Riverpod providers
└── platform/      # OS integration (launcher registration, Linux specifics)
```

Tests mirror `lib/` under `test/`. A few of them need a real native audio
library and skip themselves without one — they say so when they skip.
