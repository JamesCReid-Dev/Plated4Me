---
title: PRD — Quick Visit Logging
created: 2026-11-08
updated: 2026-11-08
status: final — post-review decisions applied (C1–S4 resolved)
parent: prd-index.md
---

# PRD: Quick Visit Logging

*FR-1, FR-2, FR-3, FR-4 + UJ-1*

**Realizes:** US-1, US-2, US-3, US-4, UJ-1, OQ-6, OQ-7, OQ-9, OQ-10.

---

## User Journey: UJ-1 — James logs a visit right after eating

> James finishes lunch at a new ramen shop he's never been to before. He opens Plated4Me while walking back to his office. The app shows a "Log Visit" screen. He types "Ichiran Ramen, 123 Main St" — the app creates the restaurant implicitly since it doesn't exist yet. He slides four bars: food quality 4/5, value for money 3/5, service quality 4/5, overall 4/5. The composite score (3.7) appears instantly. He toggles "Would I come back?" to Yes. He taps "Add photo" and snaps a picture of his bowl. He saves. Total time: ~20 seconds.
>
> **Edge case:** If another "Ichiran Ramen" exists at a different address in his database, the app shows a disambiguation picker (≤3 options, sorted by most recent visit) before he proceeds to ratings.

---

## FR-1: Visit logging with voice, photo, ratings (Must Have)

**Realizes:** US-1, UJ-1.

### Consequences (testable):
- Core flow completes in ≤30 seconds from app open to save, capturing: restaurant name, address, composite rating (four sliders), and return intent flag
- Supports voice note input with speech-to-text transcription for full-text search; voice is optional — user can skip it and enter text notes manually instead `[ASSUMPTION: On-device speech-to-text API provides acceptable accuracy in typical restaurant ambient noise; if unavailable, falls back to manual text entry]`
- Photo capture from camera or upload from gallery
- Four quick slider ratings: food quality, value for money, service quality, overall experience (on user's chosen scale — 5-star or 10-star, set during onboarding)
- If the entered `(name, address)` tuple does not match any existing Restaurant, a new Restaurant record is created implicitly with the provided name and address — no separate "Add Restaurant" screen (resolves OQ-7)
- If multiple existing Restaurants share the same name but differ in address, the user sees a disambiguation picker (≤3 options, sorted by most recent visit) before proceeding to rating fields (resolves OQ-6)
- If the entered restaurant name matches an existing Restaurant that has no address fields filled, the user must provide at least one location field (street, city, or state) before proceeding — name-only matching against null-address entries is not permitted

### Required / Optional Fields:

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

### Out of Scope:
- Voice transcription on a server — all processing is on-device during MVP
- Automatic restaurant detection from GPS or camera

---

## FR-2: Manual meal total with tip % and employee/server tracking (Should Have)

**Realizes:** US-2.

### Consequences (testable):
- User enters a single **meal total** (the full pre-tip amount for the dining experience) during visit logging — this is the primary cost capture, not derived from line items
- User can optionally add individual line items with name and an **optional price** per item — line items exist solely to track specific dishes or drinks the user wants to compare across restaurants (e.g., "hamburger at this place vs. that place"), NOT as a receipt breakdown; the meal total is independent of any line items
- Line items without a price serve as dish memory only, not cost accounting
- User enters a **tip percentage (%)** during visit logging — calculated against the meal total (not including line item prices)
- User can record an **employee/server name** associated with the visit
- A free-text **note field** is coupled to the employee name (e.g., "great recommendation on wine pairing")
- Tip % and employee info are stored per visit for future service-quality analysis

### Notes:
- The meal total represents the full pre-tip bill. Line items are completely independent — their prices do not sum to or reconcile with the meal total in any way. A user might log "$45" as the meal total and only track two items: "Steak $28" and "Cabernet $14" because those are the dishes they want to remember and compare elsewhere.
- Line items are an *optional expandable section* within the logging flow — not part of the core ≤30-second path. User taps "Add items" to expand; if skipped, only the composite ratings and return intent are captured.
- Restaurant general notes (if any exist for the selected restaurant) appear as an expandable **"Restaurant Notes"** section in the logging form, pre-populated with existing notes. The user can edit or clear them during logging. General notes persist at the Restaurant level across all visits and are included in full-text search results.

---

## FR-3: Weighted rating system (Must Have)

**Realizes:** US-3, OQ-9, OQ-10.

### Consequences (testable):
- Four rating inputs accepted: food quality (40% weight), value for money (30% weight), service quality (15% weight), overall experience (15% weight)
- Composite score calculated as weighted average and displayed immediately after ratings are entered
- Individual component scores visible alongside the composite in visit detail and list views

### Notes:
- Weights are fixed at 40/30/15/15 for MVP, stored as constants (not user-configurable) with a clear path to make them configurable if usage data shows demand.
- Service quality (OQ-10) complements the employee/server name + note fields in FR-2 by providing a numeric rating dimension; employee info is still captured as free-text for contextual detail.
- Value-for-money remains in the composite at 30% (OQ-9 resolved): it serves dual purpose as both a cost-quality signal and a component of the overall composite score. Cost tracking data (meal total, tip %, line items) provides additional granularity for value analysis beyond the composite rating.

---

## FR-4: Return intent flag (Must Have)

**Realizes:** US-4.

### Consequences (testable):
- Binary toggle (yes/no) presented during visit logging, labeled "Would I come back?"
- Flag stored with the Visit and filterable in list views

---

## Open Questions Resolved by This Shard

| # | Question | Status | Answer |
|---|----------|--------|--------|
| OQ-6 | Should the app support multiple restaurants with the same name at different addresses? | **✅ Resolved** | Yes — restaurant uniqueness is `(name, address)` tuple. Disambiguation picker shown if needed. |
| OQ-7 | What happens if a user wants to log a visit to a restaurant not yet in their database? | **✅ Resolved** | Logging auto-creates the Restaurant during the ≤30-second flow — no separate "Add Restaurant" screen. |
| OQ-9 | Should "value for money" remain in the composite score, or be decoupled since FR-2 tracks cost data separately? | **✅ Resolved** | Value-for-money retained at 30% in composite (FR-3). Serves dual purpose: composite scoring component + quick value signal. Cost tracking data provides additional granularity for deeper value analysis beyond the composite rating. |
| OQ-10 | Should "service quality" be added as a fourth rating dimension? | **✅ Resolved** | Added as fourth slider at 15% weight in FR-3 (40/30/15/15). Complements employee/server name + note fields in FR-2 — numeric rating for quick scoring, free-text for contextual detail. |

---

*See [PRD Index](prd-index.md) for the full PRD.*
