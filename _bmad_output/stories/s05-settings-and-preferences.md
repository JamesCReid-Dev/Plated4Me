---
title: "S05 — Settings & Preferences"
created: 2026-11-08
updated: 2026-11-08
status: draft
epic: "Epic 1: Foundation & Setup"
jira_key: ST-005          # pending Jira creation
priority: P1
story_points: 5
realizes: FR-16
parent_prd_shard: prd-setup.md
---

# S05 — Settings & Preferences

**As a** user, **I want** to manage my allergies, rating scale, and data export from Settings, **so that** I can update preferences after onboarding.

---

## References

| Artifact | Location |
|----------|----------|
| PRD Shard | [`_bmad_output/prd-shards/prd-setup.md`](../../prd-shards/prd-setup.md) — FR-16 |
| Epic Breakdown | [`docs/planning-artifacts/epics.md`](../../docs/planning-artifacts/epics.md) — S05 |
| PRD Shard (Onboarding) | [`_bmad_output/prd-shards/prd-setup.md`](../../prd-shards/prd-setup.md) — FR-14 (cuisine, occasions — editable here too) |
| UX Design | DESIGN.md + EXPERIENCE.md — Voice & Tone (UX-DR2), State Patterns |

---

## Acceptance Criteria

### AC-1: Allergen Management Screen (Must Have)

- [ ] Settings screen includes an "Allergies" section with a list of current allergens
- [ ] Each allergen entry shows the name and severity level badge (Mild / Moderate / Severe)
- [ ] "Add allergy" button opens a form: free-text allergen name + severity selector (Mild, Moderate, Severe)
- [ ] Each existing allergen has an edit (pencil) and delete (trash) action
- [ ] Deleting an allergen shows a confirmation dialog: "Remove [allergen] from your allergies?"
- [ ] Empty state: "No allergies configured. Tap + to add one."

### AC-2: Rating Scale Customization (Must Have)

- [ ] Settings screen includes a "Rating Scale" section
- [ ] Two tappable options presented as cards or segmented control: 5-star ★★★★★ / 10-star ⭐ × 10
- [ ] Selecting a different scale triggers a confirmation dialog: "Changing the rating scale will rescale all your existing ratings. Continue?"
- [ ] On confirm, **all existing Visit ratings are re-scaled** proportionally (e.g., a 4/5 becomes 8/10)
- [ ] After change, all future logging and display uses the new scale
- [ ] VoiceOver/TalkBack labels on every interactive element (UX-DR11)

### AC-3: Cuisine Preferences — Edit (Must Have)

- [ ] Settings screen includes a "Cuisine Preferences" section showing current selections as chips
- [ ] User can remove existing cuisine preferences by tapping the chip's close icon
- [ ] User can add new cuisines via free-text input + "Add" button
- [ ] ~20 preset options available in a bottom-sheet picker (same list as onboarding)
- [ ] Changes persist immediately to `UserPreferences`

### AC-4: Default Occasions — Edit (Must Have)

- [ ] Settings screen includes a "Default Occasions" section showing current selections as chips
- [ ] User can remove existing occasion tags by tapping the chip's close icon
- [ ] User can add new occasions via free-text input + "Add" button
- [ ] Predefined options available in a bottom-sheet picker (same list as onboarding)
- [ ] Changes persist immediately to `UserPreferences`

### AC-5: JSON Data Export (Must Have)

- [ ] Settings screen includes a "Data & Backup" section with an "Export your data as JSON" button
- [ ] Tapping the button opens a file picker / share sheet (platform-appropriate)
- [ ] User chooses destination; on save, a confirmation toast displays: "Data exported successfully."
- [ ] Exported JSON includes **all local data**: Restaurants, Visits, UserPreferences, AllergySafeFoods, JournalEntries, VisitLineItems, PhotoAttachments
- [ ] Export does NOT block the app — user can continue using it while choosing destination
- [ ] If export fails (e.g., disk full), error toast: "Could not export your data. Check storage and try again."

### AC-6: Blacklist Clear Option (Must Have)

- [ ] Settings screen includes a "Blacklist" section with a "Clear all blacklisted visits" button
- [ ] Tapping the button shows a confirmation dialog: "Remove all blacklisted visits? This cannot be undone."
- [ ] On confirm, **all Visits with `blacklisted = true` are removed** from the database
- [ ] After clearing, a confirmation toast displays: "Blacklist cleared."
- [ ] If no visits are currently blacklisted, show an informational message: "No blacklisted visits to clear."

### AC-7: Voice and Tone Compliance (Must Have)

- [ ] All UI text follows UX-DR2 voice & tone rules:
  - Short, complete sentences only
  - No exclamation marks anywhere in Settings screen
  - No encouragement/gamification language ("Great choice!", "You're all set!")
  - No system-speak ("Network error", "Operation failed")
  - State indicators are text-only — no icon + text combos for status
- [ ] Export button label: **"Export your data as JSON"** (not "Ready to backup your dining memories!" or similar)

---

## Technical Notes

### Data Model Impact

- **Entity:** `UserPreferences` (Isar collection — S01 AC-3, updated from onboarding)
  - All fields editable via Settings: `allergies[]`, `cuisinePreferences[]`, `ratingScale`, `defaultOccasions[]`
- **Rating scale change logic:**
  - Proportional re-scaling formula: `newRating = round(oldRating * newScale / oldScale)`
  - Example: 4/5 → round(4 × 10 / 5) = 8/10; 3/5 → round(3 × 10 / 5) = 6/10
  - All `Visit` entities must be updated in a single transaction to avoid partial state

### Settings Screen Structure (AD-2 — Bottom Nav, Settings Tab)

```
Settings Tab
├── Allergies
│   ├── [Allergen 1] [Mild] ✏️ 🗑️
│   ├── [Allergen 2] [Severe] ✏️ 🗑️
│   └── + Add allergy...
├── Rating Scale
│   ○ 5-star ★★★★★    ● 10-star ⭐×10
├── Cuisine Preferences
│   [Japanese] [Mexican] [Italian] [+ Add]
├── Default Occasions
│   [Date Night] [Family Dinner] [+ Add]
└── Data & Backup
    ├── Export your data as JSON
    └── Clear all blacklisted visits
```

### Repository Impact

- `UserPreferencesRepository`: update methods for each editable field group
- `VisitRepository`: bulk re-scale ratings (transactional) + bulk delete blacklisted visits

---

## Dependencies

| Dependency | Story | Status |
|------------|-------|--------|
| Isar Schema & Entity Models | S01 | Must be complete before implementation |
| Data Layer — Repository Implementation | S02 | Must be complete before implementation |
| Navigation Shell (Bottom Nav + IndexedStack) | S03 | Must be complete before implementation |
| Onboarding Flow | S04 | Should be complete (Settings is the "configure later" path) |

---

## Testing Notes

- **Unit tests:** Rating scale re-scaling formula — verify edge cases (5→10, 10→5, already on target scale)
- **Widget tests:** Each Settings section — add/remove/edit operations update UI correctly
- **Integration test:** Allergen CRUD → persisted to Isar → survives app restart
- **Integration test:** Rating scale change → all Visits re-scaled → composite scores recalculated
- **Integration test:** JSON export → valid JSON file → contains all expected entities
- **Integration test:** Blacklist clear → zero blacklisted visits remain → toast confirmation shown
- **Voice & tone audit:** All Settings screen text reviewed against UX-DR2 rules

---

## Open Questions

1. Should the rating scale re-scale happen immediately (in-app) or only on next app launch? Immediate is simpler but risks showing intermediate state if a transaction fails mid-way.
2. For JSON export, should it include **all** data or exclude blacklisted visits by default? PRD says "JSON backup of all local data" — implies everything including blacklisted.
3. Should there be an "Import from JSON" option in Settings? Not in FR-16 scope; could be post-MVP.
