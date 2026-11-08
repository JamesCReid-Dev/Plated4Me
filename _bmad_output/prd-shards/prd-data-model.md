---
title: PRD — Data Model
created: 2026-11-08
updated: 2026-11-08
status: final — post-review decisions applied (C1–S4 resolved)
parent: prd-index.md
---

# PRD: Data Model Overview

*§13 from main PRD*

High-level entities for the local data store. Implementation details (Hive boxes, field types) are resolved in architecture.

**Key design decisions:** (1) UUID primary keys for offline-first independence, (2) all location fields optional to support name-only logging, (3) `compositeScore` calculated at write time and re-derived if any input rating changes — not stored as an independent source of truth.

---

## Entities

### Restaurant

```
Restaurant
├── id: UUID (primary key)
├── name: string
├── address: string? (optional — but required if another Restaurant shares the same name; simplified from granular street/city/state/country/postalCode per S2 resolution; post-MVP may expand to structured fields for GPS integration)
├── cuisineType: string (e.g., "Italian", "Japanese")
│   └── Note: Free-text with suggested presets (~20 common types); user can add custom cuisines. Stored lowercase internally, displayed with title case. Case-insensitive comparison for filtering and search.
├── occasionTags: string[] (e.g., ["date night", "quick lunch"]) — **default suggestions** applied when logging a new Visit at this Restaurant; the user can accept, modify, or override these defaults per-visit. Per-Visit occasion tagging (FR-8) remains independent; defaults are merely suggestions, not constraints.
├── favorite: boolean (derived state — auto-detected from Visit aggregates per FR-7, with manual pin/unpin override; recomputed when associated Visits change)
├── generalNotes: string? (persistent free-text notes about the restaurant spanning all visits; included in full-text search per FR-17)
├── createdAt: datetime
└── updatedAt: datetime
```

### Visit

```
Visit
├── id: UUID (primary key)
├── restaurantId: UUID (foreign key → Restaurant)
├── date: datetime
├── foodQualityRating: number (slider, user's chosen scale — 1–5 or 1–10)
├── valueForMoneyRating: number (slider)
├── serviceQualityRating: number (slider — new per C3/OQ-10 resolution; captures staff attentiveness, order accuracy, etc.)
├── overallExperienceRating: number (slider)
├── compositeScore: number (calculated: 40/30/15/15 weighted average of four ratings)
├── returnIntent: boolean
├── mealTotal: number? (manually entered total for meals; optional, not auto-calculated from line items per C2 resolution)
├── tipPercentage: number? (tip % given during this visit; optional)
├── employeeName: string? (server/employee name; optional)
├── employeeNote: string? (free-text note about the employee's service; optional)
├── isBlacklisted: boolean? (per-Visit blacklist flag per S4 resolution; blacklisting a visit does not blacklist the Restaurant)
├── blacklistReason: string? (reason for blacklisting this visit; free text with suggested categories)
├── blacklistedAt: datetime? (timestamp when visit was blacklisted)
├── voiceNotePath: string? (file path to audio file; optional)
├── voiceTranscript: string? (transcribed text for search; optional)
├── photoPaths: string[]? (optional)
└── notes: string? (free-text visit notes; optional)
    └── Note: Cuisine type is stored on Restaurant, not Visit. Per-visit cuisine excluded from MVP — a restaurant's cuisine rarely changes, and adding it would increase logging form complexity.
```

### VisitItem (line items within a Visit)

```
VisitItem
├── id: UUID (primary key)
├── visitId: UUID (foreign key → Visit)
├── name: string (e.g., "Margherita Pizza")
├── cost: number? (optional — only entered for items the user wants to track cost-wise; line items without a price serve as dish memory, not cost accounting. mealTotal is manually entered, not auto-calculated from line items.)
└── notes: string? (optional, e.g., "amazing crust")
```

### JournalEntry (per dish within a Visit)

```
JournalEntry
├── id: UUID (primary key)
├── visitId: UUID (foreign key → Visit)
├── dishName: string
└── impressions: string (e.g., "great at first, soggy by bite 5")
    └── Note: Per-dish rating removed from v1 data model (M4 resolution) — deferred to post-MVP. Including an optional field now would risk accidental implementation; omit entirely.
```

### AllergySafeFood

```
AllergySafeFood
├── id: UUID (primary key)
├── restaurantId: UUID (foreign key → Restaurant)
├── foodName: string
├── confirmedAt: datetime
└── notes: string? (optional, e.g., "confirmed safe — no reaction")
```

### UserAllergen (personal allergens from Settings)

```
UserAllergen
├── id: UUID (primary key)
├── allergenName: string (e.g., "peanuts", "shellfish")
├── severity: enum[MILD, MODERATE, SEVERE]
└── active: boolean
```

### UserPreferences

```
UserPreferences
├── ratingScale: enum[FIVE_STAR, TEN_STAR]
├── preferredCuisines: string[]
├── defaultOccasionTags: string[]
├── mapDistanceThreshold: number? (meters; deferred to post-MVP Release 2.0 — field exists in schema but unused in v1)
└── gameLayerEnabled: boolean? (opt-in, default false; deferred to post-MVP Release 2.5+ — field exists in schema but unused in v1)
```

---

## Relationships

- **Restaurant** 1→* **Visit** — A Restaurant can have many Visits. Restaurant identity is the `(name, address)` tuple (see OQ-6, S2 resolved). Two entries with the same name but different addresses are distinct Restaurants.
- **Visit** 1→* **VisitItem** — A Visit has multiple line items.
- **Visit** 1→* **JournalEntry** — A Visit has multiple journal entries.
- **Restaurant** 1→* **AllergySafeFood** — A Restaurant has one safe foods list.
- **Visit** → blacklist state — `isBlacklisted`, `blacklistReason`, and `blacklistedAt` live on Visit (S4 resolved), not Restaurant. Blacklisting a Visit excludes it from favorites auto-detection but does not affect the parent Restaurant's visibility or browseability.

---

*See [PRD Index](prd-index.md) for the full PRD.*
