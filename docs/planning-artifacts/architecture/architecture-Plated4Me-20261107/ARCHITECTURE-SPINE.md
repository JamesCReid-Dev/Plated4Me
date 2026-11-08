# Architecture Spine: Plated4Me

**Version:** 1.0  
**Date:** November 8, 2026  
**Altitude:** initiative → feature  
**Status:** final

---

## Design Paradigm

**Local-first single-user document store.** The entire app runs on one device with one user. There is no concurrency, no sync, no server. Every decision flows from that simplicity: synchronous lookups are fast enough, error surfaces are narrow, and the data model is owned entirely by the client.

---

## Inherited Invariants

None — greenfield project. No parent spine to inherit from.

---

## Active Decisions

### AD-1: Storage — Isar (Replaces Hive)

| Field | Value |
|-------|-------|
| **Binds** | All persistent data uses Isar. Entity models defined with `@IsarCollection`. References handle Visit↔Restaurant joins. |
| **Prevents** | No Hive adapters, no Hive box registration, no Hive key format conventions. Infrastructure layer stores Isar database access, not Hive boxes. |
| **Rule** | Every entity that needs persistence gets an `@IsarCollection` with auto-incrementing `id`. References use Isar's built-in reference type, not manual foreign keys. |

### AD-2: Navigation — Bottom Nav + Full-Screen Modal

| Field | Value |
|-------|-------|
| **Binds** | Three bottom nav tabs (Browse, Favorites, Settings). Quick Log opens as a full-screen modal route from the Browse screen. Onboarding is a separate pre-nav route. |
| **Prevents** | Quick Log is NOT a bottom nav tab. No nested navigators per tab — each tab is a simple widget tree. |
| **Rule** | Bottom navigation uses `BottomNavigationBar` with `IndexedStack` to preserve tab state. Quick Log modal uses `showModalBottomSheet` or full-screen route via `Navigator.push`. |

### AD-3: State Management — AsyncNotifier + Isar Streams

| Field | Value |
|-------|-------|
| **Binds** | Riverpod `AsyncNotifierProvider` wraps Isar query streams. Providers own all query and mutation logic. UI layer watches providers and reacts. |
| **Prevents** | Direct Isar calls from widgets. No `StatefulWidget`-managed state for data that persists. |
| **Rule** | Each aggregate root (Visits, Restaurants, Favorites) gets its own AsyncNotifier. Stream-based reactivity via `IsarCollection.watchObject()` or `watchFilter()`. |

### AD-4: Composite Score — Pure Function in Domain

| Field | Value |
|-------|-------|
| **Binds** | `computeCompositeScore(Ratings)` is a pure function in `lib/domain/`. Weights are fixed constants: food=0.40, value=0.30, service=0.15, overall=0.15. Called by providers before persisting Visit. Re-derived on any input change. |
| **Prevents** | Score computation inside Isar schema, widget logic, or provider mutation methods. |
| **Rule** | `double computeCompositeScore({required double food, required double value, required double service, required double overall}) => food * 0.40 + value * 0.30 + service * 0.15 + overall * 0.15;` |

### AD-5: Favorites — Computed On-Demand

| Field | Value |
|-------|-------|
| **Binds** | Favorites are derived from Visit history, not stored as a separate entity. Three conditions must all be true: ≥2 Visits, average composite ≥80% of scale max, at least 1 `returnIntent=true`. Manual pin/unpin always respected. |
| **Prevents** | A `Favorite` entity/table. Cached favorite lists that drift from Visit data. |
| **Rule** | `FavoritesNotifier` watches all Visits via Isar stream, computes favorites list reactively. Manual overrides stored as a `Set<int>` of pinned restaurant IDs on UserPreferences. |

### AD-6: Onboarding — Separate Gate Route

| Field | Value |
|-------|-------|
| **Binds** | Onboarding runs once at app start. Checks `UserPreferences` existence in Isar. If absent → navigate to onboarding route. If present → navigate to main app with bottom nav. Skippable. |
| **Prevents** | Onboarding from being part of the bottom nav structure. Multiple onboarding flows. |
| **Rule** | Route path `/onboarding` guarded by a `FutureBuilder` or `ConsumerWidget` that checks preferences. Completing onboarding writes UserPreferences to Isar and navigates to `/`. |

### AD-7: Quick Log — Full-Screen Modal, Single Form

| Field | Value |
|-------|-------|
| **Binds** | Quick Log is a single scrollable form in a full-screen modal. No internal screen breaks. Captures restaurant name, address, 4 ratings, return intent, occasion tags, meal total, optional line items, optional journal entries. Submit persists Visit (and auto-creates Restaurant if needed) then pops modal. |
| **Prevents** | Multi-step wizard, separate screens for each logging phase, or a bottom nav tab placement. |
| **Rule** | Form uses `GlobalKey<FormState>` for validation. ≤30s constraint means no loading states during the core flow — all writes are optimistic with error retry (AD-8). |

### AD-8: Error Handling — 2 Retries → Snack Bar / Dialog

| Field | Value |
|-------|-------|
| **Binds** | Transient failures (disk I/O) get 2 fixed-interval retries (~500ms each). Recoverable failure → snack bar. Unrecoverable failure (db corruption, disk full) → dialog. All failure modes are local — no network fallback. |
| **Prevents** | Infinite retry loops. Silent failures with no user feedback. Network error handling paths. |
| **Rule** | AsyncNotifiers wrap Isar writes in `try/catch` with retry counter. Snack bar via `ScaffoldMessenger.showSnackBar`. Dialog via `showDialog` for unrecoverable errors. |

### AD-9: Search — Isar FTS + Post-Query Re-Ranking

| Field | Value |
|-------|-------|
| **Binds** | Isar full-text search finds matches across Restaurant name, address, journal entries, occasion tags, notes. Post-query Dart re-ranking applies 9-tier priority: exact restaurant name > partial name+address > employee/server > journal dish > voice transcript/journal note > general notes > occasion tag. |
| **Prevents** | In-memory inverted index construction. External search engine dependency. Hive-based text search. |
| **Rule** | Isar FTS indexes configured on searchable fields per entity. Search provider returns ranked results via `List.sort()` with priority comparator after Isar query completes. |

### AD-10: Restaurant Deduplication — Synchronous Lookup

| Field | Value |
|-------|-------|
| **Binds** | During Quick Log, restaurant lookup by `(name, address)` tuple is synchronous (`Isar.where().findAll()`). Multi-match → disambiguation picker. No match → auto-create Restaurant. Single match → use existing. |
| **Prevents** | Async stream-based dedup during typing. Separate "Add Restaurant" screen. |
| **Rule** | Lookup runs on form submit (not on each keystroke). `Isar.collection<Restaurant>().filter().nameEqualTo(name).findAll()` then filter by address match. |

### AD-11: Theme — Light Mode Only (MVP)

| Field | Value |
|-------|-------|
| **Binds** | App uses light theme only for MVP. `AppTheme` defines light colors, typography, and component styles. No dark mode toggle in Settings. |
| **Prevents** | Dark mode code paths, system theme detection, or user theme preference storage. |
| **Rule** | `MaterialApp(theme: AppTheme.light)` with no `darkTheme`. Theme extension point reserved for post-MVP. |

### AD-12: Clean Architecture — Four Layers

| Field | Value |
|-------|-------|
| **Binds** | `lib/domain/` (entities, pure functions, repository interfaces), `lib/application/` (Riverpod providers, business logic), `lib/infrastructure/` (Isar database access, schema), `lib/presentation/` (widgets, navigation, theme). Inner layers never import outer layers. |
| **Prevents** | Widget-to-database direct calls. Domain layer framework dependencies. |
| **Rule** | Barrel exports per layer (`domain.dart`, `application.dart`, `infrastructure.dart`). `package:` imports exclusively. All return types explicit. No `print()` statements. |

### AD-13: Testing — Three-Tier Strategy

| Field | Value |
|-------|-------|
| **Binds** | Domain pure functions → unit tests (no framework). Riverpod AsyncNotifiers → integration tests with in-memory Isar instance (`Isar.open(..., isInMemory: true)`). Widgets → widget tests with `flutter_test`. Mock at layer boundaries. |
| **Prevents** | Integration tests that touch the file system for domain logic. Widget tests that test provider logic. |
| **Rule** | Test files mirror lib structure under `test/`. Composite score, validation rules, and favorites computation tested in isolation. Provider tests use `ProviderContainer` with overridden providers. |

### AD-14: Operational Envelope — Single Device, No Operations

| Field | Value |
|-------|-------|
| **Binds** | One user, one device, no server. No deployment pipeline beyond Flutter app store submission (iOS App Store, Google Play). No environment variables, no feature flags, no A/B testing. Data loss recovery via JSON export (CAP-14) + device backup. |
| **Prevents** | CI/CD pipeline complexity, staging/prod environments, remote config, analytics SDKs, crash reporting services. |
| **Rule** | Build: `flutter build ios` / `flutter build apk`. Deploy: Xcode Organizer / Android Studio bundle. No post-deploy changes — updates ship as full app releases. |

---

## Deferred

| ID | Decision | Revisit Condition |
|----|----------|-------------------|
| DEF-1 | Voice transcription (speech-to-text integration) | Post-MVP — Release 1.5 |
| DEF-2 | Isar schema versioning and migration code | First post-MVP feature that adds/modifies entities |
| DEF-3 | Dark mode theme | Post-MVP |
| DEF-4 | User-configurable rating weights | Post-MVP, if usage data shows demand |
| DEF-5 | Random cuisine suggestion (CAP-15) | Release 1.5 |
| DEF-6 | Discovery map with fog-of-war (CAP-16) | Release 2.0 |
| DEF-7 | Game layer — achievements, stats, quests (CAP-17) | Release 2.5+ |

---

## Entity Model Summary

```
Restaurant ────< Visit
     │              │
     │              ├─ mealTotal: double
     │              ├─ lineItems: List<LineItem>
     │              ├─ journalEntries: List<JournalEntry>
     │              └─ blacklistReason: String?

Allergy (user-scoped, independent collection)
  { foodName, severity }

UserPreferences (singleton, one record)
  { ratingScale, cuisineTypes, occasionTags, pinnedRestaurantIds, onboardingComplete }
```

---

## App Structure

```
main.dart
├── Isar.open() — database initialization
├── ProviderScope — Riverpod setup
└── MaterialApp
    ├── / (onboarding) — guarded by UserPreferences check
    └── /app — main app with BottomNavigationBar
        ├── BrowsePage — visit list + search bar
        ├── FavoritesPage — computed favorites list
        ├── SettingsPage — allergies, preferences, data export
        └── QuickLogModal — full-screen modal route from Browse
```

---

## Non-Functional Constraints (From Spec)

| Constraint | Architectural Impact |
|------------|---------------------|
| ≤30s logging time (CAP-4) | Single-form Quick Log, synchronous lookups, optimistic writes |
| Single-user only (C2) | No concurrency handling, no auth, no data partitioning |
| Fully offline (C5) | No network layer, no API clients, no cloud sync |
| Mobile only (C1) | No web/desktop responsive layouts, touch-optimized widgets |
