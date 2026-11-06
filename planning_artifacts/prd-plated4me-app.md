# Product Requirements Document: Plated4Me

**Version:** 3.0  
**Date:** November 6, 2026  
**Status:** Draft  
**Author:** James Reid  
**Source:** PRD v2.0 + product revision — meal cost model shift, tip/employee tracking, restaurant notes  

---

## 1. Product Overview

Plated4Me is a personal mobile application for logging and reviewing restaurant/food experiences. It helps the user make informed decisions about where to eat by maintaining a verified, private record of past visits — including food quality, value for money, allergy-safe foods, and overall experience.

### 1.1 Problem Statement

The user faces three core problems:
1. **Unreliable external information** — Online reviews and staff knowledge about food allergies are inconsistent; a personal verified record is needed
2. **Emotional pain of wasted spending** — Feeling "ripped off" when portion size, quality, or price don't align
3. **Memory gaps** — Forgetting good experiences or repeating bad ones

### 1.2 Success Criteria

The app is successful when the user can open it before visiting a new or returning establishment and make an informed decision within 10 seconds — either confidently walking in because past data supports it, or choosing elsewhere to avoid a repeat of a bad experience.

---

## 2. Release Plan

### 2.1 MVP (Release 1.0)

The minimum set of features that delivers core value: log visits quickly, retrieve them meaningfully, and make informed decisions.

| Feature | User Story |
|---------|-----------|
| Quick Visit Logging | US-1 |
| Meal Cost & Tip Tracking | US-2 |
| Restaurant General Notes | US-3 |
| Weighted Rating System | US-4 |
| Return Intent Flag | US-5 |
| Allergy-Safe Database | US-6 |
| Food Journal | US-7 |
| Favorites Collection | US-8 |
| Occasion Tagging | US-9 |
| Filterable List View | US-10 |
| Blacklist / Avoid List | US-11 |
| Onboarding Flow | US-12 |
| Full-Text Search | US-13 |
| Settings & Preferences | US-14 |

**MVP Definition of Done:** User can go from zero to logging their first visit, then searching and filtering past visits to make a dining decision. No map, no random suggestions, no gamification — just reliable personal records.

**Traceability note:** Each user story (US-N) maps 1:1 to a functional requirement (FR-N) with the same numeric ID. All downstream artifacts (epics, stories, architecture decisions) should reference both IDs together (e.g., "US-3 / FR-3") for full traceability.

### 2.2 Future Releases (Post-MVP)

| Release | Features | Rationale |
|---------|----------|-----------|
| **1.5** | Random Cuisine Suggestion (US-15), Settings: distance threshold for discovery map | Light-weight additions that build on MVP data |
| **2.0** | Discovery Map with fog-of-war (US-16) | Requires geo-data infrastructure; higher complexity |
| **2.5+** | Game Layer — achievements, stats, quests (US-17) | Engagement feature; not core to value proposition |

---

## 3. User Stories

### MVP Stories (Release 1.0)

#### US-1: Quick Visit Logging
**As a** user who just finished eating at a restaurant  
**I want to** log my visit in under 30 seconds using voice notes, photos, and quick slider ratings  
**So that** I can capture impressions while walking out, not later from memory  

**Acceptance Criteria:**
- Visit logging flow completes in ≤30 seconds (core fields: restaurant name, location, composite rating, return intent; meal total, tip %, and employee info are optional expandable fields)
- Supports voice note input with speech-to-text transcription for full-text search
- Photo capture/upload capability
- Quick slider ratings (food quality, value for money, overall experience)
- If the entered `(name, street, city, state)` tuple does not match any existing restaurant, a new Restaurant record is created implicitly — no separate "Add Restaurant" screen
- If multiple existing restaurants share the same name but differ in any location field, the user sees a disambiguation picker (≤3 options, sorted by most recent visit) before proceeding to rating fields

#### US-2: Meal Cost & Tip Tracking
**As a** user who wants to record what they actually paid without tedious per-item bookkeeping  
**I want to** enter a single meal total manually, optionally assign prices to specific items I care about, and track the tip % along with the server's name and notes  
**So that** I can capture real spending (including tip) while still being able to note which dishes drove value — without the friction of pricing every line item  

**Acceptance Criteria:**
- During visit logging, user enters a single **meal total** (manual entry, not auto-calculated from line items)
- User can add multiple line items with a name; an individual price is **optional** per item (only entered for items the user wants to track cost-wise)
- User enters a **tip percentage** (%) during visit logging
- User can record an **employee/server name** associated with the visit
- A free-text **note field** is coupled to the employee name (e.g., "great recommendation on wine pairing")
- Tip % and employee info are stored per visit for future service-quality analysis
- Line items without a price do not affect the meal total — they serve as dish memory, not cost accounting

#### US-3: Restaurant General Notes
**As a** user who returns to the same restaurants multiple times  
**I want to** leave general notes on a restaurant that persist across all visits  
**So that** I can capture enduring information — like "best patio seating in summer," "call ahead on weekends," or "they changed chefs, expect different quality" — that applies to the restaurant as a whole, not just one visit  

**Acceptance Criteria:**
- Each restaurant has an editable general notes field (free-text)
- Notes are stored at the restaurant level and visible from both the restaurant detail view and any associated visit
- Notes can be updated at any time (during visit logging or from restaurant settings)
- General notes are included in full-text search results

#### US-4: Weighted Rating System
**As a** user who wants consistent, meaningful ratings  
**I want** visits rated using a weighted criteria system (40% food quality, 30% value for money, 30% overall experience)  
**So that** I can quickly compare restaurants on what matters most  

**Acceptance Criteria:**
- Three rating inputs: food quality (40%), value for money (30%), overall experience (30%)
- Weighted composite score displayed per visit
- Individual component scores also visible

#### US-5: Return Intent Flag
**As a** user who needs a quick signal for future decisions  
**I want** a binary "Would I come back?" yes/no flag on each visit  
**So that** I can quickly identify places worth revisiting  

**Acceptance Criteria:**
- Binary toggle (yes/no) during visit logging
- Filterable in list views

#### US-6: Allergy-Safe Database
**As a** user with food allergies who needs to eat safely  
**I want** a per-restaurant safe foods list that updates over time as I visit and confirm what was safely consumed  
**So that** I can order confidently at returning restaurants  

**Acceptance Criteria:**
- Per-restaurant safe foods list maintained separately from individual visits
- Ability to add/remove items from safe foods list during visit logging
- Safe foods indicator shown in restaurant detail view

#### US-7: Food Journal
**As a** user who wants detailed records of what I ate  
**I want** to log what I ordered at each visit along with impressions (e.g., how food tasted at bite 1 vs bite 5)  
**So that** I can track which dishes are worth ordering again  

**Acceptance Criteria:**
- Per-visit food journal entries with dish name and notes
- Notes support free-text descriptions of experience over time

#### US-8: Favorites Collection
**As a** user who needs quick recommendations  
**I want** auto-surfaced favorites by category when I need recommendations  
**So that** I can quickly find places to go without scrolling through all history  

**Acceptance Criteria:**
- Auto-detection rule: a restaurant is automatically added to Favorites when it meets **all three** conditions across its visit history:
  - At least **2 visits** logged, AND
  - Average composite score ≥ **80% of the chosen scale maximum** (i.e., ≥4.0 on a 5-star scale, or ≥8.0 on a 10-star scale), AND
  - `returnIntent = true` on at least **1 of those visits**
- Manual override: user can pin/unpin any restaurant as a favorite at any time (from restaurant detail view or list card). Manual pins are always respected regardless of auto-detection score.
- Favorites grouped by cuisine type or occasion for easy browsing
- Favorites list is the default landing view when the user opens the app and no recent visits exist

#### US-9: Occasion Tagging
**As a** user who wants context-aware filtering  
**I want** visits tagged by context (date night, quick lunch, family dinner, business meal)  
**So that** I can filter my history to find the right place for the current occasion  

**Acceptance Criteria:**
- Predefined occasion tags available during visit logging
- User can add custom occasion tags
- Filterable in list views

#### US-10: Object-Based List View with Filters
**As a** user who wants to browse my restaurant history  
**I want** a filterable list view supporting filters by cuisine type, price range, rating, occasion, and allergy-safe status  
**So that** I can quickly find restaurants matching my current needs  

**Acceptance Criteria:**
- List view displays visits as objects (cards) with key info: name, date, composite score, return intent flag
- Filter controls for: cuisine type, price range, rating, occasion, allergy-safe status
- Results update in real-time as filters change
- Default sort: most recent first

#### US-11: Blacklist / Avoid List
**As a** user who wants to avoid bad experiences  
**I want** to mark places I should never return to due to bad experiences, allergies, or poor value  
**So that** they don't appear in suggestions and I'm reminded why I avoided them  

**Acceptance Criteria:**
- Blacklist toggle during visit logging (or from restaurant detail view)
- Reason for blacklisting stored and displayed (free text with suggested categories: bad experience, allergy reaction, poor value, overpriced)
- Blacklisted places excluded from random suggestions

#### US-12: Onboarding Flow
**As a** new user  
**I want** to set up my profile during first launch — including my food allergies, preferred cuisines, and rating scale preferences  
**So that** the app is personalized from day one  

**Acceptance Criteria:**
- First-run onboarding screen with guided setup:
  - Food allergies (optional but encouraged)
  - Preferred cuisine types (multi-select)
  - Rating scale preference (1–5 or 1–10 stars)
  - Default occasion tags
- User can skip and configure later in Settings
- Onboarding is a one-time flow; settings can be updated anytime

#### US-13: Full-Text Search
**As a** user who wants to find something specific from my history  
**I want** to search across restaurant names, voice transcripts, food journal entries, and notes  
**So that** I can quickly locate past experiences by content, not just filters  

**Acceptance Criteria:**
- Search bar at top of list view
- Searches across: restaurant name, street, city, state, country, postal code, voice note transcripts, journal dish names, journal notes, occasion tags, restaurant general notes, employee/server names
- Results ranked by relevance (most relevant first)
- Search highlights matching text in results

#### US-14: Settings & Preferences
**As a** user who wants control over my app experience  
**I want** to configure my preferences — allergies, rating scales, distance thresholds, and data management  
**So that** the app works the way I do  

**Acceptance Criteria:**
- Allergy management: add/edit/remove personal food allergens and severity levels
- Rating scale customization: choose 1–5 or 1–10 stars for individual ratings
- Distance threshold for discovery map (configurable in meters/kilometers)
- Data export option (JSON backup of all local data)
- Clear blacklist entries option

### Future Stories (Post-MVP)

#### US-15: Random Cuisine Suggestion *(Release 1.5)*
**As a** user who wants to try something new  
**I want** to request a random restaurant suggestion filtered by cuisine type (Italian, Indian, etc.)  
**So that** I can discover new places with confidence  

**Acceptance Criteria:**
- "Random Suggestion" button/feature
- Filterable by cuisine type before generating suggestion
- Indicator showing whether it's a new place or already visited

#### US-16: Discovery Map *(Release 2.0)*
**As a** user who wants to visualize my restaurant exploration  
**I want** a visual map showing the history of visited places using a fog-of-war style — areas clear as I visit more locations  
**So that** I can see my culinary journey and identify unexplored areas  

**Acceptance Criteria:**
- Map view displays visited restaurants with markers
- Fog-of-war effect: unvisited areas remain obscured
- Areas clear progressively as user visits more locations
- Configurable threshold distance for city/country boundaries (settings)

#### US-17: Game Layer — Optional Enhancement *(Release 2.5+)*
**As a** user who wants motivation to explore  
**I want** achievement badges, stats dashboard, and quest prompts that gamify exploration  
**So that** I'm encouraged to try new cuisines and discover hidden gems  

**Acceptance Criteria:**
- Achievement badges (e.g., "Food Explorer" for 10 cuisine types, "Value Hunter" for great portion-to-price ratios)
- Stats dashboard showing visit counts, average ratings, favorite cuisines
- Quest prompts suggesting new experiences
- **Note:** Opt-in feature — user enables in Settings

---

## 4. Functional Requirements

### MVP (Release 1.0)

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| FR-1 | Visit logging with voice, photo, ratings | Must Have | ≤30 seconds to complete |
| FR-2 | Meal cost & tip tracking (manual meal total, optional per-item price, tip %, employee name + note) | Should Have | Manual entry; per-item cost optional |
| FR-3 | Restaurant general notes (persistent across visits, included in search results) | Should Have | Stored at restaurant level |
| FR-4 | Weighted rating system (40/30/30: food quality, value for money, overall experience) | Must Have | Composite score calculated |
| FR-5 | Return intent flag (yes/no) | Must Have | Binary toggle |
| FR-6 | Allergy-safe database per restaurant | Must Have | Updates over time |
| FR-7 | Food journal with impressions | Should Have | Free-text notes |
| FR-8 | Favorites collection auto-surfaced | Must Have | Auto: ≥2 visits, avg composite ≥80% of max scale (≥4.0/5★ or ≥8.0/10★), returnIntent=true on ≥1 visit; manual pin/unpin always overrides |
| FR-9 | Occasion tagging | Should Have | Predefined + custom tags |
| FR-10 | Filterable list view | Must Have | Multiple filter dimensions |
| FR-11 | Blacklist/avoid list | Should Have | Excluded from suggestions |
| FR-12 | Onboarding flow | Must Have | Allergies, preferences, rating scale |
| FR-13 | Full-text search | Must Have | Across all text content |
| FR-14 | Settings & preferences | Must Have | Allergy mgmt, data export, customization |

### Future (Post-MVP)

| ID | Requirement | Priority | Release | Notes |
|----|-------------|----------|---------|-------|
| FR-15 | Random cuisine suggestion | Could Have | 1.5 | New vs. visited indicator |
| FR-16 | Discovery map with fog-of-war | Could Have | 2.0 | Configurable distance threshold |
| FR-17 | Game layer (achievements, stats) | Could Have | 2.5+ | Opt-in feature |

---

## 5. Data Model Overview

High-level entities for the local data store. Implementation details (Hive boxes, field types) are resolved in architecture.

### Entities

```
Restaurant
├── id: UUID (primary key)
├── name: string
├── street: string? (street address, e.g., "123 Main St" — optional; at least one of street or gps must be present for disambiguation)
├── city: string? (city/town name — optional)
├── state: string? (state/province/region — optional; use ISO 3166-2 subdivide codes where available)
├── country: string? (country — optional; use ISO 3166-1 alpha-2 code, e.g., "US", "CA", "MX")
├── postalCode: string? (zip/postal code — optional)
├── gpsLatitude: number? (WGS84 latitude — optional; auto-populated from device location services during visit logging)
├── gpsLongitude: number? (WGS84 longitude — optional; same source as gpsLatitude)
├── formattedAddress: string (computed/read-only at read time from street, city, state, country, postalCode in locale-appropriate order; never persisted independently)
├── cuisineType: string (e.g., "Italian", "Japanese")
├── occasionTags: string[] (e.g., ["date night", "quick lunch"])
├── isBlacklisted: boolean
├── blacklistReason: string (optional)
├── blacklistedAt: datetime (optional)
├── favorite: boolean
├── generalNotes: string (persistent free-text notes about the restaurant, optional)
├── createdAt: datetime
└── updatedAt: datetime

Visit
├── id: UUID (primary key)
├── restaurantId: UUID (foreign key → Restaurant)
├── date: datetime
├── mealTotal: number (manually entered total for meals, optional)
├── tipPercentage: number (tip % given during this visit, optional)
├── employeeName: string (server/employee name, optional)
├── employeeNote: string (free-text note about the employee's service, optional)
├── foodQualityRating: number (slider, e.g., 1–5 or 1–10)
├── portionPriceRating: number (slider)
├── overallExperienceRating: number (slider)
├── compositeScore: number (calculated: 40/30/30 weighted average)
├── returnIntent: boolean
├── voiceNotePath: string (file path to audio file, optional)
├── voiceTranscript: string (transcribed text for search, optional)
├── photoPaths: string[] (optional)
└── notes: string (free-text visit notes, optional)

VisitItem (line items within a Visit)
├── id: UUID (primary key)
├── visitId: UUID (foreign key → Visit)
├── name: string (e.g., "Margherita Pizza")
├── cost: number? (optional — only entered for items the user wants to track cost-wise)
└── notes: string (optional, e.g., "amazing crust")

JournalEntry (per dish within a Visit)
├── id: UUID (primary key)
├── visitId: UUID (foreign key → Visit)
├── dishName: string
├── impressions: string (e.g., "great at first, soggy by bite 5")
└── rating: number (optional per-dish rating)

AllergySafeFood
├── id: UUID (primary key)
├── restaurantId: UUID (foreign key → Restaurant)
├── foodName: string
├── confirmedAt: datetime
└── notes: string (optional, e.g., "confirmed safe — no reaction")

UserAllergen (personal allergens from Settings)
├── id: UUID (primary key)
├── allergenName: string (e.g., "peanuts", "shellfish")
├── severity: enum[MILD, MODERATE, SEVERE]
└── active: boolean

UserPreferences
├── ratingScale: enum[FIVE_STAR, TEN_STAR]
├── preferredCuisines: string[]
├── defaultOccasionTags: string[]
├── mapDistanceThreshold: number (meters)
└── gameLayerEnabled: boolean (opt-in, default false)

DataExport
├── id: UUID (primary key)
├── exportedAt: datetime
├── format: enum[JSON]
└── filePath: string (local file path of export)
```

### Relationships

- **Restaurant** 1→* **Visit** — A restaurant can have many visits. Restaurant identity is the `(name, street, city, state)` tuple (see OQ-6). Two entries with the same name but differing location fields are distinct restaurants. GPS coordinates are supplementary and do not affect identity (a restaurant's physical address is more stable than its lat/lng).
- **Visit** 1→* **VisitItem** — A visit has multiple line items
- **Visit** 1→* **JournalEntry** — A visit has multiple journal entries
- **Restaurant** 1→* **AllergySafeFood** — A restaurant has a safe foods list

---

## 6. Non-Functional Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| NFR-1 | Platform: Mobile application (iOS and/or Android) | Must Have | Flutter framework |
| NFR-2 | Single-user only | Must Have | No multi-user accounts, sharing, or social features |
| NFR-3 | All data stored locally on device | Must Have | No cloud sync; fully offline |
| NFR-4 | Fully offline capable | Must Have | No server infrastructure required |
| NFR-5 | Logging flow ≤30 seconds | Must Have | Performance requirement from open to save |
| NFR-6 | Search latency <200ms | Should Have | Full-text search across local data must feel instant |
| NFR-7 | App cold start <2 seconds | Should Have | First launch and subsequent opens |

---

## 7. Constraints

| ID | Constraint | Notes |
|----|------------|-------|
| C1 | Platform: Mobile application (iOS and/or Android) | Flutter framework per SPEC.md |
| C2 | Single-user only — no multi-user accounts, sharing, or social features | Per SPEC.md |
| C3 | All data stored locally on the user's device | Per SPEC.md; no cloud sync in v1 |
| C4 | Logging must take under 30 seconds to complete | Per SPEC.md |
| C5 | No server infrastructure required — fully offline capable | Per SPEC.md |

---

## 8. Risks & Mitigations

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|------------|------------|
| R1 | Voice transcription fails or is inaccurate in noisy restaurant environments | High | Medium | Make voice optional; allow text-only logging as fallback. If transcription fails, user can still add manual notes. |
| R2 | Data loss — fully offline means no backup if device is lost or app is uninstalled | High | Low-Medium | Provide JSON data export in Settings (FR-16). Encourage periodic backup during onboarding. |
| R3 | Logging flow exceeds 30 seconds due to added cost-tracking fields (meal total, tip %, employee info) | Medium | Medium | Use progressive disclosure: show meal total and tip as compact inline inputs; collapse employee name/note behind an expandable "Server & Tip" section. Keep all new fields optional so the user can skip them for a quick log. |
| R4 | Hive schema migration issues as data model evolves | Medium | Medium | Version the data schema explicitly. Test migrations with sample data before each release. |
| R5 | User abandons app after a few visits because logging feels like a chore | High | Medium | Keep MVP logging minimal (name, rating, return intent). Defer itemized costs and journal to expandable sections. |
| R6 | Discovery map performance degrades with many locations | Low-Medium | Low | Defer to v2.0; implement lazy loading for markers if needed. |

---

## 9. Open Questions

| # | Question | Status | Answer |
|---|----------|--------|--------|
| ~~OQ-1~~ | ~~Should the allergy-safe database include severity levels (mild vs. severe reactions)?~~ | **Resolved** | Not needed — single severity flag is sufficient for this use case |
| OQ-2 | What is the preferred local storage backend for Flutter? | **Resolved** | Use HIVE |
| OQ-3 | Should voice notes be transcribed to text for searchability, or stored as audio only? | **Resolved** | Yes — speech-to-text transcription enabled for full-text search |
| OQ-4 | How should the discovery map handle places in different cities or countries? | ✅ Resolved | Use a threshold distance based on location, configurable via settings feature. |
| ~~OQ-5~~ | ~~Should the game layer be enabled by default or opt-in?~~ | **Resolved** | Opt-in — user enables in Settings (default: disabled) |
| OQ-6 | Should the app support multiple restaurants with the same name at different addresses? | **✅ Resolved** | Yes — restaurant uniqueness is `(name, street, city, state)` tuple. Two "Starbucks" on different streets (or even in different cities/states) are distinct restaurants. This is essential for a personal log where the *location* drives the experience (different seating, atmosphere, service). Architecture must deduplicate by this tuple during lookup; if only `name` matches but any location field differs, present both to the user for disambiguation. GPS coordinates are supplementary and do not affect identity. |
| OQ-7 | What happens if a user wants to log a visit to a restaurant not yet in their database? | **✅ Resolved** | Logging auto-creates the restaurant. The ≤30-second logging constraint (§NFR-5) means there is no separate "Add Restaurant" screen. During the visit logging flow, if the entered location does not match any existing restaurant by `(name, street, city, state)` tuple, a new Restaurant record is created implicitly with the provided name and parsed location fields. The user then continues directly into rating/visit fields — no intermediate form. GPS coordinates may be auto-populated from device location services if the user grants permission. |
| OQ-8 | Should ratings be configurable per release (e.g., different weights for food vs. portion)? | **Resolved** | Fixed 40/30/30 for MVP; make configurable in v2 if needed |
| OQ-9 | Should "value for money" remain in the composite score, or be decoupled since FR-2 tracks cost data separately? | **Open** | Current design keeps it at 30% for a balanced composite. Alternative: remove from composite entirely (leaving food quality + overall experience = 50/50) and let value analysis live purely in the FR-2 cost tracking layer. Low priority — decision deferred until MVP usage data is available. |
| OQ-10 | Should "service quality" be added as a fourth rating dimension? | **Open** | The data model already supports employee name + notes (US-3). A dedicated service rating could complement this, but adds friction to the ≤30-second logging flow. Consider post-MVP. |
| OQ-11 | How should GPS auto-population interact with location permissions? | **Open** | Restaurant entity now has `gpsLatitude`/`gpsLongitude` fields that can be auto-filled from device location services during visit logging. This requires the app to request location permission (iOS: `whenInUse` or `always`; Android: `ACCESS_FINE_LOCATION`). If denied, user can still enter location manually via street/city/state fields. Decision needed on whether to request location at onboarding or lazily at first visit log. |

---

## 10. Out of Scope (Non-Goals)

- Multi-user accounts or collaborative features
- Social sharing of reviews (no Yelp, no public profiles)
- Integration with restaurant reservation systems
- Automated price scraping from menus
- AI-generated review summaries
- Location-based notifications (not in v1)
- Cloud sync or cross-device data transfer (not in v1)
- Web version or desktop app (mobile only)

---

## 11. Assumptions

- User has a smartphone with camera and microphone capabilities
- User is comfortable logging visits immediately after eating (while walking out)
- Voice transcription works acceptably in typical restaurant environments (with fallback to text-only)
- Local storage performance is sufficient for the expected data volume (<500 restaurants, <2000 visits)
- User understands that data lives only on their device and may need to back up periodically

---

## 12. Appendix

### A. Glossary

| Term | Definition |
|------|------------|
| Visit | A single dining experience at a restaurant or food establishment, logged as one entry containing ratings, photos, voice notes, meal total, tip %, and employee/server info |
| Meal Total | The manually entered total cost for meals during a visit (not auto-calculated from line items) |
| Tip Percentage | The % tip given during a visit, stored alongside the server/employee name |
| Restaurant Location | Granular location fields: `street`, `city`, `state`, `country`, `postalCode` — all optional. Identity tuple is `(name, street, city, state)`. |
| GPS Coordinates | Optional `gpsLatitude`/`gpsLongitude` (WGS84) on the Restaurant entity; auto-populated from device location services during visit logging if permission granted. Supplementary to street-level fields and does not affect restaurant identity. |
| Formatted Address | Computed/read-only string derived at read time from `street`, `city`, `state`, `country`, `postalCode` in locale-appropriate order (e.g., "123 Main St, Anytown, ST 12345, US"). Never persisted independently — always regenerated when any source field changes. Used for UI display only. |
| Composite Score | Weighted rating calculated from food quality (40%), value for money (30%), and overall experience (30%) |
| Allergy-Safe Database | Per-restaurant list of foods confirmed safe for the user to consume |
| Discovery Map | Visual map showing visited restaurants with fog-of-war effect (post-MVP) |
| Blacklist | User-curated list of places they never want to return to, with reasons stored |
| Favorites Collection | Auto-surfaced list of highly-rated restaurants grouped by cuisine or occasion |
| Restaurant General Notes | Persistent free-text notes about a restaurant that span across all visits (e.g., "best patio in summer," "call ahead on weekends") |

### B. Companion Files
- `SPEC.md` — Source specification document
- `.memlog.md` — Append-only decision log (canonical source)
- `_bmad-output/brainstorming/plated4me-app/.memlog.md` — Brainstorming session log
