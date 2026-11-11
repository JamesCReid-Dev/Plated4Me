---
title: "S13 — Favorites Collection"
created: 2026-11-08
updated: 2026-11-08
status: draft
epic: "Epic 4: Favorites & Organization"
jira_key: ST-013          # pending Jira creation
priority: P0
story_points: 5
realizes: FR-7
parent_prd_shard: prd-favorites.md
---

# S13 — Favorites Collection

**As a** user, **I want** to have an auto-surfaced favorites list of restaurants I love and plan to return to, **so that** I can quickly find my best spots without scrolling through all visits.

---

## References

| Artifact | Location |
|----------|----------|
| PRD Shard | [`_bmad_output/prd-shards/prd-favorites.md`](../../prd-shards/prd-favorites.md) — FR-7 |
| Epic Breakdown | [`docs/planning-artifacts/epics.md`](../../docs/planning-artifacts/epics.md) — S13 |
| Data Model | [`_bmad_output/prd-shards/prd-data-model.md`](../../prd-shards/prd-data-model.md) — `Restaurant.favorite` field |

---

## Acceptance Criteria

### AC-1: Auto-Detection Rule (Must Have)

- [ ] A Restaurant is automatically added to Favorites when **all three** conditions are met across its Visit history:
  - At least **2 Visits** logged for this Restaurant, AND
  - Average composite score ≥ **80% of the chosen scale maximum** (≥4.0 on 5-star, or ≥8.0 on 10-star), AND
  - `returnIntent = true` on at least **1 of those Visits**
- [ ] Auto-detection runs whenever a new Visit is saved or an existing Visit's ratings are updated

### AC-2: Favorites Tab in Bottom Navigation (Must Have)

- [ ] Favorites tab appears as the second item in bottom navigation bar (after Home/Browse, before Settings)
- [ ] Tab icon: filled star when active, outlined star when inactive
- [ ] Favorites list displays restaurants using VisitCard component from S10 with additional favorite indicator
- [ ] List sorted by average composite score descending (highest rated first)

### AC-3: Manual Pin/Unpin Override (Must Have)

- [ ] User can pin any Restaurant as a favorite from Restaurant detail view or list card
- [ ] User can unpin any Restaurant from favorites at any time
- [ ] Manual pins **always take precedence** over auto-detection — a manually pinned restaurant stays in favorites even if it no longer meets the criteria

### AC-4: Favorites Grouped by Cuisine Type (Must Have)

- [ ] Favorite restaurants are grouped by cuisine type for easy browsing
- [ ] Each group header shows cuisine name + count (e.g., "Italian (3)")
- [ ] Groups sorted alphabetically by cuisine name
- [ ] If a restaurant has no cuisine type set, it appears under an "Uncategorized" group

### AC-5: Blacklisted Visits Excluded from Favorites (Must Have)

- [ ] Visits with `isBlacklisted = true` are excluded from favorites auto-detection computation
- [ ] A visit that would otherwise qualify as a favorite is **not** added to favorites if it is blacklisted
- [ ] Blacklisting an existing favorite removes it from the favorites list

### AC-6: Favorites List as Default Landing View (Must Have)

- [ ] When the user opens the app and no recent Visits exist, the Favorites tab is shown by default
- [ ] If the user has visited restaurants before, the Browse/Home tab remains the default landing view

### AC-7: Rating Scale Change Triggers Re-Detection (Must Have)

- [ ] When user changes rating scale in Settings (S05), all existing composite scores are re-derived
- [ ] Auto-detection rules re-run after re-computation
- [ ] Restaurants that cross the threshold are automatically added to or removed from Favorites
- [ ] Manual pins remain unaffected by scale change

### AC-8: Voice and Tone Compliance (Must Have)

- [ ] All UI text follows UX-DR2 voice & tone rules:
  - Tab label: "Favorites" — neutral, no exclamation marks
  - Group headers: cuisine name only + count in parentheses
  - No gamification language ("Your top picks!" — forbidden)

---

## Technical Notes

### Data Model Impact

- **Restaurant entity** already has `favorite: boolean` field (S01 AC-1) — described as "derived state"
- Implementation detail: `favorite` is computed from Visit aggregates + manual override, not stored independently
- Composite score re-computation needed when rating scale changes

### Repository Impact

- **`RestaurantRepository`** needs:
  - `Future<void> setFavorite(String restaurantId, bool favorite)` — sets/clears favorite status (manual pin)
  - `List<Restaurant> getFavorites()` — returns all favorite restaurants with Visit aggregates
  - `Future<void> recomputeAllFavorites()` — triggers auto-detection for all restaurants (used on scale change)
- **`VisitRepository`** needs:
  - `double averageCompositeScore(String restaurantId)` — computes average composite score across visits

### UI Component Requirements

- **Favorites tab** — bottom navigation item with star icon
- **Grouped list view** — `ListView.builder` with grouped sections by cuisine type
- **Favorite indicator on VisitCard** — small filled/outline star overlay (in addition to the card's existing fields)
- **Pin/unpin action** — tap star icon on card or detail view

### Provider Impact

- **FavoritesProvider** (AsyncNotifier) — watches for changes in Visits, re-runs auto-detection logic, emits updated favorites list
- Auto-detection runs after: new Visit saved, existing Visit ratings updated, rating scale changed in Settings

---

## Dependencies

| Dependency | Story | Status |
|------------|-------|--------|
| Isar Schema & Entity Models | S01 | Must be complete (`favorite` field on Restaurant) |
| Data Layer — Repository Implementation | S02 | Must be complete (repository methods for favorites operations) |
| Navigation Shell (Bottom Nav + IndexedStack) | S03 | Must be complete |
| Ratings Screen (4 Sliders + Composite Score) | S07 | Should be complete (composite score needed for auto-detection) |

---

## Testing Notes

- **Unit tests:** Auto-detection rule — verify all three conditions must be met; test with various Visit combinations
- **Unit tests:** Rating scale change re-computation — scores re-derived, favorites updated accordingly
- **Widget tests:** Favorites tab — list displays correctly, grouped by cuisine type, sorted by score descending
- **Widget tests:** Pin/unpin action — manual pin persists even when auto-detection criteria not met; unpin removes from list
- **Integration test:** Save new Visit → verify auto-detection runs → restaurant added/removed from favorites as appropriate
- **Integration test:** Change rating scale in Settings → all composite scores re-derived → favorites updated

---

## Open Questions

1. Should there be a "Favorites empty state" message? When no restaurants are favorited yet, show: "No favorites yet. Restaurants you visit often with great ratings will appear here."
2. For the default landing view logic (AC-6): should this be based on whether any Visits exist at all, or whether Favorites has entries? The PRD says "no recent Visits exist" — I'm interpreting this as zero total visits in the app.
