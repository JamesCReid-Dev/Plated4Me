---
title: "S12 — Restaurant General Notes"
created: 2026-11-08
updated: 2026-11-08
status: draft
epic: "Epic 3: Browse & Discover"
jira_key: ST-012          # pending Jira creation
priority: P1
story_points: 3
realizes: FR-17
parent_prd_shard: prd-browse.md
---

# S12 — Restaurant General Notes

**As a** user, **I want** to add persistent free-text notes about a restaurant that span all my visits, **so that** I can capture enduring information ("best patio seating in summer," "call ahead on weekends") that applies to the establishment as a whole.

---

## References

| Artifact | Location |
|----------|----------|
| PRD Shard | [`_bmad_output/prd-shards/prd-browse.md`](../../prd-shards/prd-browse.md) — FR-17 |
| Epic Breakdown | [`docs/planning-artifacts/epics.md`](../../docs/planning-artifacts/epics.md) — S12 AC-3 |
| Data Model | [`_bmad_output/prd-shards/prd-data-model.md`](../../prd-shards/prd-data-model.md) — `Restaurant.generalNotes` |

---

## Scope Clarification

This is a **standalone feature** restored from original v3.0 US-3/FR-3, which was absorbed into FR-2 during BMAD reformatting. Persistent restaurant-level notes differ from per-visit journal entries (FR-6): restaurant notes capture enduring information about the establishment itself, not about one specific visit.

The `generalNotes` field already exists on the `Restaurant` entity (S01 AC-1). This story implements the UI and behavior around it.

---

## Acceptance Criteria

### AC-1: Restaurant Notes in Visit Logging (Must Have)

- [ ] Within the "Optional Sections Accordion" during visit logging, a "Restaurant Notes" section is available
- [ ] If the restaurant already exists (not newly created), existing notes appear **pre-populated** in an expandable section
- [ ] If the restaurant is new (auto-created during logging), the section shows placeholder text: "Add notes about this restaurant..."
- [ ] User can edit, add to, or clear existing notes
- [ ] Saving the visit persists any changes to `Restaurant.generalNotes`
- [ ] Notes are saved at the Restaurant level — not tied to the individual Visit

### AC-2: Restaurant Notes in Restaurant Detail View (Must Have)

- [ ] Restaurant detail view includes a "General Notes" section
- [ ] Notes displayed as plain text with an edit (pencil) icon
- [ ] Tapping the edit icon opens an inline editor or bottom sheet for editing notes
- [ ] Saving updates persists changes to `Restaurant.generalNotes`
- [ ] Empty state: "No notes yet. Add one when logging a visit, or tap + below."

### AC-3: Notes Included in Full-Text Search (Must Have)

- [ ] Restaurant general notes are searched as part of FR-11 full-text search
- [ ] Matches in general notes appear at **Tier 9** (lowest priority) in the relevance ranking model
- [ ] Matching text highlighted in search results per FR-11 AC-4

### AC-4: Voice and Tone Compliance (Must Have)

- [ ] All UI text follows UX-DR2 voice & tone rules:
  - Section header: "Restaurant Notes" — neutral label
  - Placeholder text: "Add notes about this restaurant..." — short, complete sentence
  - Empty state: "No notes yet." — informational only
  - No exclamation marks, no gamification language

---

## Technical Notes

### Data Model Impact

- **Entity:** `Restaurant` already has `generalNotes: String?` field (S01 AC-1)
- No schema changes needed — this story is primarily UI + behavior

### Repository Impact

- **`RestaurantRepository`** needs:
  - `Future<void> updateGeneralNotes(String restaurantId, String notes)` — updates the general notes field
  - This is a simple single-field update on an existing entity

### UI Component Requirements

- **Accordion section** within visit logging form (shares accordion framework with S06, S08, S15)
  - Expandable/collapsible by default if notes exist; collapsed if empty
  - Free-text editor (multiline `TextFormField`)
- **Restaurant detail notes section** — display + edit inline or via bottom sheet
  - Plain text display with word wrap
  - Edit action opens a simple text input dialog or bottom sheet

### Interaction with Other Stories

- **S08 (Accordion):** This story owns the restaurant notes accordion section; S08 owns the accordion framework
- **S11 (Search):** Notes are included in search scope — S12 ensures `Restaurant.generalNotes` is indexed by Isar FTS
- **S10 (List view):** Notes are NOT displayed on visit cards — only in detail views

---

## Dependencies

| Dependency | Story | Status |
|------------|-------|--------|
| Isar Schema & Entity Models | S01 | Must be complete (`generalNotes` field on Restaurant) |
| Data Layer — Repository Implementation | S02 | Must be complete (repository update method for general notes) |
| Navigation Shell (Bottom Nav + IndexedStack) | S03 | Must be complete |
| Full-Text Search | S11 | **Co-developed** — S12 ensures notes are indexed; S11 searches them. Can develop in parallel once S02 is done |

---

## Testing Notes

- **Widget tests:** Restaurant notes accordion in logging form — pre-populated for existing restaurant, placeholder for new restaurant, edit/save behavior
- **Widget tests:** Restaurant detail notes section — display, edit inline/bottom sheet, save persistence
- **Integration test:** Save notes during logging → open same restaurant later → notes still present and editable
- **Integration test:** Update notes in restaurant detail → verify they appear in logging flow as pre-populated

---

## Open Questions

1. Should there be a character limit on general notes? PRD doesn't specify one. For a single-user app, unlimited text is reasonable — but we should cap at something reasonable (e.g., 2000 characters) to avoid UI issues.
2. Should notes support basic formatting (line breaks, bullet points)? Free-text with line breaks preserved is sufficient for MVP; rich text or markdown can be post-MVP.
