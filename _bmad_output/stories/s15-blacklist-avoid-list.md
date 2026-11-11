---
title: "S15 — Blacklist / Avoid List"
created: 2026-11-08
updated: 2026-11-08
status: draft
epic: "Epic 4: Favorites & Organization"
jira_key: ST-015          # pending Jira creation
priority: P1
story_points: 3
realizes: FR-10
parent_prd_shard: prd-browse.md
---

# S15 — Blacklist / Avoid List

**As a** user, **I want** to blacklist bad restaurant visits so they don't pollute my favorites and I remember what to avoid.

---

## References

| Artifact | Location |
|----------|----------|
| PRD Shard | [`_bmad_output/prd-shards/prd-browse.md`](../../prd-shards/prd-browse.md) — FR-10 |
| Epic Breakdown | [`docs/planning-artifacts/epics.md`](../../docs/planning-artifacts/epics.md) — S15 |
| Data Model | [`_bmad_output/prd-shards/prd-data-model.md`](../../prd-shards/prd-data-model.md) — `isBlacklisted`, `blacklistReason`, `blacklistedAt` on Visit |

---

## Scope Clarification

This story covers the **per-Visit blacklist mechanism**. Blacklisting a Visit does **not** blacklist the entire Restaurant — the Restaurant remains browsable and can still be revisited. This is a key distinction from the original v3.0 design (S4 resolved in PRD review).

Blacklist clearing is implemented as part of **S05: Settings & Preferences** (AC-6) since it's a settings action, but this story defines the data model and logic for it.

---

## Acceptance Criteria

### AC-1: Blacklist Toggle During Visit Logging (Must Have)

- [ ] Blacklist toggle is available in the "Optional Sections Accordion" during visit logging
- [ ] Section header: "Blacklist this visit?" with a Yes/No pill toggle
- [ ] Selecting **Yes** reveals additional fields:
  - Reason selector — suggested categories as chips: Poor Food, Bad Service, Overpriced, Allergy Issue, Other
  - Optional free-text reason field (shown when "Other" is selected or always available)
- [ ] Selecting **No** hides the reason fields
- [ ] User can save the visit without blacklisting — never blocks save

### AC-2: Blacklist Toggle from Visit Detail View (Must Have)

- [ ] Visit detail view includes a "Blacklisted" status indicator
- [ ] If not blacklisted: tap toggles to blacklisted, reveals reason fields (same as logging flow)
- [ ] If already blacklisted: shows current blacklist status + reason; user can change or remove the blacklist
- [ ] Removing a blacklist sets `isBlacklisted = false` and clears `blacklistReason`

### AC-3: Blacklisted Visits Excluded from Favorites (Must Have)

- [ ] Visits with `isBlacklisted = true` are excluded from favorites auto-detection computation (S13 AC-5)
- [ ] A visit that would otherwise qualify as a favorite is **not** added to favorites if it is blacklisted
- [ ] Blacklisting an existing favorite removes it from the favorites list

### AC-4: Blacklisted Visit Card Styling (Must Have)

- [ ] Blacklisted visit cards in list views show 40% `ink-disabled` grey overlay + dimmed text (UX-DR3, DESIGN.md Visit Card)
- [ ] Tap on blacklisted card still navigates to Visit Detail — blacklisting does not prevent viewing
- [ ] This styling is applied consistently across Browse list and Favorites tab

### AC-5: Blacklist Clear from Settings (Must Have)

- [ ] Implemented in **S05: Settings & Preferences** (AC-6) but data logic owned here
- [ ] Bulk clear removes all Visits with `isBlacklisted = true`
- [ ] Confirmation dialog required before clearing
- [ ] After clearing, confirmation toast displayed

### AC-6: Voice and Tone Compliance (Must Have)

- [ ] All UI text follows UX-DR2 voice & tone rules:
  - Section header: "Blacklist this visit?" — neutral, no exclamation marks
  - Reason categories: short labels only ("Poor Food", not "The food was terrible")
  - No gamification language ("Avoid this place next time!" — forbidden)

---

## Technical Notes

### Data Model Impact

- **Visit entity** already has blacklist fields (S01):
  - `isBlacklisted`: `bool?` — nullable to distinguish "not set" from "false"
  - `blacklistReason`: `String?` — free text with suggested categories
  - `blacklistedAt`: `DateTime?` — timestamp when visit was blacklisted

### Repository Impact

- **`VisitRepository`** needs:
  - `Future<void> toggleBlacklist(String visitId, bool blacklisted, String? reason)` — sets/clears blacklist state + timestamp
  - `List<Visit> getNonBlacklisted()` — for favorites computation (S13)
  - `Future<int> clearAllBlacklisted()` — bulk delete used by S05 Settings

### UI Component Requirements

- **Blacklist accordion section** within visit logging form (shares accordion framework with S06, S08)
- **Blacklist toggle pill** — Yes/No selector in the accordion
- **Reason chip selector** — horizontal scrollable chips for suggested categories + free-text fallback
- **Visit detail blacklist indicator** — small status badge showing "Blacklisted" with reason preview

### Interaction with Favorites (S13)

- When a visit is blacklisted, it must be excluded from the favorites computation logic in S13
- This requires the favorites provider to filter out blacklisted visits when evaluating criteria

---

## Dependencies

| Dependency | Story | Status |
|------------|-------|--------|
| Isar Schema & Entity Models | S01 | Must be complete (blacklist fields on Visit entity) |
| Data Layer — Repository Implementation | S02 | Must be complete (repository methods for blacklist operations) |
| Navigation Shell (Bottom Nav + IndexedStack) | S03 | Must be complete |
| Optional Sections Accordion | S08 | **Co-developed** — blacklist section shares accordion framework; can develop in parallel once S03 is done |

---

## Testing Notes

- **Unit tests:** Blacklist toggle logic — setting/clearing `isBlacklisted`, `blacklistReason`, `blacklistedAt`
- **Widget tests:** Blacklist accordion in logging form — toggle Yes/No, reason chips, free-text input
- **Widget tests:** Visit detail blacklist indicator — shows status, tap toggles, confirmation on clear
- **Integration test:** Blacklist a visit → verify it's excluded from favorites computation
- **Integration test:** Bulk clear blacklisted visits via Settings → zero blacklisted visits remain

---

## Open Questions

1. Should the blacklist reason categories be localized? Currently hardcoded as English labels. For a single-user app, this may not be necessary in MVP.
2. When clearing all blacklisted visits from Settings, should there be an undo option (e.g., 5-second toast with "Undo")? Not in scope for MVP per UX-DR13 (no complex gesture patterns), but a simple confirmation dialog + toast is sufficient.
