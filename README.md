# plated4me

A privacy-first dining journal for allergy-aware foodies. Log visits, rate experiences, and discover your favorite restaurants — all offline.

## Architecture

This project follows **Clean Architecture** with four layers:

```
presentation/    ← UI, widgets, navigation, theme
application/     ← Business logic, Riverpod providers
domain/          ← Entities, value objects, repository interfaces
infrastructure/  ← Isar storage implementation
```

Inner layers never depend on outer layers. See [`CLAUDE.md`](CLAUDE.md) for full conventions.

## Getting Started

### Prerequisites

- **Flutter >= 3.16.0** (Dart SDK >= 3.2.0 < 4.0.0)
- Check your version: `flutter --version`

### Setup

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate code (Isar entities, Freezed classes, JSON serializers)
dart run build_runner build --delete-conflicting-outputs

# 3. Run the app
flutter run
```

### Code Generation

After modifying any annotated class (Freezed, Isar, JSON serializable), re-run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files have `.g.dart`, `.freezed.dart` extensions and are tracked in git. **Never edit them manually.**

## Analysis & Linting

```bash
# Run static analysis (must pass with zero issues)
flutter analyze

# Format code
dart format .
```

The project enforces strict lint rules via `analysis_options.yaml`:
- No relative imports inside `lib/` — use `package:` imports
- All return types must be declared explicitly
- No `print()` statements

## Testing

```bash
# Run all tests
flutter test

# Run with verbose output
flutter test --reporter=expanded
```

## Pre-commit Hooks

A pre-commit hook is provided to run `flutter analyze` before each commit:

```bash
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

The hook blocks commits if `flutter analyze` reports any issues.

## Tech Stack

| Category | Technology |
|----------|-----------|
| State Management | Riverpod (`flutter_riverpod`) |
| Immutability | Freezed |
| Serialization | JSON Serializable |
| Local Storage | Isar (primary), Hive (key-value fallback) |
| Linting | `flutter_lints` with project-specific rules |

## Learn More

- [Flutter Documentation](https://docs.flutter.dev)
- [Riverpod Documentation](https://riverpod.dev)
- [Isar Documentation](https://isar.dev)
