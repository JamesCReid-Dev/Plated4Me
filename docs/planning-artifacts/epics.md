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

## Epic List

<!-- To be populated in Step 2 and Step 3 -->

## Epics

<!-- To be designed in Step 2 -->

## Stories

<!-- To be created in Step 3 -->
