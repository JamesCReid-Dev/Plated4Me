---
title: "S10 — Filterable Visit Card List"
created: 2026-11-08
updated: 2026-11-08
status: draft
epic: "Epic 3: Browse & Discover"
jira_key: ST-010          # pending Jira creation
priority: P0
story_points: 5
realizes: FR-9
parent_prd_shard: prd-browse.md
---

# S10 — Filterable Visit Card List

**As a** user, **I want** to browse my visit history as filterable cards showing restaurant name, date, composite score, and return intent, **so that** I can quickly scan past experiences.

---

## References

| Artifact | Location |
|----------|----------|
| PRD Shard | [`_bmad_output/prd-shards/prd-browse.md`](../../prd-shards/prd-browse.md) — FR-9 |
| Epic Breakdown | [`docs/planning-artifacts/epics.md`](../../docs/planning-artifacts/epics.md) — S10 |
| UX Design | DESIGN.md + EXPERIENCE.md — Visit Card (UX-DR3), Filter Controls (UX-DR5), State Patterns (UX-DR10) |

---

## Acceptance Criteria

### AC-1: Visit Card Component (Must Have)

- [ ] Each card displays the following fields:
  - **Restaurant name** — headline font weight, truncated after 40 characters with ellipsis
  - **Date** — caption style, relative format ("2 days ago") or formatted ("Nov 5, 2026") for older entries
  - **Composite score bar** — accent color fill proportional to score, 3px height at bottom of card (visual only, not interactive)
  - **Return intent pill** — top-right corner: "Would I come back?" Yes/No indicator
- [ ] Card tap navigates to Visit Detail View (UX-DR3)
- [ ] Long-press is a no-op in MVP (reserved for future use — UX-DR13)

### AC-2: Default Sort — Most Recent First (Must Have)

- [ ] List is sorted by `Visit.date` descending (most recent first) by default
- [ ] No sort selector UI in MVP — sort order is fixed, not user-configurable

### AC-3: Filter Controls — Bottom Sheet (Must Have)

- [ ] Tap the filter icon in the list header → bottom sheet slides up from bottom with dimmed background overlay
- [ ] Filter options available:
  - **Cuisine type** — multi-select chips (same ~20 presets as onboarding)
  - **Rating range** — slider or min/max input using user's chosen scale (5 or 10)
  - **Occasion tag** — multi-select chips (user-defined occasions from onboarding/settings)
  - **Allergy-safe status** — toggle: "Show only allergy-safe visits" ON/OFF
- [ ] Cost-related filters (tip %, meal total range) are **excluded from MVP**

### AC-4: Filter Apply & Reset (Must Have)

- [ ] "Apply" button closes the bottom sheet and updates the list in one frame (~16ms render time)
- [ ] "Clear all filters" button resets to unfiltered view and closes the sheet
- [ ] Active filter icon shows a dot/badge when any filter is active (UX-DR5)

### AC-5: Blacklisted Visit Cards (Must Have)

- [ ] Blacklisted visit cards show a 40% `ink-disabled` grey overlay + dimmed text (UX-DR3, DESIGN.md Visit Card)
- [ ] Tap on blacklisted card still navigates to Visit Detail — blacklisting does not prevent viewing
- [ ] Blacklisted visits are **not excluded** from the default list view (they appear dimmed); they are only excluded from favorites computation

### AC-6: Cold Open Empty State (Must Have)

- [ ] When no visits exist: large icon/illustration area, headline "No visits yet", subtext "Tap + to log your first dining experience"
- [ ] This state appears before any data is loaded — no loading spinner visible

### AC-7: Voice and Tone Compliance (Must Have)

- [ ] All UI text follows UX-DR2 voice & tone rules:
  - Short, complete sentences only
  - No exclamation marks
  - No encouragement/gamification language
  - State indicators are text-only — no icon + text combos for status

---

## Technical Notes

### Data Model Impact

- **Visit entity** already has all required fields (from S01): `restaurantId`, `compositeScore`, `returnIntent`, `isBlacklisted`
- **Restaurant entity** provides `name`, `cuisineType` via join
- Query pattern: `Visit` joined with `Restaurant` → filtered by cuisine, rating range, occasion, allergy-safe status → sorted by date DESC

### UI Component Requirements

- **VisitCard widget** — reusable card component used in both Browse list and Favorites tab
  - Accepts a `Visit` + `Restaurant` pair as input
  - Renders name, date, composite score bar, return intent pill
  - Applies blacklisted styling conditionally
- **Filter bottom sheet** — reusable bottom-sheet overlay
  - Takes filter state as input, emits filtered results on apply
  - Each filter group is independently toggleable
- **List view** — `ListView.builder` with VisitCard children
  - Debounced updates (no intermediate states during filter application)

### Performance Target

- Filter results update within one frame (~16ms) of filter change
- All data is local (Isar), so this target should be easily achievable even with full dataset

---

## Dependencies

| Dependency | Story | Status |
|------------|-------|--------|
| Isar Schema & Entity Models | S01 | Must be complete |
| Data Layer — Repository Implementation | S02 | Must be complete (query streams, repository interfaces) |
| Navigation Shell (Bottom Nav + IndexedStack) | S03 | Must be complete |
| Ratings Screen (4 Sliders + Composite Score) | S07 | Should be complete (composite score needed for cards) |

---

## Testing Notes

- **Widget tests:** VisitCard renders all fields correctly — name truncation, date formatting, composite bar fill proportion, return intent pill state
- **Widget tests:** Filter bottom sheet — each filter group toggles independently, apply/reset behavior correct
- **Widget tests:** Blacklisted card styling — grey overlay + dimmed text visible, tap still navigates
- **Widget tests:** Empty state displayed when no visits exist
- **Integration test:** Apply multiple filters → list updates in one frame → results match expected query
- **Performance test:** Filter application time measured via DevTools — should be <16ms

---

## Open Questions

1. Should the filter sheet show active filter counts (e.g., "Cuisine (2)") or just the selected values? UX-DR5 doesn't specify — lean toward showing selected values directly as chips for simplicity.
2. For rating range filter, should it be a continuous slider or discrete min/max inputs? Slider is more intuitive but harder to set precise boundaries. Min/max inputs are more precise but add UI complexity.
