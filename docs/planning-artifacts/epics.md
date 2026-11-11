createc---
status: draft
stepsCompleted: []
inputDocuments:
  - _bmad_output/prd-shards/prd-index.md
  - _bmad_output/prd-shards/prd-quick-log.md
  - _bmad_output/prd-shards/prd-allergy.md
  - _bmad_output/prd-shards/prd-journal.md
  - _bmad_output/prd-shards/prd-favorites.md
  - _bmad_output/prd-shards/prd-browse.md
  - _bmad_output/prd-shards/prd-setup.md
  - _bmad_output/prd-shards/prd-data-model.md
  - _bmad_output/prd-shards/prd-post-mvp.md
  - _bmad_output/prd-shards/prd-risks-nfrs.md
  - docs/planning-artifacts/architecture/architecture-Plated4Me-20261107/ARCHITECTURE-SPINE.md
  - docs/planning-artifacts/ux-designs/ux-Plated4Me-2026-11-08/DESIGN.md
  - docs/planning-artifacts/ux-designs/ux-Plated4Me-2026-11-08/EXPERIENCE.md
---

# Plated4Me - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Plated4Me, decomposing the requirements from the PRD shards, UX Design (DESIGN.md + EXPERIENCE.md spine pair), and Architecture decisions into implementable stories.

## Requirements Inventory

### Functional Requirements

**Must Have (M)**
- **FR-1:** Visit logging with voice note, photo, and four slider ratings — core flow completes in ≤30 seconds (M)
- **FR-2:** Manual meal total with tip % and employee/server tracking, plus optional line items (S)
- **FR-3:** Weighted rating system — food 40%, value 30%, service 15%, overall 15% → composite score displayed immediately (M)
- **FR-4:** Return intent flag — binary toggle "Would I come back?" stored with Visit (M)
- **FR-5:** Per-Restaurant allergy-safe foods list — add/remove during visit logging, shown in Restaurant detail (M)
- **FR-6:** Food journal with per-dish impressions — optional expandable section within logging flow (S)
- **FR-7:** Favorites collection auto-surfaced — Restaurant qualifies when ≥2 Visits, avg composite ≥80% of scale max, ≥1 returnIntent=true; manual pin/unpin override always respected (M)
- **FR-8:** Occasion tagging — predefined tags (date night, quick lunch, family dinner, business meal), custom tags allowed, filterable in list views (S)
- **FR-9:** Filterable list view — cards show restaurant name, date, composite score, return intent; filters for cuisine type, rating, occasion, allergy-safe status; results update within one frame (~16ms); default sort most recent first (M)
- **FR-10:** Blacklist / avoid list — toggle during logging or from Visit detail; reason stored with suggested categories; blacklisted visits excluded from favorites computation (S)
- **FR-11:** Full-text search — search bar at top of list view; searches across restaurant name, address, voice transcripts, journal entries, occasion tags, employee names, general notes; results ranked by 9-tier relevance priority; matching text highlighted (M)
- **FR-14:** Onboarding flow — first-run guided setup capturing allergies, cuisine preferences (multi-select ~20 presets + custom), rating scale (5 or 10 star), default occasions; skippable, configurable later in Settings (M)
- **FR-16:** Settings & preferences — allergy management (add/edit/remove allergens with severity), rating scale customization, JSON data export, blacklist clear option (M)
- **FR-17:** Restaurant general notes — editable free-text field at Restaurant level, persists across all Visits, pre-populated during logging, included in full-text search (S)

**Post-MVP (C — Could Have)**
- **FR-18:** Random cuisine suggestion — filterable by cuisine type, indicator for new vs. visited (Release 1.5)
- **FR-19:** Discovery map with fog-of-war — visited restaurants as markers, unvisited areas obscured progressively (Release 2.0)
- **FR-20:** Game layer — achievements, stats dashboard, quest prompts; opt-in feature disabled by default (Release 2.5+)

### Non-Functional Requirements

- **NFR-1:** Platform: Mobile application for iOS and Android via Flutter (Must Have)
- **NFR-2:** Single-user only — no multi-user accounts, sharing, or social features (Must Have)
- **NFR-3:** All data stored locally on device — no cloud sync; JSON export available (Must Have)
- **NFR-4:** Fully offline capable — no server infrastructure required (Must Have)
- **NFR-5:** Logging flow ≤30 seconds from open to save — core fields only, optional sections expandable but never block save (Must Have)
- **NFR-6:** Search latency <200ms for full-text search across local data (Should Have)
- **NFR-7:** App cold start <2 seconds (first launch and subsequent opens) (Should Have)

### Additional Requirements (from Architecture)

- **AD-1:** All persistent data uses Isar (not Hive). Entity models defined with `@IsarCollection`. References handle Visit↔Restaurant joins.
- **AD-2:** Navigation — Bottom nav + full-screen modal. Three tabs (Browse, Favorites, Settings). Quick Log opens as full-screen modal route. Onboarding is separate pre-nav route.
- **AD-3:** State Management — Riverpod `AsyncNotifierProvider` wraps Isar query streams. Providers own all query and mutation logic. UI layer watches providers and reacts.
- **AD-4:** Composite Score — Pure function in domain layer (`lib/domain/`). Weights fixed: food=0.40, value=0.30, service=0.15, overall=0.15. Called by providers before persisting. Re-derived on any input change.
- **AD-5:** Favorites — Computed on-demand from Visit history, not stored as separate entity. Three conditions: ≥2 Visits, avg composite ≥80% of scale max, ≥1 returnIntent=true. Manual pin/unpin always respected.
- **AD-6:** Onboarding — Separate gate route `/onboarding`. Checks `UserPreferences` existence in Isar. Skippable. Completing writes UserPreferences and navigates to main app.
- **AD-7:** Quick Log — Full-screen modal, single scrollable form. No internal screen breaks. Captures restaurant name, address, 4 ratings, return intent, occasion tags, meal total, optional line items, journal entries. Submit persists Visit (auto-creates Restaurant if needed) then pops modal.
- **AD-8:** Error Handling — 2 retries (~500ms each) for transient failures. Recoverable → snack bar. Unrecoverable (db corruption, disk full) → dialog. All failure modes are local.
- **AD-9:** Search — Isar FTS + post-query Dart re-ranking with 9-tier priority model.
- **AD-10:** Restaurant Deduplication — Synchronous lookup by `(name, address)` tuple during Quick Log. Multi-match → disambiguation picker. No match → auto-create.
- **AD-11:** Theme — Light mode only for MVP. Dark mode reserved for post-MVP.
- **AD-12:** Clean Architecture — Four layers: domain, application, infrastructure, presentation. Inner layers never import outer layers. `package:` imports exclusively. All return types explicit. No `print()` statements.
- **AD-13:** Testing — Three-tier strategy: Domain pure functions → unit tests (no framework). Riverpod AsyncNotifiers → integration tests with in-memory Isar. Widgets → widget tests with `flutter_test`. Mock at layer boundaries.
- **AD-14:** Operational Envelope — Single device, no server. No deployment pipeline beyond Flutter app store submission. No environment variables, feature flags, or A/B testing.

### UX Design Requirements

From DESIGN.md + EXPERIENCE.md spine pair:

- **UX-DR1:** Information Architecture — Onboarding → Browse/Home (default) → Log Visit modal → Visit Detail → Restaurant Detail → Settings. Navigation via bottom nav bar with IndexedStack for tab state preservation. Filter/disambiguation sheets as bottom-sheet overlays.
- **UX-DR2:** Voice and Tone — Short, complete sentences. No exclamation marks. No encouragement/gamification language. No system-speak ("Network error", "Operation failed"). State indicators text-only (no icon + text combos for status).
- **UX-DR3:** Visit Card Component — Tap navigates to Visit Detail. Long-press reserved (no-op in MVP). Blacklisted state: grey overlay + dimmed text. Composite score bar fills proportionally from left, visual only, not interactive.
- **UX-DR4:** Rating Slider Component — Drag thumb with real-time composite recalculation as any slider moves. Tap on track jumps thumb. Scale shown as tick marks (user's chosen 5 or 10). Composite updates live, no "Calculate" button needed.
- **UX-DR5:** Filter Controls — Bottom sheet slides up from bottom with dimmed background. Apply closes sheet and updates list in one frame (~16ms). Clear all filters resets. Active filter icon shows dot/badge when any filter active.
- **UX-DR6:** Search Bar — Focus shows keyboard, list updates debounced 200ms. Clear button (X) clears text and dismisses keyboard. No results: "No matches." centered message. Matching text highlighted in results.
- **UX-DR7:** Log Visit Flow — Restaurant ID screen with auto-suggest from previously visited restaurants. Address field conditional (only shown on name collision). New restaurant auto-creates on Continue. Disambiguation picker ≤3 options sorted by most recent visit date.
- **UX-DR8:** Optional Sections Accordion Pattern — Meal total + tip, line items, journal entries, allergy-safe foods, restaurant notes. Each independently expandable/collapsible. Never block save. User can save after ratings and add details later from Visit Detail.
- **UX-DR9:** Media (Photos + Voice Note) — Camera button opens device camera. Gallery picker allows multiple selection. Voice note: long-press to record, release to stop, waveform indicator during recording. Transcription shows "Transcribed" badge; failure → error toast + manual text fallback.
- **UX-DR10:** State Patterns — Cold open empty state with icon/illustration and "No visits yet" message. Empty search: "No matches." centered. Name collision: disambiguation bottom sheet. New restaurant auto-created: seamless transition, no confirmation needed. Voice transcription failure: error toast, does not block save.
- **UX-DR11:** Accessibility Floor — VoiceOver/TalkBack labels on every interactive element with role + state. Dynamic Type honored through typography tokens (legible at largest setting). Reduce Motion skips all animations. Tap targets ≥44pt iOS / ≥48dp Android. Color contrast WCAG AA 4.5:1 ratio in light mode. State indicators paired with text label, never color alone.
- **UX-DR12:** Key User Flows — Flow 1: Log a Visit (≤30s target). Flow 2: Browse & Discover with filters and allergy-safe check. Flow 3: First-Run Onboarding (<2 min target). Flow 4: Review a Past Visit via search. Each flow has defined climax moment and failure path.
- **UX-DR13:** Banned Interactions in MVP — No carousels, hero animations, badge counts on list items, pull-to-refresh (unnecessary for local data), haptic feedback patterns that mimic gamification. No swipe gestures, no long-press custom actions, no pinch-to-zoom.

### FR Coverage Map

| Epic | FRs Covered |
|------|-------------|
| Epic 1: Foundation & Setup | FR-14, FR-16, AD-6, AD-11, NFR-1, NFR-2, NFR-3, NFR-4 |
| Epic 2: Core Visit Logging | FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, AD-7, AD-8, AD-10, NFR-5 |
| Epic 3: Browse & Discover | FR-9, FR-11, FR-17, AD-9, NFR-6 |
| Epic 4: Favorites & Organization | FR-7, FR-8, FR-10, AD-5 |
| Epic 5: UX Polish & Accessibility | UX-DR1 through UX-DR13, NFR-7 |

## Epics

### Epic 1: Foundation & Setup

**Goal:** Establish the data layer, navigation shell, and first-run onboarding experience. Everything else depends on this foundation.

| ID | Title | Priority | Key Dependencies |
|----|-------|----------|-----------------|
| E1 | Isar Schema & Entity Models | P0 | None |
| E2 | Data Layer — Repository Implementation | P0 | E1 |
| E3 | Navigation Shell (Bottom Nav + IndexedStack) | P0 | E2 |
| E4 | Onboarding Flow | P1 | E3 |
| E5 | Settings & Preferences | P1 | E3, E4 |

### Epic 2: Core Visit Logging

**Goal:** Enable James to log a restaurant visit in ≤30 seconds with ratings, return intent, and optional detail sections. This is the heart of the app.

| ID | Title | Priority | Key Dependencies |
|----|-------|----------|-----------------|
| E6 | Restaurant ID & Deduplication | P0 | E1, E2 |
| E7 | Ratings Screen (4 Sliders + Composite) | P0 | E6 |
| E8 | Optional Sections Accordion | P1 | E7 |
| E9 | Media — Photos & Voice Notes | P2 | E7 |

### Epic 3: Browse & Discover

**Goal:** Let James search, filter, and browse his visit history to make informed dining decisions.

| ID | Title | Priority | Key Dependencies |
|----|-------|----------|-----------------|
| E10 | Filterable Visit Card List | P0 | E2, E7 |
| E11 | Full-Text Search | P0 | E10 |
| E12 | Restaurant Detail View | P1 | E10 |

### Epic 4: Favorites & Organization

**Goal:** Auto-surface favorite restaurants and let James organize visits by occasion or blacklist.

| ID | Title | Priority | Key Dependencies |
|----|-------|----------|-----------------|
| E13 | Favorites Computation & Display | P0 | E7, E10 |
| E14 | Occasion Tagging | P1 | E8 |
| E15 | Blacklist / Avoid List | P1 | E8 |

### Epic 5: UX Polish & Accessibility

**Goal:** Ensure the app is accessible, follows the experience spine consistently, and meets performance targets.

| ID | Title | Priority | Key Dependencies |
|----|-------|----------|-----------------|
| E16 | Accessibility Foundation | P0 | All epics (woven throughout) |
| E17 | UX Refinements & State Patterns | P1 | All epics |
| E18 | Performance — Cold Start <2s | P1 | E3 |

---

## Stories

### Epic 1: Foundation & Setup

#### S01: Isar Schema & Entity Models

**As a** developer, **I want** well-defined Isar entity models for all domain concepts, **so that** the data layer has a consistent schema to work with.

**Acceptance Criteria:**
- AC-1: `Restaurant` collection with fields: `id`, `name`, `address`, `createdAt`, `updatedAt` (AD-1)
- AC-2: `Visit` collection with fields: `id`, `restaurantId`, `foodRating`, `valueRating`, `serviceRating`, `overallRating`, `compositeScore`, `returnIntent`, `occasionTags[]`, `mealTotal`, `tipPercent`, `employeeName`, `generalNotes`, `blacklisted`, `blacklistReason`, `createdAt`, `updatedAt` (AD-1, AD-4)
- AC-3: `UserPreferences` collection with fields: `id`, `allergies[]`, `cuisinePreferences[]`, `ratingScale` (5 or 10), `defaultOccasions[]`, `onboardingComplete` (FR-14, AD-6)
- AC-4: `AllergySafeFood` sub-collection linked to Restaurant (FR-5)
- AC-5: `JournalEntry` sub-collection within Visit with `dishName` and `impressions` (FR-6)
- AC-6: `VisitLineItem` sub-collection within Visit with `dishName` and optional `price` (FR-2)
- AC-7: `PhotoAttachment` sub-collection within Visit with file path and timestamp (UX-DR9)
- AC-8: All models use `@IsarCollection` annotations with proper indexes on name, address, createdAt (AD-1)

**Story Points:** 3

---

#### S02: Data Layer — Repository Implementation

**As a** developer, **I want** repository interfaces implemented over Isar using Riverpod AsyncNotifiers, **so that** all layers interact with data through consistent abstractions.

**Acceptance Criteria:**
- AC-1: `RestaurantRepository` interface with CRUD + lookup by `(name, address)` tuple (AD-10)
- AC-2: `VisitRepository` interface with CRUD + query streams + FTS search wrapper (FR-9, AD-9)
- AC-3: `UserPreferencesRepository` with get/set and existence check for onboarding gate (AD-6)
- AC-4: All repositories wrapped in `AsyncNotifierProvider`s using Riverpod (AD-3)
- AC-5: Error handling: 2 retries (~500ms each) for transient failures; recoverable → snack bar, unrecoverable → dialog (AD-8)
- AC-6: Domain pure function `computeCompositeScore(food, value, service, overall)` with fixed weights 0.40/0.30/0.15/0.15 called before persisting any Visit (AD-4)

**Story Points:** 5

---

#### S03: Navigation Shell (Bottom Nav + IndexedStack)

**As a** developer, **I want** a bottom navigation bar with three tabs and IndexedStack state preservation, **so that** users can switch between Browse, Favorites, and Settings without losing their place.

**Acceptance Criteria:**
- AC-1: Bottom nav bar with three tabs: Browse (default), Favorites, Settings (AD-2)
- AC-2: IndexedStack preserves tab state when switching (UX-DR1)
- AC-3: Quick Log opens as full-screen modal route, not a tab (AD-7)
- AC-4: Onboarding is a separate pre-nav gate route `/onboarding` — shown only if `UserPreferences.onboardingComplete == false` (AD-6)
- AC-5: Back navigation follows platform conventions: iOS swipe-from-left-edge, Android system back button (UX-DR1)
- AC-6: No drawer navigation. Single-column layout with 16px horizontal margins (EXPERIENCE.md Layout)

**Story Points:** 3

---

#### S04: Onboarding Flow

**As a** new user, **I want** a guided first-run setup that captures my allergies, cuisine preferences, rating scale, and default occasions, **so that** the app is personalized from the start.

**Acceptance Criteria:**
- AC-1: Screen 1 — Allergies: "Do you have any food allergies?" Add/remove allergens with severity (Moderate/Severe). Skip button always visible (FR-14)
- AC-2: Screen 2 — Cuisine preferences: Multi-select from ~20 preset chips (Japanese, Mexican, Italian, Chinese, Thai, Indian, American, Mediterranean, French, Korean, Vietnamese, Greek, Turkish, Ethiopian, Brazilian, Lebanese, Spanish, German, Swedish, Indonesian) plus "Custom" chip for free-text entry. Skip button always visible (FR-14)
- AC-3: Screen 3 — Rating scale: Two large tappable cards — ★★★★★ (5-star) or ⭐ × 10 (10-star). Default to 5 if skipped (FR-14)
- AC-4: Screen 4 — Default occasions: Pre-populated chips (Date Night, Family Dinner, Business Lunch, Quick Bite, Celebration, Trying Something New). Can add custom. Skip defaults to all occasions available (FR-14)
- AC-5: Completing onboarding writes `UserPreferences` to Isar and navigates to Browse/Home (AD-6)
- AC-6: Every screen has "Skip for now" — skipped settings use sensible defaults: 5-star scale, no allergies, all occasions available (FR-14)
- AC-7: Target completion time <2 minutes (EXPERIENCE.md Flow 3)

**Story Points:** 5

---

#### S05: Settings & Preferences

**As a** user, **I want** to manage my allergies, rating scale, and data export from Settings, **so that** I can update preferences after onboarding.

**Acceptance Criteria:**
- AC-1: Allergen management screen — add/edit/remove allergens with severity level (FR-16)
- AC-2: Rating scale customization — switch between 5-star and 10-star; existing ratings re-scaled on change (FR-16)
- AC-3: Cuisine preferences — edit presets and custom entries (FR-14, FR-16)
- AC-4: Default occasions — add/remove/edit occasion tags (FR-14, FR-16)
- AC-5: JSON data export — "Export your data as JSON" button opens file picker; user chooses destination; confirmation toast "Data exported successfully." (FR-16, EXPERIENCE.md State Patterns)
- AC-6: Blacklist clear option — bulk remove all blacklisted visits with confirmation (FR-16)
- AC-7: Voice and tone: "Export your data as JSON" not "Ready to backup your dining memories!" (UX-DR2)

**Story Points:** 5

---

### Epic 2: Core Visit Logging

#### S06: Restaurant ID & Deduplication

**As a** user, **I want** to identify a restaurant by name with auto-suggestions and automatic deduplication, **so that** I can start logging quickly without worrying about duplicate entries.

**Acceptance Criteria:**
- AC-1: Name field is required. Auto-suggests previously visited restaurants as user types (UX-DR7)
- AC-2: Address field is conditional — only shown if another restaurant shares the typed name AND has a non-null address (UX-DR7)
- AC-3: New restaurant auto-creates on "Continue"; proceeds to ratings screen seamlessly, no confirmation needed (UX-DR7, UX-DR10)
- AC-4: Name collision shows disambiguation picker bottom sheet with ≤3 options sorted by most recent visit date. Each option shows name + address (if available) (UX-DR7)
- AC-5: Lookup is synchronous by `(name, address)` tuple — no loading state visible to user (AD-10)
- AC-6: Multi-match disambiguation uses the same bottom-sheet pattern as filters (UX-DR1)

**Story Points:** 3

---

#### S07: Ratings Screen (4 Sliders + Composite Score)

**As a** user, **I want** to rate my visit using four weighted sliders with real-time composite score feedback, **so that** I can capture my experience quickly and accurately.

**Acceptance Criteria:**
- AC-1: Four stacked vertical sliders — Food Quality (40%), Value (30%), Service (15%), Overall (15%) (AD-4, EXPERIENCE.md)
- AC-2: Scale matches user's chosen setting (5 or 10), shown as tick marks below each track (FR-14, UX-DR4)
- AC-3: Dragging thumb shows real-time composite score recalculation — no "Calculate" button needed (UX-DR4)
- AC-4: Tap on track jumps thumb to that position (UX-DR4)
- AC-5: Composite score displayed below all sliders in large headline format, updates live (UX-DR4)
- AC-6: Return intent toggle — "Would you come back?" Yes/No pill toggle. Green checkmark for Yes, red X for No (FR-4, DESIGN.md Status Lozenge)
- AC-7: Save button always visible at bottom, enabled when all four ratings have values (EXPERIENCE.md)
- AC-8: VoiceOver/TalkBack labels on every slider announcing "Food Quality, [value] out of [scale]" (UX-DR11)

**Story Points:** 5

---

#### S08: Optional Sections Accordion

**As a** user, **I want** to add optional details like meal total, journal entries, and allergy-safe foods in expandable sections that never block saving, **so that** I can log the essentials quickly and add richness later.

**Acceptance Criteria:**
- AC-1: Five independently expandable/collapsible accordion sections (UX-DR8):
  - Meal total + tip (%), employee/server name, note — FR-2
  - Visit line items — dish name (+ optional price), "Add another" button — FR-2
  - Food journal — dish name + impressions text, "Add another" button — FR-6
  - Allergy-safe foods — add/remove from per-restaurant safe list — FR-5
  - Restaurant notes — pre-populated if restaurant exists; editable — FR-17
- AC-2: User can save immediately after ratings without filling any optional section (NFR-5)
- AC-3: Optional sections are also accessible from Visit Detail View for adding details later (UX-DR8)
- AC-4: Accordion pattern uses `surface-overlay` background tone, no shadows (DESIGN.md Elevation)
- AC-5: Save button is never blocked — always enabled with ratings complete (NFR-5)

**Story Points:** 5

---

#### S09: Media — Photos & Voice Notes

**As a** user, **I want** to attach photos and voice notes to my visit log, **so that** I can capture visual and audio context alongside my written impressions.

**Acceptance Criteria:**
- AC-1: Camera button opens device camera; photo attached to visit (UX-DR9)
- AC-2: Gallery picker allows multiple photo selection (UX-DR9)
- AC-3: Voice note: long-press to record, release to stop, waveform indicator during recording (UX-DR9)
- AC-4: If transcription succeeds, shows "Transcribed" badge on the voice note entry (UX-DR9)
- AC-5: If transcription fails, error toast + manual text entry fallback — does NOT block save (UX-DR9, UX-DR10)
- AC-6: Photos stored as file paths in Isar `PhotoAttachment` sub-collection (S01 AC-7)

**Story Points:** 5

---

### Epic 3: Browse & Discover

#### S10: Filterable Visit Card List

**As a** user, **I want** to browse my visit history as filterable cards showing restaurant name, date, composite score, and return intent, **so that** I can quickly scan past experiences.

**Acceptance Criteria:**
- AC-1: Cards show: restaurant name (headline weight, truncated >40 chars), date (caption, relative "2 days ago" or formatted), composite score bar (accent color fill proportional to score, 3px height at bottom), return intent pill (top-right) (UX-DR3, DESIGN.md Visit Card)
- AC-2: Default sort: most recent first (FR-9)
- AC-3: Filters available via filter icon in header → bottom sheet slides up with dimmed background (UX-DR5)
- AC-4: Filter options: cuisine type, rating range, occasion tag, allergy-safe status (FR-9)
- AC-5: Apply closes sheet and updates list in one frame (~16ms) — local data is instant (FR-9, UX-DR5)
- AC-6: Clear all filters resets to unfiltered view (UX-DR5)
- AC-7: Active filter icon shows dot/badge when any filter is active (UX-DR5)
- AC-8: Blacklisted visits show 40% `ink-disabled` grey overlay + dimmed text; tap still navigates to detail (UX-DR3, DESIGN.md Visit Card)
- AC-9: Tap card navigates to Visit Detail View (UX-DR3)
- AC-10: Cold open empty state: large icon/illustration area, headline "No visits yet", subtext "Tap + to log your first dining experience" (UX-DR10, EXPERIENCE.md State Patterns)

**Story Points:** 5

---

#### S11: Full-Text Search

**As a** user, **I want** to search across all my visit data with relevant results ranked by importance, **so that** I can find specific restaurants, dishes, or notes quickly.

**Acceptance Criteria:**
- AC-1: Search bar at top of list view, always visible (UX-DR6)
- AC-2: Searches across: restaurant name, address, voice transcripts, journal entries, occasion tags, employee names, general notes (FR-11)
- AC-3: Results ranked by 9-tier relevance priority model (AD-9):
  1. Restaurant name exact match
  2. Restaurant name partial match
  3. Address match
  4. Journal entry dish name match
  5. Journal entry impressions match
  6. Voice transcript match
  7. Employee name match
  8. Occasion tag match
  9. General notes match
- AC-4: Matching text highlighted in results (FR-11)
- AC-5: Focus shows keyboard; list updates debounced 200ms (UX-DR6)
- AC-6: Clear button (X) clears text and dismisses keyboard (UX-DR6)
- AC-7: No results: "No matches." centered message — no suggestions offered (UX-DR10, EXPERIENCE.md Voice & Tone)
- AC-8: Search latency <200ms for full local dataset (NFR-6)

**Story Points:** 5

---

#### S12: Restaurant Detail View

**As a** user, **I want** to see a restaurant's complete profile including allergy-safe list, general notes, and visit history, **so that** I can make informed decisions before visiting.

**Acceptance Criteria:**
- AC-1: Restaurant info header: name (headline weight), address (if available) (DESIGN.md Typography)
- AC-2: Allergy-safe foods list — expandable section showing confirmed safe items per visit (FR-5, UX-DR10)
- AC-3: General notes — editable free-text field at Restaurant level, persists across all Visits (FR-17)
- AC-4: Visit history — chronological list of all visits to this restaurant with composite scores (UX-DR3)
- AC-5: Tap restaurant name from Visit Detail navigates here (EXPERIENCE.md IA)
- AC-6: "No visits logged yet" shown in restaurant info area if no visits exist (UX-DR10, EXPERIENCE.md State Patterns)

**Story Points:** 3

---

### Epic 4: Favorites & Organization

#### S13: Favorites Computation & Display

**As a** user, **I want** my favorite restaurants auto-surfaced in the Browse list, **so that** I can quickly see my best dining experiences.

**Acceptance Criteria:**
- AC-1: Restaurant qualifies as favorite when ALL three conditions met (AD-5):
  - ≥2 Visits logged
  - Average composite score ≥80% of scale max
  - ≥1 visit with returnIntent=true
- AC-2: Favorites computed on-demand from Visit history, NOT stored as separate entity (AD-5)
- AC-3: Manual pin/unpin override always respected — pinned restaurants show even if criteria not met; unpinned hidden even if criteria met (FR-7)
- AC-4: Favorites section appears at top of Browse list when auto-surfaced criteria are met (EXPERIENCE.md IA)
- AC-5: Blacklisted visits excluded from favorites computation (FR-10)
- AC-6: Empty favorites state: "Favorites appear here when you have 2+ great visits with a return intent." — informational, not actionable (UX-DR10, EXPERIENCE.md State Patterns)

**Story Points:** 3

---

#### S14: Occasion Tagging

**As a** user, **I want** to tag my visits with occasions like "Date Night" or "Business Lunch," **so that** I can filter by occasion when planning future meals.

**Acceptance Criteria:**
- AC-1: Predefined occasion tags available during logging: Date Night, Quick Lunch, Family Dinner, Business Meal (FR-8)
- AC-2: Custom occasion tags allowed — user can add new ones (FR-8)
- AC-3: Occasion tags shown as chips in Visit Card metadata (DESIGN.md Filter Chip)
- AC-4: Filter by occasion in filter sheet bottom sheet (FR-9, FR-8)
- AC-5: Multiple occasions per visit supported (tag array on Visit entity)

**Story Points:** 3

---

#### S15: Blacklist / Avoid List

**As a** user, **I want** to blacklist bad restaurant visits so they don't pollute my favorites and I remember what to avoid.

**Acceptance Criteria:**
- AC-1: Blacklist toggle available during logging (in optional sections) or from Visit Detail View (FR-10)
- AC-2: Reason stored with suggested categories (Poor Food, Bad Service, Overpriced, Allergy Issue, Other) — FR-10
- AC-3: Blacklisted visits excluded from favorites computation (FR-10, S13 AC-5)
- AC-4: Blacklisted visit cards show 40% `ink-disabled` grey overlay + dimmed text in list views (UX-DR3, DESIGN.md Visit Card)
- AC-5: Blacklist can be cleared in bulk from Settings with confirmation (FR-16)

**Story Points:** 3

---

### Epic 5: UX Polish & Accessibility

#### S16: Accessibility Foundation

**As a** user with accessibility needs, **I want** the app to support screen readers, dynamic text sizing, and reduced motion, **so that** I can use Plated4Me comfortably.

**Acceptance Criteria:**
- AC-1: VoiceOver/TalkBack labels on every interactive element with role + state (UX-DR11)
- AC-2: Dynamic Type honored through typography tokens — UI remains legible at largest accessibility setting without truncation or layout break (UX-DR11, DESIGN.md Typography)
- AC-3: Visit cards may show fewer metadata fields at extreme text sizes but never truncate the restaurant name (EXPERIENCE.md Accessibility)
- AC-4: Reduce Motion skips all animations — state changes shown immediately without transition (UX-DR11)
- AC-5: Tap targets ≥44pt iOS / ≥48dp Android for all interactive elements (UX-DR11)
- AC-6: Color contrast WCAG AA 4.5:1 ratio in light mode for all text against its background (UX-DR11, DESIGN.md)
- AC-7: State indicators paired with text label, never color alone (UX-DR11)

**Story Points:** 5

---

#### S17: UX Refinements & State Patterns

**As a** user, **I want** consistent state handling and voice/tone across every screen, **so that** the app feels polished and predictable.

**Acceptance Criteria:**
- AC-1: Voice and tone rules enforced (UX-DR2):
  - Short, complete sentences only
  - No exclamation marks anywhere in UI text
  - No encouragement/gamification language ("Great job!", "You're on a roll!")
  - No system-speak ("Network error", "Operation failed")
  - State indicators are text-only — no icon + text combos for status (UX-DR2)
- AC-2: All state patterns implemented per EXPERIENCE.md (UX-DR10):
  - Cold open empty state with "No visits yet" message
  - Empty search: "No matches." centered
  - Name collision: disambiguation bottom sheet
  - New restaurant auto-created: seamless transition, no confirmation
  - Voice transcription failure: error toast, does not block save
  - Data export: confirmation toast "Data exported successfully."
- AC-3: Banned interactions enforced in MVP (UX-DR13):
  - No carousels, hero animations, badge counts on list items
  - No pull-to-refresh (unnecessary for local data)
  - No haptic feedback patterns that mimic gamification
  - No swipe gestures, no long-press custom actions, no pinch-to-zoom
- AC-4: Breadcrumb navigation from Visit Detail → Restaurant Detail via restaurant name tap (EXPERIENCE.md IA)

**Story Points:** 3

---

#### S18: Performance — Cold Start <2s

**As a** user, **I want** the app to launch quickly, **so that** I can get to my data without waiting.

**Acceptance Criteria:**
- AC-1: App cold start (first launch and subsequent opens) completes in <2 seconds (NFR-7)
- AC-2: Isar database initialized before first frame renders — no visible loading spinner on Browse/Home
- AC-3: Onboarding gate route `/onboarding` checks `UserPreferences` existence synchronously at startup (AD-6)
- AC-4: No deferred initialization of critical providers — all AsyncNotifiers ready before UI mounts

**Story Points:** 2
