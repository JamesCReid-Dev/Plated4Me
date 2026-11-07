---
title: Plated4Me
created: 2026-11-06
updated: 2026-11-08
status: final — post-review decisions applied (C1–S4 resolved)
---

# PRD: Plated4Me

*Personal restaurant visit log — mobile app built in Flutter.*

## 0. Document Purpose

This PRD defines the requirements for **Plated4Me**, a personal mobile application for logging and reviewing restaurant/food experiences. It is intended for the sole stakeholder (the product owner, James Reid) and serves as the canonical input for downstream UX design, architecture, and sprint planning. The document uses Glossary-anchored vocabulary — every domain noun appears in §3 and is used consistently throughout. Features are grouped with Functional Requirements nested beneath them; FRs use globally stable IDs (FR-1 through FR-20) so downstream artifacts have unambiguous references. Inline `[ASSUMPTION: …]` tags mark inferences the author made without direct confirmation; all such assumptions are indexed in §9 for explicit review.

**Post-review decisions (2026-11-08):** Composite score weights reverted to 40/30/30 (§C1). Original v3.0 cost model restored — manual meal total + tip % + employee/server tracking (§C2). Service quality added as fourth rating dimension at 15% weight (40/30/15/15) (§C3/OQ-10). Value-for-money retained in composite at 30% (§C3/OQ-9). GPS/location auto-population deferred to post-MVP (§C3/OQ-11). Restaurant identity simplified to `(name, address)` tuple (§S2). Blacklist moved from per-Restaurant to per-Visit (§S4). Feature IDs renumbered from original v3.0 scheme (FR-12/13/15 removed during consolidation — see §4 preamble); all downstream references updated.

---

## 1. Vision

Plated4Me is a personal mobile app that helps you make better dining decisions by maintaining a verified, private record of your past restaurant visits. When you open it before walking into a new or returning establishment, you should be able to decide within 10 seconds — confidently walk in because your own data supports it, or choose elsewhere to avoid repeating a bad experience.

Online reviews are unreliable and staff knowledge about food allergies is inconsistent. The emotional pain of being "ripped off" on portion size, quality, or price is real and repeatable. Plated4Me solves this by putting **your** verified record front and center — no noise, no social features, no algorithmic opinions. Just your own data, organized and searchable, in under 30 seconds from open to save.

This is a single-user, fully offline product. No cloud sync, no accounts, no server infrastructure. The app lives on your device and belongs entirely to you.

---

## 2. Target User

### 2.1 Jobs To Be Done

- **Before I go out to eat:** "Show me what happened the last time I was here — was the food good? Were portions worth the price? Would I come back?"
- **While I'm at the restaurant:** "I need to log this experience quickly before I forget, without spending 10 minutes filling out forms."
- **When planning a specific occasion:** "Where's a place for a date night / family dinner / business meal that was actually good?"
- **Managing food allergies:** "What foods have I confirmed are safe for me to eat at this restaurant?"

### 2.2 Non-Users (v1)

- Groups dining out together (no multi-user or sharing features)
- People looking for restaurant discovery from scratch (no Yelp-like browsing of unvisited places in v1)
- Anyone needing cross-device data access (fully offline, single device only)

### 2.3 Key User Journeys

**UJ-1. James logs a visit right after eating.**
> James finishes lunch at a new ramen shop he's never been to before. He opens Plated4Me while walking back to his office. The app shows a "Log Visit" screen. He types "Ichiran Ramen, 123 Main St" — the app creates the restaurant implicitly since it doesn't exist yet. He slides four bars: food quality 4/5, value for money 3/5, service quality 4/5, overall 4/5. The composite score (3.7) appears instantly. He toggles "Would I come back?" to Yes. He taps "Add photo" and snaps a picture of his bowl. He saves. Total time: ~20 seconds.
> **Edge case:** If another "Ichiran Ramen" exists at a different address in his database, the app shows a disambiguation picker (≤3 options, sorted by most recent visit) before he proceeds to ratings.

**UJ-2. James decides where to eat using search and filters.**
> It's Thursday evening. James opens Plated4Me — the Favorites list is his default landing view since no recent visits exist. He sees "Thai Basil" (4.6 avg, marked favorite). But he's in the mood for something specific. He taps the filter icon, selects "Japanese," then "Date Night" occasion, then sorts by rating. The top result is "Sakura Sushi" with a 4.8 composite and a return-intent checkmark. He walks in confident.
> **Edge case:** If no results match his filters, the app shows an empty state with a suggestion to relax one filter or browse all history.

**UJ-3. James sets up Plated4Me on first launch.**
> James downloads and opens Plated4Me for the first time. An onboarding flow guides him through: he enters "peanuts" and "shellfish" as allergens (severity: Severe), selects preferred cuisines (Italian, Japanese, Thai, Mexican from a multi-select list), chooses a 1–5 star rating scale, and accepts the default occasion tags ("date night," "quick lunch," "family dinner"). He can skip any step and configure later in Settings. One-time flow — done in under 2 minutes.

---

## 3. Glossary

- **Allergy-Safe Database** — Per-Restaurant list of foods confirmed safe for the user to consume, updated over time as the user visits and verifies.
- **Blacklist** — User-curated list of places they never want to return to, with reasons stored (bad experience, allergy reaction, poor value, overpriced). Blacklisted places are excluded from suggestions.
- **Composite Score** — Weighted rating for a Visit, calculated as: food quality × 40% + value for money × 30% + service quality × 15% + overall experience × 15%. Expressed on the user's chosen scale (5-star or 10-star).
- **Favorites Collection** — Auto-surfaced list of highly-rated restaurants grouped by cuisine type or occasion, plus any manually pinned entries. Serves as the default landing view when no recent visits exist.
- **Food Journal** — Per-Visit log of individual dishes ordered, with free-text impressions (e.g., "great at first, soggy by bite 5").
- **Occasion Tag** — Context label applied to a Visit (date night, quick lunch, family dinner, business meal). Predefined tags available; user can create custom tags.
- **Restaurant** — A dining establishment identified uniquely by the `(name, address)` tuple. Two entries with the same name but different addresses are distinct Restaurants. A Restaurant has many Visits and one Allergy-Safe Database.
- **Visit** — A single dining experience at a Restaurant, logged as one entry containing ratings (food quality, value for money, service quality, overall experience), composite score, return intent flag, optional voice notes, photos, journal entries, line items, meal total, tip %, employee/server info, and blacklist status.
- **VisitItem** — An individual line item within a Visit (e.g., "Margherita Pizza" at $14.50), representing a specific dish or drink ordered.

---

## 4. Features

Functional Requirements are grouped by capability area. FR IDs are globally stable (FR-1 through FR-20); gaps in numbering (FR-12, FR-13, FR-15) reflect features removed during post-review consolidation from the original v3.0 scheme — no functionality was lost, only reorganized. All downstream references use the current IDs.

### 4.1 Quick Visit Logging

Core logging flow that captures the essential data about a dining experience in ≤30 seconds. This is the heart of Plated4Me — everything else builds on well-captured visit data. Realizes UJ-1. `[ASSUMPTION: The user logs visits immediately after eating, while walking out of the restaurant, when impressions are freshest.]`

**Functional Requirements:**

#### FR-1: Visit logging with voice, photo, ratings (Must Have)
Realizes US-1, UJ-1.

**Consequences (testable):**
- Core flow completes in ≤30 seconds from app open to save, capturing: restaurant name, address, composite rating (four sliders), and return intent flag
- Supports voice note input with speech-to-text transcription for full-text search; voice is optional — user can skip it and enter text notes manually instead `[ASSUMPTION: On-device speech-to-text API (e.g., iOS Speech Framework or Android SpeechRecognizer) provides acceptable accuracy in typical restaurant ambient noise; if unavailable, falls back to manual text entry]`
- Photo capture from camera or upload from gallery
- Four quick slider ratings: food quality, value for money, service quality, overall experience (on user's chosen scale — 5-star or 10-star, set during onboarding)
- If the entered `(name, address)` tuple does not match any existing Restaurant, a new Restaurant record is created implicitly with the provided name and address — no separate "Add Restaurant" screen (resolves OQ-7)
- If multiple existing Restaurants share the same name but differ in address, the user sees a disambiguation picker (≤3 options, sorted by most recent visit) before proceeding to rating fields (resolves OQ-6)
- If the entered restaurant name matches an existing Restaurant that has no address fields filled, the user must provide at least one location field (street, city, or state) before proceeding — name-only matching against null-address entries is not permitted

**Required / Optional Fields:**

| Field | Required? | Notes |
|---|---|---|
| Restaurant name | **Required** | At minimum — triggers auto-create if new |
| Address (any location field) | **Conditional required** | Required only if another restaurant shares the same name; otherwise optional |
| Food quality rating | **Required** | Part of composite score; no valid visit without it |
| Value for money rating | **Required** | Part of composite score; no valid visit without it |
| Service quality rating | **Required** | Part of composite score; no valid visit without it |
| Overall experience rating | **Required** | Part of composite score; no valid visit without it |
| Return intent flag | **Required** | Core decision signal ("would I come back?") |
| Voice note | Optional | Can skip or enter text manually |
| Photo(s) | Optional | Tap to capture or skip |

**Out of Scope:**
- Voice transcription on a server — all processing is on-device during MVP
- Automatic restaurant detection from GPS or camera

#### FR-2: Manual meal total with tip % and employee/server tracking (Should Have)
Realizes US-2.

**Consequences (testable):**
- User enters a single **meal total** (the full pre-tip amount for the dining experience) during visit logging — this is the primary cost capture, not derived from line items
- User can optionally add individual line items with name and an **optional price** per item — line items exist solely to track specific dishes or drinks the user wants to compare across restaurants (e.g., "hamburger at this place vs. that place"), NOT as a receipt breakdown; the meal total is independent of any line items
- Line items without a price serve as dish memory only, not cost accounting
- User enters a **tip percentage (%)** during visit logging — calculated against the meal total (not including line item prices)
- User can record an **employee/server name** associated with the visit
- A free-text **note field** is coupled to the employee name (e.g., "great recommendation on wine pairing")
- Tip % and employee info are stored per visit for future service-quality analysis

**Notes:**
- The meal total represents the full pre-tip bill. Line items are completely independent — their prices do not sum to or reconcile with the meal total in any way. A user might log "$45" as the meal total and only track two items: "Steak $28" and "Cabernet $14" because those are the dishes they want to remember and compare elsewhere.
- Line items are an *optional expandable section* within the logging flow — not part of the core ≤30-second path. User taps "Add items" to expand; if skipped, only the composite ratings and return intent are captured.
- Restaurant general notes (if any exist for the selected restaurant) appear as an expandable **"Restaurant Notes"** section in the logging form, pre-populated with existing notes. The user can edit or clear them during logging. General notes persist at the Restaurant level across all visits and are included in full-text search results.

#### FR-3: Weighted rating system (Must Have)
Realizes US-3, OQ-9, OQ-10.

**Consequences (testable):**
- Four rating inputs accepted: food quality (40% weight), value for money (30% weight), service quality (15% weight), overall experience (15% weight)
- Composite score calculated as weighted average and displayed immediately after ratings are entered
- Individual component scores visible alongside the composite in visit detail and list views

**Notes:**
- Weights are fixed at 40/30/15/15 for MVP, stored as constants (not user-configurable) with a clear path to make them configurable if usage data shows demand.
- Service quality (OQ-10) complements the employee/server name + note fields in FR-2 by providing a numeric rating dimension; employee info is still captured as free-text for contextual detail.
- Value-for-money remains in the composite at 30% (OQ-9 resolved): it serves dual purpose as both a cost-quality signal and a component of the overall composite score. Cost tracking data (meal total, tip %, line items) provides additional granularity for value analysis beyond the composite rating.

#### FR-17: Restaurant general notes (Should Have)
Realizes US-3.

**Consequences (testable):**
- Each Restaurant has an editable general notes field (free-text) that persists across all Visits
- Notes are stored at the Restaurant level and visible from both the Restaurant detail view and any associated Visit
- During visit logging, existing restaurant notes appear as a pre-populated expandable section the user can edit or clear
- General notes are included in full-text search results (FR-11)

**Notes:**
- This is a standalone feature restored from original v3.0 US-3/FR-3, which was absorbed into FR-2 during BMAD reformatting. Persistent restaurant-level notes differ from per-visit journal entries (FR-6): restaurant notes capture enduring information ("best patio seating in summer," "call ahead on weekends") that applies to the establishment as a whole, not just one visit.

#### FR-4: Return intent flag (Must Have)
Realizes US-4.

**Consequences (testable):**
- Binary toggle (yes/no) presented during visit logging, labeled "Would I come back?"
- Flag stored with the Visit and filterable in list views

---

### 4.2 Allergy Management

#### FR-5: Allergy-safe database per Restaurant (Must Have)
Realizes US-5.

**Consequences (testable):**
- Per-Restaurant safe foods list maintained separately from individual Visits
- User can add or remove items from the safe foods list during visit logging
- Safe foods indicator shown in Restaurant detail view (count of confirmed safe foods, with ability to expand and view the full list)

**Notes:**
- Severity levels for allergens are tracked at the User level (UserAllergen entity), not per-Restaurant. The Allergy-Safe Database stores only food names — severity context lives in Settings.

---

### 4.3 Food Journal

#### FR-6: Food journal with impressions (Should Have)
Realizes US-6.

**Consequences (testable):**
- User can create per-Visit journal entries, each with a dish name and free-text impressions describing the experience over time (e.g., "amazing crust at first, got chewy by bite 5")
- Journal entries are an *optional expandable section* within the logging flow — not part of the core ≤30-second path

**Notes:**
- Optional per-dish rating is deferred; journal notes are free-text only in MVP.

---

### 4.4 Favorites & Occasions

#### FR-7: Favorites collection auto-surfaced (Must Have)
Realizes US-7.

**Consequences (testable):**
- Auto-detection rule: a Restaurant is automatically added to Favorites when it meets **all three** conditions across its Visit history:
  - At least **2 Visits** logged, AND
  - Average composite score ≥ **80% of the chosen scale maximum** (i.e., ≥4.0 on a 5-star scale, or ≥8.0 on a 10-star scale), AND
  - `returnIntent = true` on at least **1 of those Visits**
- When the user changes their rating scale in Settings, all existing composite scores are re-derived and auto-detection rules re-run; restaurants that cross the threshold are automatically added to or removed from Favorites (manual pins always take precedence over auto-detection)
- Manual override: user can pin/unpin any Restaurant as a favorite at any time (from Restaurant detail view or list card). Manual pins are always respected regardless of auto-detection score.
- Favorites grouped by cuisine type or occasion for easy browsing
- Favorites list is the default landing view when the user opens the app and no recent Visits exist

#### FR-8: Occasion tagging (Should Have)
Realizes US-8.

**Consequences (testable):**
- Predefined occasion tags available during visit logging ("date night," "quick lunch," "family dinner," "business meal")
- User can add custom occasion tags at any time
- Visits filterable by occasion tag in list views

---

### 4.5 Browse & Discover

#### FR-9: Filterable list view (Must Have)
Realizes US-9, UJ-2.

**Consequences (testable):**
- List view displays Visits as cards with key info: Restaurant name, date, composite score, return intent flag
- Filter controls for: cuisine type, price range, rating, occasion, allergy-safe status. Cost-related filters (tip %, meal total range) are excluded from MVP — they require additional UI complexity and are not core to the dining decision use case.
- Results update within one frame (~16ms) of filter change
- Default sort: most recent first

#### FR-10: Blacklist / avoid list (Should Have)
Realizes US-11.

**Consequences (testable):**
- Blacklist toggle available during visit logging and from Visit detail view
- Reason for blacklisting stored and displayed (free text with suggested categories: bad experience, allergy reaction, poor value, overpriced)
- Blacklisted visits excluded from favorites auto-detection computation (blacklisting a visit does not blacklist the entire Restaurant; the Restaurant remains browsable and can still be revisited); also excluded from random suggestions (FR-18, post-MVP)

#### FR-11: Full-text search (Must Have)
Realizes US-13.

**Consequences (testable):**
- Search bar at top of list view
- Searches across: Restaurant name, address, voice note transcripts, journal dish names, journal notes, occasion tags, employee/server names, restaurant general notes
- Results ranked by relevance (most relevant first); simple full-text matching with field weighting (Restaurant name weighted higher than notes) — BM25 or equivalent if library permits, otherwise basic term frequency `[ASSUMPTION: The expected data volume (<500 Restaurants, <2000 Visits) is small enough that even basic term-frequency search feels instant on a modern smartphone]`
- Relevance model (highest to lowest priority): exact restaurant name match > partial name + address match > employee/server name match > journal dish name match > voice transcript / journal note match > restaurant general notes match > occasion tag match > general visit notes match. Field weights are fixed for MVP; tuning if needed is deferred based on usage data.
- Search highlights matching text in results

---

### 4.6 Setup & Configuration

#### FR-14: Onboarding flow (Must Have)
Realizes US-14, UJ-3.

**Consequences (testable):**
- First-run onboarding screen with guided setup capturing: food allergies (optional but encouraged), preferred cuisine types (multi-select from a list of ~20 common presets with free-text option for others), rating scale preference (1–5 or 1–10 stars), default occasion tags
- User can skip any step and configure later in Settings
- Onboarding is a one-time flow; settings can be updated anytime

#### FR-16: Settings & preferences (Must Have)
Realizes US-16.

**Consequences (testable):**
- Allergy management: add/edit/remove personal food allergens with severity levels (Mild, Moderate, Severe)
- Rating scale customization: choose 1–5 or 1–10 stars for individual ratings
- Distance threshold for discovery map (configurable in meters/kilometers; post-MVP but configurable now)
- Data export option: JSON backup of all local data to a shareable file
- Clear blacklist entries option

---

### 4.7 Post-MVP Features (Deferred)

#### FR-18: Random cuisine suggestion (Could Have — Release 1.5)
Realizes US-10.

**Consequences (testable):**
- "Random Suggestion" button/feature available from the main browse view
- Filterable by cuisine type before generating suggestion
- Indicator showing whether the suggested Restaurant is new (never visited) or already in the user's history

#### FR-19: Discovery map with fog-of-war (Could Have — Release 2.0)
Realizes US-11. `[ASSUMPTION: The user will want to enable location services on their device for this feature; it is opt-in and not required for core functionality.]`

**Consequences (testable):**
- Map view displays visited Restaurants with markers
- Fog-of-war effect: unvisited areas remain obscured
- Areas clear progressively as the user visits more locations
- Configurable threshold distance for city/country boundaries (Settings)

#### FR-20: Game layer — achievements, stats, quests (Could Have — Release 2.5+)
Realizes US-12.

**Consequences (testable):**
- Achievement badges (e.g., "Food Explorer" for 10 cuisine types, "Value Hunter" for great portion-to-price ratios)
- Stats dashboard showing visit counts, average ratings, favorite cuisines
- Quest prompts suggesting new experiences
- **Opt-in feature** — user enables in Settings; default is disabled

---

## 5. Non-Goals (Explicit)

The following are explicitly out of scope for Plated4Me v1:

- Multi-user accounts or collaborative features — this is a personal log, not a social platform
- Social sharing of reviews (no Yelp, no public profiles, no export to review sites)
- Integration with restaurant reservation systems (OpenTable, Resy, etc.)
- Automated price scraping from menus
- AI-generated review summaries
- Location-based notifications (not in v1; GPS is not used during MVP)
- Cloud sync or cross-device data transfer (fully offline, single device only)
- Web version or desktop app (mobile only)

`[NON-GOAL for MVP]` Discovery map — deferred to Release 2.0 due to geo-data infrastructure complexity.
`[NON-GOAL for MVP]` Random cuisine suggestions — deferred to Release 1.5; requires sufficient visit data to be useful.
`[NON-GOAL for MVP]` Gamification (achievements, stats, quests) — deferred to Release 2.5+; engagement features are not core to the value proposition.

---

## 6. MVP Scope

### 6.1 In Scope (Release 1.0)

- Quick Visit Logging with voice, photo, and slider ratings (FR-1)
- Manual meal total with tip % and employee/server tracking; optional line items (FR-2)
- Restaurant general notes — persistent across visits, included in search (FR-17)
- Weighted rating system — four dimensions: food 40%, value 30%, service 15%, overall 15% (FR-3)
- Return intent flag (FR-4)
- Allergy-safe database per Restaurant (FR-5)
- Food journal with free-text impressions (FR-6)
- Favorites collection with auto-detection and manual override (FR-7)
- Occasion tagging — predefined + custom (FR-8)
- Filterable list view with real-time filter updates (FR-9)
- Blacklist / avoid list (FR-10)
- Onboarding flow for first-run setup (FR-14)
- Full-text search across all text content (FR-11)
- Settings & preferences including data export (FR-16)

**MVP Definition of Done:** User can go from zero to logging their first Visit, then searching and filtering past Visits to make a dining decision. No map, no random suggestions, no gamification — just reliable personal records.

### 6.2 Out of Scope for MVP

| Item | Deferred To | Reason |
|------|-------------|--------|
| Random cuisine suggestion | Release 1.5 | Needs sufficient visit data to be useful; light-weight to add later |
| Discovery map with fog-of-war | Release 2.0 | Requires geo-data infrastructure; higher complexity |
| Game layer (achievements, stats) | Release 2.5+ | Engagement feature; not core to value proposition |

---

## 7. Success Metrics

*Measured periodically by the product owner to decide whether to keep investing in Plated4Me.*

**Primary**
- **SM-1: Weekly active logging rate** — % of weeks where the user logs ≥1 Visit. Target: ≥60% of weeks in the first 8 weeks after onboarding. Validates FR-1, FR-9. *Counter-metric SM-C1:* Do not optimize for total Visit count at the expense of data quality (e.g., logging visits with empty journal entries just to inflate numbers).

**Secondary**
- **SM-2: Time-to-decision** — Average time from opening the app to making a dining decision (logging or looking up past Visits). Target: ≤10 seconds. Validates FR-9, FR-11.
- **SM-3: Onboarding completion rate** — % of first-time users who complete the full onboarding flow vs. skipping. Target: ≥80% complete all steps. Validates FR-14.

---

## 8. Non-Functional Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| NFR-1 | Platform: Mobile application for iOS and Android | Must Have | Flutter framework (decision resolved) |
| NFR-2 | Single-user only | Must Have | No multi-user accounts, sharing, or social features |
| NFR-3 | All data stored locally on device | Must Have | No cloud sync; fully offline |
| NFR-4 | Fully offline capable | Must Have | No server infrastructure required |
| NFR-5 | Logging flow ≤30 seconds from open to save | Must Have | Core fields only: name, address, four ratings, return intent; optional sections (meal total, tip, employee info, line items, journal) expandable but never block save |
| NFR-6 | Search latency <200ms for full-text search across local data | Should Have | Must feel instant on target device |
| NFR-7 | App cold start <2 seconds (first launch and subsequent opens) | Should Have | Measured from app icon tap to first visible screen |

---

## 9. Constraints

| ID | Constraint | Notes |
|----|------------|-------|
| C1 | Mobile application only (iOS + Android via Flutter) | Platform decision resolved; no web or desktop in v1 |
| C2 | Single-user only — no multi-user accounts, sharing, or social features | Architectural simplification: no auth, no user management |
| C3 | All data stored locally on the user's device | No cloud sync in v1; JSON export available for backup (FR-16) |
| C4 | Logging must take under 30 seconds to complete | Drives UX design: core fields first, optional sections expandable |
| C5 | No server infrastructure required — fully offline capable | Voice transcription uses on-device APIs only during MVP; GPS/location services deferred to post-MVP (OQ-11) |

---

## 10. Risks & Mitigations

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|------------|------------|
| R1 | Voice transcription fails or is inaccurate in noisy restaurant environments | High | Medium | Make voice optional; allow text-only logging as fallback. If transcription fails, user can still add manual notes. |
| R2 | Data loss — fully offline means no backup if device is lost or app is uninstalled | High | Low-Medium | Provide JSON data export in Settings (FR-16). Encourage periodic backup during onboarding. |
| R3 | Logging flow exceeds 30 seconds due to UI complexity | Medium | Medium | Timebox MVP logging screens. Use progressive disclosure: show only essential fields first, advanced options expandable. |
| R4 | Hive schema migration issues as data model evolves | Medium | Medium | Version the data schema explicitly. Test migrations with sample data before each release. |
| R5 | User abandons app after a few visits because logging feels like a chore | High | Medium | Keep MVP logging minimal (name, rating, return intent). Defer itemized costs and journal to expandable sections. Four-rating dimensions (food, value, service, overall) kept as compact sliders — no free-text rating fields. |
| R6 | Discovery map performance degrades with many locations | Low-Medium | Low | Defer to v2.0; implement lazy loading for markers if needed. |
| R7 | Logging complexity exceeds 30-second target due to accumulated optional fields (meal total, tip %, employee info, voice notes, photos) | High | Medium | Progressive disclosure: collapsible sections for FR-2 (line items, meal total, tip, employee), FR-5 (allergy-safe foods), FR-6 (journal). "Quick log" mode captures only required fields (name, four ratings, return intent) in ≤10 seconds. Optional sections expandable but never block the save action. |
| R8 | Four rating dimensions add cognitive load vs. original three | Medium | Low-Medium | Service quality (OQ-10) is intuitive for dining (staff attentiveness, accuracy of order). Sliders are compact and fast; pilot-test with 3–5 users to confirm ≤30s target still holds with four sliders instead of three. |

---

## 11. Open Questions

| # | Question | Status | Answer |
|---|----------|--------|--------|
| ~~OQ-1~~ | ~~Should the allergy-safe database include severity levels (mild vs. severe reactions)?~~ | **Resolved** | Not needed — single severity flag is sufficient for this use case |
| OQ-2 | What is the preferred local storage backend for Flutter? | **Resolved** | Use HIVE |
| OQ-3 | Should voice notes be transcribed to text for searchability, or stored as audio only? | **Resolved** | Yes — speech-to-text transcription enabled for full-text search |
| OQ-4 | How should the discovery map handle places in different cities or countries? | **✅ Resolved** | Use a threshold distance based on location, configurable via settings feature. |
| ~~OQ-5~~ | ~~Should the game layer be enabled by default or opt-in?~~ | **Resolved** | Opt-in — user enables in Settings (default: disabled) |
| OQ-6 | Should the app support multiple restaurants with the same name at different addresses? | **✅ Resolved** | Yes — restaurant uniqueness is `(name, address)` tuple. Two "Starbucks" on different streets are distinct restaurants. Architecture must deduplicate by this tuple during lookup; if only `name` matches but `address` differs, present both to the user for disambiguation. |
| OQ-7 | What happens if a user wants to log a visit to a restaurant not yet in their database? | **✅ Resolved** | Logging auto-creates the Restaurant. The ≤30-second logging constraint (§NFR-5) means there is no separate "Add Restaurant" screen. During the visit logging flow, if the entered `(name, address)` tuple does not match any existing Restaurant, a new record is created implicitly with the provided name and address. |
| OQ-8 | Should ratings be configurable per release (e.g., different weights for food vs. value for money)? | **✅ Resolved** | Fixed 40/30/15/15 for MVP (food quality, value for money, service quality, overall experience); weights stored as constants (not user-configurable) with a clear path to make them configurable if usage data shows demand. |
| OQ-9 | Should "value for money" remain in the composite score, or be decoupled since FR-2 tracks cost data separately? | **✅ Resolved** | Value-for-money retained at 30% in composite (FR-3). Serves dual purpose: composite scoring component + quick value signal. Cost tracking data (meal total, tip %, line items) provides additional granularity for deeper value analysis beyond the composite rating. |
| OQ-10 | Should "service quality" be added as a fourth rating dimension? | **✅ Resolved** | Added as fourth slider at 15% weight in FR-3 (40/30/15/15). Complements employee/server name + note fields in FR-2 — numeric rating for quick scoring, free-text for contextual detail (e.g., "server forgot our drinks," "excellent wine pairing recommendation"). |
| OQ-11 | How should GPS auto-population interact with location permissions? | **Deferred to post-MVP** | GPS coordinates (`gpsLatitude`/`gpsLongitude`) removed from v1 data model. Restaurant identity uses `(name, address)` tuple only (S2 resolved). Location services may be added in post-MVP for discovery map (FR-11 / Release 2.0); permission flow and identity interaction will be addressed then. |

---

## 12. Assumptions Index

Every `[ASSUMPTION]` tag from the document body, surfaced here for explicit confirmation:

- **§4.1 (FR-1)** — The user logs visits immediately after eating, while walking out of the restaurant, when impressions are freshest.
- **§4.1 (FR-1)** — On-device speech-to-text API (iOS Speech Framework or Android SpeechRecognizer) provides acceptable accuracy in typical restaurant ambient noise; if unavailable, falls back to manual text entry.
- **§4.5 (FR-11)** — The expected data volume (<500 Restaurants, <2000 Visits) is small enough that even basic term-frequency search feels instant on a modern smartphone.
- **§4.7 (FR-11)** — The user will want to enable location services on their device for the discovery map feature; it is opt-in and not required for core functionality.

**Post-review assumption updates:**
- GPS/location auto-population removed from v1 (OQ-11 deferred) — no assumption needed about location permission flow at this stage.
- Restaurant identity uses simplified `(name, address)` tuple (S2 resolved) — assumes single-address string is sufficient for MVP deduplication; granular street/city/state fields may be added post-MVP if name+address collisions prove frequent in real usage.

---

## 13. Data Model Overview

High-level entities for the local data store. Implementation details (Hive boxes, field types) are resolved in architecture.

**Key design decisions:** (1) UUID primary keys for offline-first independence, (2) all location fields optional to support name-only logging, (3) `compositeScore` calculated at write time and re-derived if any input rating changes — not stored as an independent source of truth.

### Entities

```
Restaurant
├── id: UUID (primary key)
├── name: string
├── address: string? (optional — but required if another Restaurant shares the same name; simplified from granular street/city/state/country/postalCode per S2 resolution; post-MVP may expand to structured fields for GPS integration)
├── cuisineType: string (e.g., "Italian", "Japanese")
│   └── Note: Free-text with suggested presets (~20 common types); user can add custom cuisines. Stored lowercase internally, displayed with title case. Case-insensitive comparison for filtering and search.
├── occasionTags: string[] (e.g., ["date night", "quick lunch"]) — **default suggestions** applied when logging a new Visit at this Restaurant; the user can accept, modify, or override these defaults per-visit. Actual visit-level occasions are stored on the Visit entity (FR-8).
    └── Note: Default occasion tags help speed up logging — if the user frequently visits this restaurant for "date night," that tag is pre-selected when they log a new visit here. Per-Visit occasion tagging (FR-8) remains independent; defaults are merely suggestions, not constraints.
├── favorite: boolean (derived state — auto-detected from Visit aggregates per FR-7, with manual pin/unpin override; recomputed when associated Visits change)
├── generalNotes: string? (persistent free-text notes about the restaurant spanning all visits; included in full-text search per FR-17)
├── createdAt: datetime
└── updatedAt: datetime

Visit
├── id: UUID (primary key)
├── restaurantId: UUID (foreign key → Restaurant)
├── date: datetime
├── foodQualityRating: number (slider, user's chosen scale — 1–5 or 1–10)
├── valueForMoneyRating: number (slider)
├── serviceQualityRating: number (slider — new per C3/OQ-10 resolution; captures staff attentiveness, order accuracy, etc.)
├── overallExperienceRating: number (slider)
├── compositeScore: number (calculated: 40/30/15/15 weighted average of four ratings)
├── returnIntent: boolean
├── mealTotal: number? (manually entered total for meals; optional, not auto-calculated from line items per C2 resolution)
├── tipPercentage: number? (tip % given during this visit; optional)
├── employeeName: string? (server/employee name; optional)
├── employeeNote: string? (free-text note about the employee's service; optional)
├── isBlacklisted: boolean? (per-Visit blacklist flag per S4 resolution; blacklisting a visit does not blacklist the Restaurant)
├── blacklistReason: string? (reason for blacklisting this visit; free text with suggested categories)
├── blacklistedAt: datetime? (timestamp when visit was blacklisted)
├── voiceNotePath: string? (file path to audio file; optional)
├── voiceTranscript: string? (transcribed text for search; optional)
├── photoPaths: string[]? (optional)
└── notes: string? (free-text visit notes; optional)
    └── Note: Cuisine type is stored on Restaurant, not Visit. Per-visit cuisine excluded from MVP — a restaurant's cuisine rarely changes, and adding it would increase logging form complexity.

VisitItem (line items within a Visit)
├── id: UUID (primary key)
├── visitId: UUID (foreign key → Visit)
├── name: string (e.g., "Margherita Pizza")
├── cost: number? (optional — only entered for items the user wants to track cost-wise; line items without a price serve as dish memory, not cost accounting. mealTotal is manually entered, not auto-calculated from line items.)
└── notes: string? (optional, e.g., "amazing crust")

JournalEntry (per dish within a Visit)
├── id: UUID (primary key)
├── visitId: UUID (foreign key → Visit)
├── dishName: string
└── impressions: string (e.g., "great at first, soggy by bite 5")
    └── Note: Per-dish rating removed from v1 data model (M4 resolution) — deferred to post-MVP. Including an optional field now would risk accidental implementation; omit entirely.

AllergySafeFood
├── id: UUID (primary key)
├── restaurantId: UUID (foreign key → Restaurant)
├── foodName: string
├── confirmedAt: datetime
└── notes: string? (optional, e.g., "confirmed safe — no reaction")

UserAllergen (personal allergens from Settings)
├── id: UUID (primary key)
├── allergenName: string (e.g., "peanuts", "shellfish")
├── severity: enum[MILD, MODERATE, SEVERE]
└── active: boolean

UserPreferences
├── ratingScale: enum[FIVE_STAR, TEN_STAR]
├── preferredCuisines: string[]
├── defaultOccasionTags: string[]
├── mapDistanceThreshold: number? (meters; deferred to post-MVP Release 2.0 — field exists in schema but unused in v1)
└── gameLayerEnabled: boolean? (opt-in, default false; deferred to post-MVP Release 2.5+ — field exists in schema but unused in v1)
```

### Relationships

- **Restaurant** 1→* **Visit** — A Restaurant can have many Visits. Restaurant identity is the `(name, address)` tuple (see OQ-6, S2 resolved). Two entries with the same name but different addresses are distinct Restaurants.
- **Visit** 1→* **VisitItem** — A Visit has multiple line items.
- **Visit** 1→* **JournalEntry** — A Visit has multiple journal entries.
- **Restaurant** 1→* **AllergySafeFood** — A Restaurant has one safe foods list.
- **Visit** → blacklist state — `isBlacklisted`, `blacklistReason`, and `blacklistedAt` live on Visit (S4 resolved), not Restaurant. Blacklisting a Visit excludes it from favorites auto-detection but does not affect the parent Restaurant's visibility or browseability.

---

## 14. Appendix

### A. Companion Files

- `planning_artifacts/prd-plated4me-app.md` — Source PRD (v2.0, Draft) from which this BMad-formatted document was derived
- `_bmad_output/review-rubric.md` — Quality review against the bmad-prd rubric (pending execution)
