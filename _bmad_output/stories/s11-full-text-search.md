---
title: "S11 — Full-Text Search"
created: 2026-11-08
updated: 2026-11-08
status: draft
epic: "Epic 3: Browse & Discover"
jira_key: ST-011          # pending Jira creation
priority: P0
story_points: 5
realizes: FR-11
parent_prd_shard: prd-browse.md
---

# S11 — Full-Text Search

**As a** user, **I want** to search across all my visit data with relevant results ranked by importance, **so that** I can find specific restaurants, dishes, or notes quickly.

---

## References

| Artifact | Location |
|----------|----------|
| PRD Shard | [`_bmad_output/prd-shards/prd-browse.md`](../../prd-shards/prd-browse.md) — FR-11 |
| Epic Breakdown | [`docs/planning-artifacts/epics.md`](../../docs/planning-artifacts/epics.md) — S11 |
| Architecture Decision | AD-9: Search — Isar FTS + post-query Dart re-ranking with 9-tier priority model |
| UX Design | DESIGN.md + EXPERIENCE.md — Search Bar (UX-DR6), State Patterns |

---

## Acceptance Criteria

### AC-1: Search Bar Placement & Behavior (Must Have)

- [ ] Search bar is at the top of the list view in the Browse tab, always visible
- [ ] Tapping the search bar focuses it and shows the keyboard
- [ ] List updates are debounced by 200ms while user types (UX-DR6)
- [ ] Clear button (X icon) clears text and dismisses keyboard
- [ ] No results: "No matches." centered message — no suggestions offered (UX-DR10, EXPERIENCE.md Voice & Tone)

### AC-2: Search Scope — Fields Searched (Must Have)

Search queries across the following fields:
- Restaurant name
- Restaurant address
- Voice note transcripts (`voiceTranscript`)
- Journal entry dish names (`JournalEntry.dishName`)
- Journal entry impressions (`JournalEntry.impressions`)
- Occasion tags (`Visit.occasionTags[]`)
- Employee/server names (`employeeName`)
- Restaurant general notes (`Restaurant.generalNotes`)
- General visit notes (`Visit.notes`)

### AC-3: Relevance Ranking — 9-Tier Priority Model (Must Have)

Results are ranked by this priority model (highest to lowest):

| Tier | Match Type | Example |
|------|-----------|---------|
| 1 | Restaurant name exact match | Query "Nobu" matches visit at "Nobu" |
| 2 | Restaurant name partial match | Query "nobu" matches "Nobu Downtown" |
| 3 | Address match | Query "Broadway" matches address containing "Broadway Ave" |
| 4 | Journal dish name match | Query "lobster" matches journal entry with dish "Lobster Roll" |
| 5 | Journal impressions match | Query "soggy" matches journal impression "bread was soggy by bite 3" |
| 6 | Voice transcript match | Query "amazing" matches voice transcript containing "amazing flavors" |
| 7 | Employee name match | Query "Maria" matches employeeName "Maria Santos" |
| 8 | Occasion tag match | Query "date" matches occasionTag "Date Night" |
| 9 | General notes match | Query "patio" matches generalNotes "best patio seating in summer" |

- Field weights are **fixed for MVP** — no user-configurable tuning
- Implementation: Isar FTS + post-query Dart re-ranking (AD-9)

### AC-4: Matching Text Highlighting (Must Have)

- [ ] Matching text within each result is highlighted (e.g., bold or accent-colored background)
- [ ] Highlighting applies to the fields that matched — not all text in a card if only one field matched
- [ ] Case-insensitive matching

### AC-5: Search Latency Target (Should Have)

- [ ] Full-text search completes in <200ms for full local dataset (NFR-6)
- [ ] Given expected data volume (<500 Restaurants, <2000 Visits), even basic term-frequency search should feel instant on a modern smartphone

### AC-6: Voice and Tone Compliance (Must Have)

- [ ] Search placeholder text: "Search" or "Search visits..." — neutral, no exclamation marks
- [ ] No results message: "No matches." — informational only, no suggestions offered
- [ ] All UI text follows UX-DR2 voice & tone rules

---

## Technical Notes

### Implementation Approach (AD-9)

- **Primary:** Isar Full-Text Search (FTS) index on relevant fields
- **Post-processing:** Dart re-ranking with 9-tier priority model applied after Isar returns results
- The FTS query provides candidate matches; the Dart layer applies field-weighted scoring to produce final ordering

### Data Model Impact

- No schema changes needed — all searchable fields already exist on `Visit` and `Restaurant` entities (S01)
- Isar FTS index configuration required on: `restaurant.name`, `restaurant.address`, `restaurant.generalNotes`, `visit.voiceTranscript`, `journal.dishName`, `journal.impressions`, `visit.occasionTags`, `visit.employeeName`, `visit.notes`

### UI Component Requirements

- **SearchBar widget** — fixed at top of list view
  - Text field with clear button (X)
  - Focus management: show keyboard on tap, dismiss on clear
- **ResultCard widget** — reuses VisitCard component from S10 with highlighted matching text overlay
- **Debounced search controller** — 200ms delay between keystrokes before query executes

### Provider Impact

- `SearchProvider` (AsyncNotifier) — watches search text, runs FTS query + re-ranking, emits result list
- List view watches `SearchProvider` and updates accordingly

---

## Dependencies

| Dependency | Story | Status |
|------------|-------|--------|
| Isar Schema & Entity Models | S01 | Must be complete (FTS index configuration) |
| Data Layer — Repository Implementation | S02 | Must be complete (repository query methods with FTS support) |
| Filterable Visit Card List | S10 | **Co-developed** — search bar sits above the same list; can develop in parallel once S02 is done |

---

## Testing Notes

- **Unit tests:** 9-tier relevance ranking function — verify ordering for various query/result combinations
- **Widget tests:** Search bar — focus, clear button, debounced input updates list
- **Widget tests:** Matching text highlighting — correct fields highlighted in results
- **Integration test:** Query across multiple field types → results ordered by tier priority → matching text highlighted
- **Performance test:** Search latency measured via DevTools — should be <200ms even with full dataset

---

## Open Questions

1. Should the search bar auto-focus on first render of the Browse tab? UX-DR6 says "focus shows keyboard" but doesn't mandate auto-focus. Leaning toward no auto-focus to avoid unexpected keyboard pop-up on app launch.
2. For voice transcript matching: if a voice note failed transcription (no `voiceTranscript`), should it still be searchable via the manual text fallback? Yes — the fallback text is stored in the same field, so this works automatically with no extra work needed.
