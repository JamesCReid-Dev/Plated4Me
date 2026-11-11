---
title: "S04 — Onboarding Flow"
created: 2026-11-08
updated: 2026-11-08
status: draft
epic: "Epic 1: Foundation & Setup"
jira_key: ST-004          # pending Jira creation
priority: P1
story_points: 5
realizes: FR-14
parent_prd_shard: prd-setup.md
---

# S04 — Onboarding Flow

**As a** new user, **I want** a guided first-run setup that captures my allergies, cuisine preferences, rating scale, and default occasions, **so that** the app is personalized from the start.

---

## References

| Artifact | Location |
|----------|----------|
| PRD Shard | [`_bmad_output/prd-shards/prd-setup.md`](../../prd-shards/prd-setup.md) — FR-14 |
| Epic Breakdown | [`docs/planning-artifacts/epics.md`](../../docs/planning-artifacts/epics.md) — S04 |
| Architecture Decision | AD-6: Onboarding gate route `/onboarding` |
| UX Design | DESIGN.md + EXPERIENCE.md — Flow 3, State Patterns |

---

## Acceptance Criteria

### AC-1: Screen 1 — Allergies (Must Have)

- [ ] App displays "Do you have any food allergies?" as the screen heading
- [ ] User can add allergens with a severity selector (Moderate / Severe)
- [ ] User can remove previously added allergens
- [ ] "Skip for now" button is always visible and accessible
- [ ] Allergy input is **optional but encouraged** — no validation blocking progression
- [ ] VoiceOver/TalkBack labels on every interactive element (UX-DR11)

### AC-2: Screen 2 — Cuisine Preferences (Must Have)

- [ ] App displays ~20 preset cuisine chips in a scrollable grid: Japanese, Mexican, Italian, Chinese, Thai, Indian, American, Mediterranean, French, Korean, Vietnamese, Greek, Turkish, Ethiopian, Brazilian, Lebanese, Spanish, German, Swedish, Indonesian
- [ ] A "Custom" chip allows free-text entry for additional cuisines
- [ ] Multiple selections supported (multi-select chips)
- [ ] "Skip for now" button is always visible and accessible
- [ ] Selected cuisines are visually highlighted

### AC-3: Screen 3 — Rating Scale Preference (Must Have)

- [ ] Two large tappable cards presented side-by-side or stacked:
  - Card A: ★★★★★ (5-star scale)
  - Card B: ⭐ × 10 (10-star scale, shows ten tick marks)
- [ ] Selecting a card highlights it and proceeds to the next screen
- [ ] Default is **5-star** if user skips this step
- [ ] "Skip for now" button is always visible

### AC-4: Screen 4 — Default Occasions (Must Have)

- [ ] Pre-populated occasion chips displayed: Date Night, Family Dinner, Business Lunch, Quick Bite, Celebration, Trying Something New
- [ ] User can add custom occasion tags via free-text input
- [ ] Multiple selections supported
- [ ] "Skip for now" button defaults to **all occasions available**
- [ ] Selected occasions are visually highlighted

### AC-5: Completion Writes UserPreferences (Must Have)

- [ ] Completing all four screens writes a `UserPreferences` entity to Isar
- [ ] Written fields: `allergies[]`, `cuisinePreferences[]`, `ratingScale` (5 or 10), `defaultOccasions[]`, `onboardingComplete = true`
- [ ] After write, user navigates to the Browse/Home tab (AD-6)

### AC-6: Skip Behavior — Sensible Defaults (Must Have)

- [ ] Skipping any screen uses these defaults:
  - Allergies → empty list
  - Cuisine preferences → empty list (user adds later)
  - Rating scale → 5-star
  - Default occasions → all predefined occasions available
- [ ] User can always return to Settings to configure skipped items

### AC-7: Target Completion Time <2 Minutes (Should Have)

- [ ] Onboarding flow completes in under 2 minutes for an engaged user
- [ ] No loading states or unnecessary delays between screens
- [ ] Transition between screens is a simple slide animation (or none, per UX-DR13)

---

## Technical Notes

### Data Model Impact

- **Entity:** `UserPreferences` (Isar collection — S01 AC-3)
  - `id`: auto-generated UUID
  - `allergies`: `List<Allergy>` where `Allergy` has `name: String`, `severity: AllergySeverity`
  - `cuisinePreferences`: `List<String>` (preset names + custom entries)
  - `ratingScale`: `int` — either `5` or `10`
  - `defaultOccasions`: `List<String>`
  - `onboardingComplete`: `bool`

### Navigation Impact (AD-6)

- Route `/onboarding` is a **gate route** checked before the main navigation shell renders
- Gate logic: if `UserPreferences.onboardingComplete == false` (or no record exists), show onboarding; otherwise navigate directly to Browse/Home
- Onboarding is a **one-time flow** — once completed, it never reappears automatically

### UI Component Requirements

- Four sequential screens with progress indicator (e.g., dot indicators at top)
- Bottom-sheet-style "Skip for now" action
- Chip-based selection components for cuisine and occasions
- Severity selector dropdown or segmented control for allergies
- Large tappable card components for rating scale selection

---

## Dependencies

| Dependency | Story | Status |
|------------|-------|--------|
| Isar Schema & Entity Models | S01 | Must be complete before implementation |
| Data Layer — Repository Implementation | S02 | Must be complete before implementation |
| Navigation Shell (Bottom Nav + IndexedStack) | S03 | Must be complete before implementation |

---

## Testing Notes

- **Unit tests:** `UserPreferences` entity serialization/deserialization with all field combinations
- **Widget tests:** Each of the 4 onboarding screens — skip button always present, selection state updates correctly
- **Integration test:** Full flow completion → `UserPreferences` written to Isar → navigation to Browse/Home
- **Integration test:** Skip at each screen → correct defaults applied

---

## Open Questions

1. Should the progress indicator be dots (4) or a step counter ("Step 2 of 4")? UX-DR2 says short complete sentences — no preference stated.
2. Should skipped screens show a "Configure later" hint on the Settings screen, or is the Settings menu self-explanatory?
