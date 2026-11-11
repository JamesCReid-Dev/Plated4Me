---
title: "S07 — Visit Logging Screen"
created: 2026-11-08
updated: 2026-11-08
status: draft
epic: "Epic 2: Core Visit Logging"
jira_key: ST-007          # pending Jira creation
priority: P0
story_points: 5
realizes: FR-1, FR-3, FR-4
parent_prd_shard: prd-quick-log.md
---

# S07 — Visit Logging Screen

**As a** user, **I want** to log a visit in ≤30 seconds with ratings and optional details, **so that** I can capture my dining experience quickly while it's fresh.

---

## References

| Artifact | Location |
|----------|----------|
| PRD Shard | [`_bmad_output/prd-shards/prd-quick-log.md`](../../prd-shards/prd-quick-log.md) — FR-1, FR-3, FR-4 |
| Epic Breakdown | [`docs/planning-artifacts/epics.md`](../../docs/planning-artifacts/epics.md) — S07 |
| Data Model | [`_bmad_output/prd-shards/prd-data-model.md`](../../prd-shards/prd-data-model.md) — `Visit`, `Restaurant` entities, rating fields |

---

## Acceptance Criteria

### AC-1: Core Logging Flow Completes in ≤30 Seconds (Must Have)

- [ ] From app open to save, the core flow captures: restaurant name, address (conditional), four ratings, and return intent flag
- [ ] Restaurant name is **required** — triggers auto-create if new
- [ ] Address fields are **conditionally required**: only when another restaurant shares the same name; otherwise optional
- [ ] If entered `(name, address)` tuple does not match any existing Restaurant → a new `Restaurant` record is created implicitly with provided name and address (no separate "Add Restaurant" screen)
- [ ] If multiple existing Restaurants share the same name but differ in address → disambiguation picker shown (≤3 options, sorted by most recent visit) before proceeding to ratings
- [ ] If entered restaurant name matches an existing Restaurant that has no address fields filled → user must provide at least one location field (street, city, or state) before proceeding

### AC-2: Four Rating Sliders with Composite Score (Must Have)

- [ ] Four quick slider ratings displayed in a single screen section:
  - **Food quality** — 40% weight
  - **Value for money** — 30% weight
  - **Service quality** — 15% weight
  - **Overall experience** — 15% weight
- [ ] Slider scale matches user's chosen setting from onboarding (5-star or 10-star)
- [ ] Composite score calculated as weighted average and displayed immediately after ratings are entered
- [ ] Individual component scores visible alongside the composite in visit detail and list views
- [ ] Weights fixed at 40/30/15/15 for MVP — stored as constants, not user-configurable

### AC-3: Return Intent Flag (Must Have)

- [ ] Binary toggle presented during logging, labeled "Would I come back?"
- [ ] Toggle options: Yes / No (pill-style selector)
- [ ] Flag stored with the Visit and filterable in list views (S10)

### AC-4: Voice Note Input (Should Have)

- [ ] Microphone button available during logging — tap to record voice note
- [ ] On-device speech-to-text transcription for full-text search
- [ ] If on-device STT unavailable, falls back to manual text entry
- [ ] Voice is optional — user can skip it and enter text notes manually instead

### AC-5: Photo Capture (Should Have)

- [ ] "Add photo" button available during logging
- [ ] Supports camera capture or gallery upload
- [ ] Photos stored with the Visit for future reference

### AC-6: Meal Total, Tip %, Line Items, Employee Tracking (Should Have)

- [ ] User enters a **meal total** (full pre-tip amount) — primary cost capture field
- [ ] User can optionally add individual line items with name and optional price per item
  - Line items exist solely to track specific dishes/drinks for cross-restaurant comparison, NOT as receipt breakdown
  - Line items without a price serve as dish memory only, not cost accounting
  - Meal total is independent of any line items — their prices do not sum to or reconcile with the meal total
- [ ] User enters a **tip percentage (%)** during logging — calculated against the meal total (not including line item prices)
- [ ] User can record an **employee/server name** associated with the visit
- [ ] Free-text note field coupled to employee name (e.g., "great recommendation on wine pairing")

### AC-7: Voice and Tone Compliance (Must Have)

- [ ] All UI text follows UX-DR2 voice & tone rules:
  - Section headers: neutral labels ("Ratings", "Return Intent?", "Meal Details")
  - Slider labels: short, descriptive ("Food quality", not "How was the food?")
  - Return intent toggle: "Would I come back?" — clear question format
  - No exclamation marks, no gamification language

---

## Technical Notes

### Data Model Impact

- **Visit entity** fields used: `restaurantId`, `mealTotal`, `tipPercent`, `lineItems[]`, `employeeName`, `employeeNote`, `foodQuality`, `valueForMoney`, `serviceQuality`, `overallExperience`, `returnIntent`, `voiceTranscript`, `photoUrls`
- **Restaurant entity** auto-created during logging if `(name, address)` tuple not found

### Repository Impact

- **`VisitRepository`** needs:
  - `Future<void> createVisit(Visit visit)` — creates a new visit with all fields
- **`RestaurantRepository`** needs:
  - `Future<Restaurant?> lookupByNameAddress(String name, String? address)` — finds existing restaurant by (name, address) tuple
  - `Future<List<Restaurant>> searchByName(String name)` — returns up to 3 most recent matches for disambiguation picker
  - `Future<String> createOrGetRestaurant(String name, {String? street, String? city, String? state})` — creates new restaurant if not found; returns ID

### UI Component Requirements

- **VisitLoggingScreen** — single-page form with the following sections:
  1. Restaurant lookup (name input + optional address fields)
  2. Disambiguation picker (if multiple matches)
  3. Rating sliders (4 sliders in a grid or vertical stack)
  4. Return intent toggle
  5. Meal details section (meal total, tip %, line items, employee info) — expandable/collapsible
  6. Voice note button + photo capture button
- **RatingSlider widget** — reusable slider component with label, current value display, and scale matching user's chosen setting
- **CompositeScoreDisplay widget** — shows weighted composite score + individual component scores below it
- **DisambiguationPicker widget** — ≤3 options sorted by most recent visit, tap to select

### Provider Impact

- **VisitLoggingProvider** (AsyncNotifier) — manages form state, handles restaurant lookup/creation logic, computes composite score in real-time as sliders change

---

## Dependencies

| Dependency | Story | Status |
|------------|-------|--------|
| Isar Schema & Entity Models | S01 | Must be complete (`Visit`, `Restaurant` entities with all rating/cost fields) |
| Data Layer — Repository Implementation | S02 | Must be complete (repository methods for visit/restaurant CRUD + lookup) |
| Navigation Shell (Bottom Nav + IndexedStack) | S03 | Must be complete |
| Onboarding Flow | S04 | Should be complete (user's chosen rating scale needed for slider display) |

---

## Testing Notes

- **Widget tests:** Rating sliders — all 4 sliders render correctly, values update in real-time, composite score recalculates on any change
- **Widget tests:** Disambiguation picker — shows ≤3 options sorted by most recent visit, selection works
- **Widget tests:** Return intent toggle — Yes/No pill selector, value persists through form navigation
- **Integration test:** Log visit to new restaurant → verify Restaurant auto-created + Visit saved with all fields
- **Integration test:** Log visit to existing restaurant (name match) → disambiguation picker shown → correct restaurant selected → Visit saved

---

## Open Questions

1. For the meal details section: should it be always visible or collapsible? The PRD says line items are "optional expandable" — I'm making the entire meal details section collapsible to keep the core ≤30-second path minimal (just name, ratings, return intent).
2. For voice note fallback: if on-device STT is unavailable, should we show a text input field immediately or just hide the microphone button and let the user add notes elsewhere? Leaning toward showing a text input field as an alternative to the mic button.
