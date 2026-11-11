---
title: "S06 — Allergy-Safe Database"
created: 2026-11-08
updated: 2026-11-08
status: draft
epic: "Epic 2: Core Visit Logging"
jira_key: ST-006          # pending Jira creation
priority: P1
story_points: 3
realizes: FR-5
parent_prd_shard: prd-allergy.md
---

# S06 — Allergy-Safe Database

**As a** user, **I want** to maintain a per-Restaurant list of foods confirmed safe for my allergies, **so that** I can quickly check which dishes are reliable when planning a return visit.

---

## References

| Artifact | Location |
|----------|----------|
| PRD Shard | [`_bmad_output/prd-shards/prd-allergy.md`](../../prd-shards/prd-allergy.md) — FR-5 |
| Epic Breakdown | [`docs/planning-artifacts/epics.md`](../../docs/planning-artifacts/epics.md) — S08 AC-4, S12 AC-2 |
| Data Model | [`_bmad_output/prd-shards/prd-data-model.md`](../../prd-shards/prd-data-model.md) — `AllergySafeFood` entity |
| UX Design | DESIGN.md + EXPERIENCE.md — Accordion pattern (UX-DR8), State Patterns |

---

## Scope Clarification

This story covers the **per-Restaurant allergy-safe foods list** only. The user's personal allergen definitions (with severity levels) are covered in **S05: Settings & Preferences** (AC-1). Severity context lives in Settings; this feature stores only food names linked to a Restaurant.

---

## Acceptance Criteria

### AC-1: Add Safe Foods During Visit Logging (Must Have)

- [ ] Within the "Optional Sections Accordion" during visit logging, an "Allergy-Safe Foods" section is available
- [ ] Section is independently expandable/collapsible (accordion pattern — UX-DR8)
- [ ] User can add a food name via free-text input + "Add" button
- [ ] Added foods appear as chips within the accordion section
- [ ] Each chip shows the food name and has a remove (×) action
- [ ] Adding a safe food creates an `AllergySafeFood` entity linked to the Restaurant being logged
- [ ] User can save the visit without filling any allergy-safe foods — never blocks save (NFR-5)

### AC-2: Remove Safe Foods During Visit Logging (Must Have)

- [ ] Each added safe food chip has a remove action (× icon or swipe)
- [ ] Tapping remove shows a confirmation dialog: "Remove [food] from the allergy-safe list for [Restaurant]?"
- [ ] On confirm, the `AllergySafeFood` entity is deleted from Isar

### AC-3: Safe Foods Indicator in Restaurant Detail (Must Have)

- [ ] Restaurant detail view shows an "Allergy-Safe Foods" section
- [ ] Section header displays a count badge: e.g., "Allergy-Safe Foods (3)" or "No allergy-safe foods yet"
- [ ] Tapping the section expands to show the full list of confirmed safe foods
- [ ] Each food name is displayed as a plain text line item with the date it was confirmed (e.g., "Margherita Pizza — confirmed Nov 5, 2026")
- [ ] If no safe foods exist, shows: "No allergy-safe foods configured. Add one when logging a visit."

### AC-4: Safe Foods Persist Across Visits to Same Restaurant (Must Have)

- [ ] Adding a safe food during Visit A is visible during Visit B at the same Restaurant
- [ ] Safe foods are linked to `restaurantId`, not to individual `Visit` entities
- [ ] Deleting a safe food removes it for all future views of that Restaurant

### AC-5: Voice and Tone Compliance (Must Have)

- [ ] All UI text follows UX-DR2 voice & tone rules:
  - Short, complete sentences only
  - No exclamation marks
  - No encouragement/gamification language ("Your food is now safe!" — forbidden)
  - State indicators are text-only

---

## Technical Notes

### Data Model Impact

- **Entity:** `AllergySafeFood` (Isar sub-collection linked to Restaurant)
  - `id`: auto-generated UUID
  - `restaurantId`: UUID → Restaurant
  - `foodName`: string
  - `confirmedAt`: datetime (timestamp of creation)
  - `notes`: string? (optional — e.g., "confirmed safe — no reaction")

### Repository Impact

- **`AllergySafeFoodRepository`** interface:
  - `List<AllergySafeFood> getByRestaurantId(String restaurantId)`
  - `Future<void> add(AllergySafeFood food)`
  - `Future<void> delete(String id)`
  - `int countByRestaurantId(String restaurantId)` — for the count badge in Restaurant detail

### UI Component Requirements

- Accordion section within visit logging form (S08 context)
- Chip-based input component for adding/removing foods
- Expandable/collapsible list view in Restaurant detail
- Date formatting: relative ("Nov 5, 2026") — consistent with other date displays in the app

### Relationship to UserAllergen (S05)

- `UserAllergen` (Settings): personal allergens with severity → defines **what** to watch for
- `AllergySafeFood` (per-Restaurant): confirmed safe foods → records **which foods are safe** at this location
- The two entities are independent — no automatic matching or cross-referencing in MVP. The user manually adds safe foods based on their experience.

---

## Dependencies

| Dependency | Story | Status |
|------------|-------|--------|
| Isar Schema & Entity Models | S01 | Must be complete (AllergySafeFood entity defined) |
| Data Layer — Repository Implementation | S02 | Must be complete (repository interfaces) |
| Navigation Shell (Bottom Nav + IndexedStack) | S03 | Must be complete |
| Optional Sections Accordion | S08 | **Co-developed** — this story owns the allergy-safe accordion section; S08 owns the accordion framework |

---

## Testing Notes

- **Unit tests:** `AllergySafeFood` entity serialization/deserialization
- **Widget tests:** Accordion section in logging form — add/remove chips, confirmation dialogs
- **Widget tests:** Restaurant detail view — count badge displays correctly, expand/collapse works
- **Integration test:** Add safe food during Visit A → navigate to same Restaurant → open Visit B → safe food visible
- **Integration test:** Delete safe food → not visible in any future views of that Restaurant

---

## Open Questions

1. Should the safe foods list suggest foods from the user's personal allergen list? (e.g., "You're allergic to peanuts — confirm they're safe here?" ) Not in MVP scope per PRD notes, but could be a post-MVP enhancement.
2. Should `notes` on `AllergySafeFood` be editable after creation? Currently only addable at creation time. If needed, an edit action would require a small form component.
