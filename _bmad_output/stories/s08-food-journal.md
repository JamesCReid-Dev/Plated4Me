---
title: "S08 — Food Journal"
created: 2026-11-08
updated: 2026-11-08
status: draft
epic: "Epic 2: Core Visit Logging"
jira_key: ST-008          # pending Jira creation
priority: P1
story_points: 5
realizes: FR-6
parent_prd_shard: prd-journal.md
---

# S08 — Food Journal

**As a** user, **I want** to create per-visit journal entries with dish names and free-text impressions, **so that** I can capture how dishes evolved over time.

---

## References

| Artifact | Location |
|----------|----------|
| PRD Shard | [`_bmad_output/prd-shards/prd-journal.md`](../../prd-shards/prd-jard.md) — FR-6 |
| Epic Breakdown | [`docs/planning-artifacts/epics.md`](../../docs/planning-artifacts/epics.md) — S08 AC-3 |
| Data Model | [`_bmad_output/prd-shards/prd-data-model.md`](../../prd-shards/prd-data-model.md) — `JournalEntry` entity, `Visit.journalEntries[]` |

---

## Scope Clarification

This story covers **per-Visit journal entry creation and editing**. Journal entries are an optional expandable section within the logging flow — not part of the core ≤30-second path. Per-dish rating is deferred; journal notes are free-text only in MVP.

The accordion framework that contains this section is shared with S06 (Allergy-Safe Database), S12 (Restaurant Notes), and S15 (Blacklist). This story owns the journal entry UI within that framework.

---

## Acceptance Criteria

### AC-1: Journal Entry Creation During Logging (Must Have)

- [ ] "Journal" section appears in the Optional Sections Accordion during visit logging
- [ ] Section starts empty with a "+ Add dish" button at the bottom
- [ ] Tapping "+ Add dish" reveals an inline form with two fields:
  - **Dish name** — required text field, placeholder "e.g., Lobster Roll"
  - **Impressions** — optional free-text textarea, placeholder "Describe how it tasted over time..."
- [ ] User can add multiple journal entries per visit (tap "+ Add dish" again)
- [ ] Each entry displays as a card within the accordion section with:
  - Dish name in bold headline style
  - Impressions text below (truncated after 2 lines with "Read more" expand)
  - Delete button (trash icon, top-right of each entry card)

### AC-2: Journal Entry Editing & Deletion (Must Have)

- [ ] Tapping on a journal entry card opens an inline editor for that entry
- [ ] Both dish name and impressions are editable
- [ ] Save button persists changes to the `JournalEntry` entity
- [ ] Delete button shows confirmation dialog before removing the entry: "Delete this dish note?"
- [ ] Deleting an entry removes it from the accordion list immediately

### AC-3: Journal Entries Persisted with Visit (Must Have)

- [ ] When a visit is saved, all journal entries are persisted as part of the `Visit.journalEntries[]` array
- [ ] When editing an existing visit's details, previously saved journal entries appear pre-populated in the accordion section
- [ ] Journal entries are stored at the Visit level — not shared across visits to the same restaurant

### AC-4: Voice and Tone Compliance (Must Have)

- [ ] All UI text follows UX-DR2 voice & tone rules:
  - Section header: "Journal" — neutral label
  - Add button: "+ Add dish" — short, complete instruction
  - Placeholder text: "e.g., Lobster Roll", "Describe how it tasted over time..." — short, complete sentences
  - Delete confirmation: "Delete this dish note?" — clear, no exclamation marks
  - No gamification language ("Your food diary!" — forbidden)

---

## Technical Notes

### Data Model Impact

- **JournalEntry entity** already exists (S01 AC-1):
  - `dishName`: `String` — required
  - `impressions`: `String?` — optional free-text
- **Visit entity** has `journalEntries: List<JournalEntry>?` field (S01 AC-1)

### Repository Impact

- **`VisitRepository`** needs:
  - `Future<void> addJournalEntry(String visitId, JournalEntry entry)` — adds a new journal entry to the visit's list
  - `Future<void> updateJournalEntry(String visitId, String entryId, JournalEntry updatedEntry)` — updates an existing entry
  - `Future<void> removeJournalEntry(String visitId, String entryId)` — removes an entry from the visit's list

### UI Component Requirements

- **Accordion section** within visit logging form (shares accordion framework with S06, S12, S15)
  - Expandable/collapsible by default
  - Empty state: "+ Add dish" button visible when no entries exist
- **JournalEntryCard widget** — reusable card component for displaying/editing a single entry
  - Displays dish name + truncated impressions with "Read more" expand
  - Delete button with confirmation dialog
  - Tap to open inline editor
- **Inline form** — dish name field + impressions textarea, shown when adding or editing an entry

### Interaction with Other Stories

- **S06 (Allergy-Safe Database):** Shares accordion framework; both stories own their respective sections within the same accordion
- **S12 (Restaurant Notes):** Same accordion pattern; restaurant notes section is separate from journal entries
- **S15 (Blacklist):** Same accordion pattern; blacklist toggle is a third optional section

---

## Dependencies

| Dependency | Story | Status |
|------------|-------|--------|
| Isar Schema & Entity Models | S01 | Must be complete (`JournalEntry` entity, `Visit.journalEntries[]`) |
| Data Layer — Repository Implementation | S02 | Must be complete (repository methods for journal entry CRUD) |
| Navigation Shell (Bottom Nav + IndexedStack) | S03 | Must be complete |

---

## Testing Notes

- **Widget tests:** Journal accordion section in logging form — empty state shows "+ Add dish", adding entries works, multiple entries display correctly
- **Widget tests:** JournalEntryCard widget — displays dish name + truncated impressions, "Read more" expands, delete button shows confirmation
- **Widget tests:** Inline editor — tap on entry opens edit mode, save persists changes, cancel discards changes
- **Integration test:** Save visit with journal entries → open same visit later → entries appear pre-populated and editable

---

## Open Questions

1. Should there be a character limit on impressions? Suggesting 2000 characters max for consistency with other free-text fields (voice notes, general notes).
2. For the "Read more" truncation: should it expand inline within the accordion or open a bottom sheet/drawer? Leaning toward inline expansion to keep everything in one place and avoid extra navigation.
