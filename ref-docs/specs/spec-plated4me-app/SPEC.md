# SPEC: Plated4Me

**Version:** 2.0  
**Date:** November 8, 2026  
**Status:** Final — aligned with PRD v3.0 (post-review decisions applied)

---

## Why

When I'm about to visit a restaurant or store, I want to read my past insights so that I can decide whether to go in or select another place.

This app solves three core problems:
1. **Unreliable external information** — Online reviews and staff knowledge about food allergies are inconsistent; a personal verified record is needed
2. **Emotional pain of wasted spending** — Feeling "ripped off" when portion size, quality, or price don't align
3. **Memory gaps** — Forgetting good experiences or repeating bad ones

---

## Capabilities

### CAP-1: Quick Visit Logging (MVP)
The app enables logging a visit in under 30 seconds using voice notes, photos, and quick slider ratings. Users capture impressions while walking out, not later from memory. Core flow captures: restaurant name, address, four composite ratings (food quality, value for money, service quality, overall experience), and return intent flag. Restaurant auto-created if `(name, address)` tuple doesn't exist; disambiguation picker shown if multiple restaurants share the same name at different addresses.

### CAP-2: Meal Total Tracking (MVP)
Users enter a single **meal total** (the full pre-tip bill for the dining experience) during visit logging — this is the primary cost capture. Users can optionally track individual items (e.g., "hamburger," "firebird wings," "beer") with names and prices for cross-restaurant comparison purposes only; line items are completely independent of the meal total and do not reconcile or sum to it. Line items serve as dish memory, not a receipt breakdown.

### CAP-3: Weighted Rating System (MVP)
Visits are rated using a four-dimension weighted criteria system: **40% food quality**, **30% value for money** (portion size vs. price), **15% service quality**, and **15% overall experience**. The composite score is calculated at write time as `food × 0.40 + value × 0.30 + service × 0.15 + overall × 0.15` and re-derived if any input rating changes. Weights are fixed for MVP; configurability deferred to v2.

### CAP-4: Return Intent Flag (MVP)
A binary "Would I come back?" yes/no flag stored with each Visit, filterable in list views. Provides a quick signal for future decision-making.

### CAP-5: Allergy-Safe Database (MVP)
Per-Restaurant safe foods list that updates over time as the user visits and confirms what was safely consumed. Severity levels tracked at the User level (Settings), not per-Restaurant. The Allergy-Safe Database stores only food names — severity context lives in Settings.

### CAP-6: Food Journal (MVP)
Users log per-Visit journal entries, each with a dish name and free-text impressions describing the experience over time (e.g., "amazing crust at first, got chewy by bite 5"). Optional expandable section within logging flow — not part of the core ≤30-second path. Per-dish rating deferred to post-MVP.

### CAP-7: Favorites Collection (MVP)
Auto-surfaced favorites when a Restaurant meets all three conditions across its Visit history: at least 2 Visits, average composite score ≥80% of chosen scale maximum, and `returnIntent = true` on at least 1 Visit. Manual pin/unpin override always respected. Favorites grouped by cuisine type or occasion; serves as default landing view when no recent visits exist.

### CAP-8: Occasion Tagging (MVP)
Visits tagged by context: date night, quick lunch, family dinner, business meal, etc. Predefined tags available during logging; user can add custom tags at any time. Restaurants have **default occasion tag suggestions** that pre-populate when logging a new visit — user can accept, modify, or override per-visit. Visits filterable by occasion in list views.

### CAP-9: Filterable List View (MVP)
List view displays Visits as cards with key info: Restaurant name, date, composite score, return intent flag. Filter controls for: cuisine type, price range, rating, occasion, allergy-safe status. Results update within one frame (~16ms) of filter change. Default sort: most recent first. Cost-related filters (tip %, meal total range) excluded from MVP.

### CAP-10: Full-Text Search (MVP)
Search bar at top of list view searching across: Restaurant name, address, voice note transcripts, journal dish names, journal notes, occasion tags, employee/server names, restaurant general notes. Results ranked by relevance: exact restaurant name match > partial name + address match > employee/server name match > journal dish name match > voice transcript / journal note match > restaurant general notes match > occasion tag match > general visit notes match. Search highlights matching text in results.

### CAP-11: Blacklist / Avoid List (MVP)
Users can mark a Visit as blacklisted due to bad experiences, allergies, or poor value. Reason stored and displayed (free text with suggested categories: bad experience, allergy reaction, poor value, overpriced). Blacklisted visits excluded from favorites auto-detection and random suggestions. Blacklisting a Visit does not blacklist the parent Restaurant — it remains browsable and can still be revisited.

### CAP-12: Restaurant General Notes (MVP)
Each Restaurant has an editable general notes field (free-text) that persists across all Visits. Notes visible from both Restaurant detail view and associated Visits. During visit logging, existing restaurant notes appear as a pre-populated expandable section the user can edit or clear. Included in full-text search results.

### CAP-13: Onboarding Flow (MVP)
First-run guided setup capturing: food allergies (optional but encouraged), preferred cuisine types (multi-select from ~20 common presets with free-text option), rating scale preference (1–5 or 1–10 stars), default occasion tags. User can skip any step and configure later in Settings. One-time flow, completed in under 2 minutes.

### CAP-14: Settings & Preferences (MVP)
Allergy management: add/edit/remove personal food allergens with severity levels (Mild, Moderate, Severe). Rating scale customization: choose 1–5 or 1–10 stars. Data export option: JSON backup of all local data to a shareable file. Clear blacklist entries option.

### CAP-15: Random Cuisine Suggestion (Post-MVP — Release 1.5)
"Random Suggestion" button/feature from main browse view, filterable by cuisine type before generating suggestion. Indicator showing whether the suggested Restaurant is new (never visited) or already in user's history. Requires sufficient visit data to be useful.

### CAP-16: Discovery Map with Fog-of-War (Post-MVP — Release 2.0)
Map view displays visited Restaurants with markers. Fog-of-war effect: unvisited areas remain obscured, clearing progressively as the user visits more locations. Configurable threshold distance for city/country boundaries in Settings. Requires geo-data infrastructure; deferred due to complexity.

### CAP-17: Game Layer — Achievements, Stats, Quests (Post-MVP — Release 2.5+)
Achievement badges (e.g., "Food Explorer" for 10 cuisine types, "Value Hunter" for great portion-to-price ratios). Stats dashboard showing visit counts, average ratings, favorite cuisines. Quest prompts suggesting new experiences. **Opt-in feature** — user enables in Settings; default is disabled.

---

## Constraints

| ID | Constraint |
|----|------------|
| C1 | Platform: Mobile application built with Flutter (iOS + Android) |
| C2 | Single-user only — no multi-user accounts, sharing, or social features |
| C3 | All data stored locally on the user's device |
| C4 | Logging must take under 30 seconds to complete |
| C5 | No server infrastructure required — fully offline capable |

---

## Non-Goals

- Multi-user accounts or collaborative features
- Social sharing of reviews (no Yelp, no public profiles, no export to review sites)
- Integration with restaurant reservation systems (OpenTable, Resy, etc.)
- Automated price scraping from menus
- AI-generated review summaries
- Location-based notifications (not in v1; GPS not used during MVP)
- Cloud sync or cross-device data transfer (fully offline, single device only)
- Web version or desktop app (mobile only)

---

## Success Signal

The app is successful when the user can open it before visiting a new or returning establishment and make an informed decision within 10 seconds — either confidently walking in because past data supports it, or choosing elsewhere to avoid a repeat of a bad experience.

---

## Open Questions

| # | Question | Status | Answer |
|---|----------|--------|--------|
| ~~OQ-1~~ | ~~Should the allergy-safe database include severity levels (mild vs. severe reactions)?~~ | **Resolved** | Not needed — single severity flag is sufficient for this use case |
| OQ-2 | What is the preferred local storage backend for Flutter (Hive, SQLite, Isar)? | **Resolved** | Use HIVE |
| OQ-3 | Should voice notes be transcribed to text for searchability, or stored as audio only? | **Resolved** | Yes — speech-to-text transcription enabled for full-text search |
| OQ-4 | How should the discovery map handle places in different cities or countries? | **✅ Resolved** | Use a threshold distance based on location, configurable via settings feature. Deferred to Release 2.0 (CAP-16). |
| ~~OQ-5~~ | ~~Should the game layer be enabled by default or opt-in?~~ | **Resolved** | Opt-in — user enables in Settings (default: disabled) |
| OQ-6 | Should the app support multiple restaurants with the same name at different addresses? | **✅ Resolved** | Yes — restaurant uniqueness is `(name, address)` tuple. Two "Starbucks" on different streets are distinct restaurants. Architecture must deduplicate by this tuple during lookup; if only `name` matches but `address` differs, present both to the user for disambiguation. |
| OQ-7 | What happens if a user wants to log a visit to a restaurant not yet in their database? | **✅ Resolved** | Logging auto-creates the Restaurant. The ≤30-second logging constraint means there is no separate "Add Restaurant" screen. During the visit logging flow, if the entered `(name, address)` tuple does not match any existing Restaurant, a new record is created implicitly with the provided name and address. |
| OQ-8 | Should ratings be configurable per release (e.g., different weights for food vs. value for money)? | **✅ Resolved** | Fixed 40/30/15/15 for MVP (food quality, value for money, service quality, overall experience); weights stored as constants (not user-configurable) with a clear path to make them configurable if usage data shows demand. |
| OQ-9 | Should "value for money" remain in the composite score, or be decoupled since meal tracking data exists separately? | **✅ Resolved** | Value-for-money retained at 30% in composite (CAP-3). Serves dual purpose: composite scoring component + quick value signal. Meal tracking data (meal total, tip %, line items) provides additional granularity for deeper value analysis beyond the composite rating. |
| OQ-10 | Should "service quality" be added as a fourth rating dimension? | **✅ Resolved** | Added as fourth slider at 15% weight in CAP-3 (40/30/15/15). Complements employee/server name + note fields in CAP-2 — numeric rating for quick scoring, free-text for contextual detail. |
| OQ-11 | How should GPS auto-population interact with location permissions? | **Deferred to post-MVP** | GPS coordinates removed from v1 data model. Restaurant identity uses `(name, address)` tuple only. Location services may be added in post-MVP for discovery map (CAP-16 / Release 2.0); permission flow and identity interaction will be addressed then. |

---

## Companion Files

- `.memlog.md` — Append-only decision log (canonical source for this spec)
- `_bmad_output/prd.md` — Source PRD v3.0 (aligned, validated)
- `docs/planning-artifacts/architecture/architecture-Plated4Me-20261107/ARCHITECTURE-SPINE.md` — Architecture spine (AD-1 through AD-14, [final], Nov 2026). AD IDs are stable and citable from downstream epics/stories.
