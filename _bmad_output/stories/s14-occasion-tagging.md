---
title: "S14 — Occasion Tagging"
created: 2026-11-08
updated: 2026-11-08
status: draft
epic: "Epic 4: Favorites & Organization"
jira_key: ST-014          # pending Jira creation
priority: P2
story_points: 3
realizes: FR-8
parent_prd_shard: prd-favorites.md
---

# S14 — Occasion Tagging

**As a** user, **I want** to tag visits with occasions so I can filter and browse by the type of dining experience.

---

## References

| Artifact | Location |
|----------|----------|
| PRD Shard | [`_bmad_output/prd-shards/prd-favorites.md`](../../prd-shards/prd-favorites.md) — FR-8 |
| Epic Breakdown | [`docs/planning-artifacts/epics.md`](../../docs/planning-artifacts/epics.md) — S14 |
| Data Model | [`_bmad_output/prd-shards/prd-data-model.md`](../../prd-shards/prd-data-model.md) — `Visit.occasionTags[]`, `Restaurant.occasionTags[]` (defaults), `UserPreferences.defaultOccasionTags[]` |

---

## Scope Clarification

This story covers **per-Visit occasion tagging** only. Per-Restaurant default suggestions are covered in the Restaurant entity (S01 AC-1) and applied during logging but remain independent — defaults are merely suggestions, not constraints. User-defined occasions from onboarding/settings are also separate (S05).

---

## Acceptance Criteria

### AC-1: Predefined Occasion Tags During Logging (Must Have)

- [ ] Within the "Optional Sections Accordion" during visit logging, an "Occasion" section is available
- [ ] Predefined tags displayed as chips: Date Night, Quick Lunch, Family Dinner, Business Meal
- [ ] User can select multiple occasion tags per visit (multi-select)
- [ ] Selected tags appear as highlighted chips within the accordion section

### AC-2: Custom Occasion Tags (Must Have)

- [ ] User can add a custom occasion tag via free-text input + "Add" button
- [ ] Added custom tags persist for future use (stored in `UserPreferences.defaultOccasionTags[]`)
- [ ] Custom tags appear alongside predefined tags in the chip selector
- [ ] User can remove custom tags from Settings (S05 AC-2)

### AC-3: Occasion Tags on Visit Cards (Must Have)

- [ ] Visit cards display selected occasion tags as small pill badges below the restaurant name
- [ ] Maximum 3 tags shown per card; additional tags truncated with "+N" indicator
- [ ] Tag chips are not interactive on visit cards — tap navigates to Visit Detail View only

### AC-4: Filter by Occasion Tag (Must Have)

- [ ] Occasion tag filter available in the filter bottom sheet from S10
- [ ] Multi-select chips for occasion tags (predefined + custom)
- [ ] Selecting an occasion tag filters the list to show only visits with that tag
- [ ] Multiple occasion tags can be selected — results match visits containing **any** of the selected tags

### AC-5: Voice and Tone Compliance (Must Have)

- [ ] All UI text follows UX-DR2 voice & tone rules:
  - Section header: "Occasion" — neutral label
  - Tag labels: short, title case ("Date Night", not "This was a date night")
  - No exclamation marks, no gamification language

---

## Technical Notes

### Data Model Impact

- **Visit entity** already has `occasionTags: string[]` field (S01 AC-1) — per-visit occasions
- **Restaurant entity** has `occasionTags: string[]` field (S01 AC-1) — default suggestions applied during logging, not constraints
- **UserPreferences entity** has `defaultOccasionTags: string[]` field (S01 AC-1) — user-defined occasions from onboarding/settings

### Repository Impact

- **`VisitRepository`** needs:
  - `Future<void> addOccasionTag(String visitId, String tag)` — adds a tag to an existing visit's occasion list
  - `Future<void> removeOccasionTag(String visitId, String tag)` — removes a tag from a visit's occasion list
  - `List<Visit> getByOccasionTags(List<String> tags)` — filters visits by selected occasion tags

### UI Component Requirements

- **Chip selector** within visit logging accordion (shares framework with S06 allergy-safe chips)
  - Predefined tags as static chips
  - Custom tag input field + add button
  - Multi-select behavior (tapping a chip toggles selection)
- **VisitCard occasion display** — small pill badges below restaurant name, truncated at 3 with "+N" overflow indicator

### Interaction with Other Stories

- **S08 (Accordion):** This story owns the occasion tagging accordion section; S08 owns the accordion framework
- **S10 (Filter list):** Occasion tag filter is one of the four filter groups in the bottom sheet
- **S05 (Settings):** Custom occasion tags can be removed from Settings

---

## Dependencies

| Dependency | Story | Status |
|------------|-------|--------|
| Isar Schema & Entity Models | S01 | Must be complete (`occasionTags` field on Visit entity) |
| Data Layer — Repository Implementation | S02 | Must be complete (repository methods for occasion tag operations) |
| Navigation Shell (Bottom Nav + IndexedStack) | S03 | Must be complete |

---

## Testing Notes

- **Widget tests:** Occasion chip selector in logging form — predefined tags display, multi-select works, custom tag add/remove works
- **Widget tests:** VisitCard occasion display — up to 3 tags shown, "+N" overflow indicator correct
- **Integration test:** Add occasion tags during logging → verify they appear on visit card and are filterable

---

## Open Questions

1. Should there be a character limit on custom occasion tags? Suggesting 50 characters max for consistency with other free-text fields.
2. For the "+N" overflow indicator on visit cards: should tapping it navigate to Visit Detail or open a quick-view popup of all tags? Leaning toward Visit Detail for simplicity — no extra component needed.
