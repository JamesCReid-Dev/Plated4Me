# SPEC: Plated4Me

**Version:** 1.0  
**Date:** November 3, 2026  
**Status:** Draft  

---

## Why

When I'm about to visit a restaurant or store, I want to read my past insights so that I can decide whether to go in or select another place.

This app solves three core problems:
1. **Unreliable external information** — Online reviews and staff knowledge about food allergies are inconsistent; a personal verified record is needed
2. **Emotional pain of wasted spending** — Feeling "ripped off" when portion size, quality, or price don't align
3. **Memory gaps** — Forgetting good experiences or repeating bad ones

---

## Capabilities

### CAP-1: Quick Visit Logging
The app enables logging a visit in under 30 seconds using voice notes, photos, and quick slider ratings. Users capture impressions while walking out, not later from memory.

### CAP-2: Itemized Cost Tracking
Users can track individual item costs (meal, drink, beer) rather than just the total bill, enabling granular value analysis per item type.

### CAP-3: Weighted Rating System
Visits are rated using a weighted criteria system: 40% food quality, 40% portion size vs. price, 20% overall experience (ambiance, service).

### CAP-4: Return Intent Flag
A binary "Would I come back?" yes/no flag provides a quick signal for future decision-making.

### CAP-5: Allergy-Safe Database
Per-restaurant safe foods list that updates over time as the user visits and confirms what was safely consumed.

### CAP-6: Food Journal
Users log what they ordered at each visit along with impressions (e.g., how food tasted at bite 1 vs bite 5).

### CAP-7: Favorites Collection
Auto-surfaced favorites by category when the user needs recommendations.

### CAP-8: Occasion Tagging
Visits are tagged by context: date night, quick lunch, family dinner, business meal, etc., enabling filtered retrieval.

### CAP-9: Object-Based List View with Filters
A filterable list view supports filtering by cuisine type, price range, rating, occasion, and allergy-safe status.

### CAP-10: Random Cuisine Suggestion
Users can request a random restaurant suggestion filtered by cuisine type (Italian, Indian, etc.), with an indicator showing whether it's a new place or already visited.

### CAP-11: Discovery Map
A visual map shows the history of visited places using a fog-of-war style — areas clear as the user visits more locations.

### CAP-12: Game Layer (Optional Enhancement)
Achievement badges, stats dashboard, and quest prompts gamify exploration. Examples: "Food Explorer" badge for visiting 10 cuisine types, "Value Hunter" for finding great portion-to-price ratios.

### CAP-13: Blacklist / Avoid List
Users can mark places to never return to due to bad experiences, allergies, or poor value.

---

## Constraints

| ID | Constraint |
|----|------------|
| C1 | Platform: Mobile application built with Flutter |
| C2 | Single-user only — no multi-user accounts, sharing, or social features |
| C3 | All data stored locally on the user's device |
| C4 | Logging must take under 30 seconds to complete |
| C5 | No server infrastructure required — fully offline capable |

---

## Non-Goals

- Multi-user accounts or collaborative features
- Social sharing of reviews (no Yelp, no public profiles)
- Integration with restaurant reservation systems
- Automated price scraping from menus
- AI-generated review summaries
- Location-based notifications (not in v1)

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
| OQ-4 | How should the discovery map handle places in different cities or countries? | ✅ Resolved | Use a threshold distance based on location, configurable via settings feature. |
| OQ-5 | Should the game layer be enabled by default or opt-in? | Open | TBD |

---

## Companion Files

- `.memlog.md` — Append-only decision log (canonical source for this spec)
- `_bmad-output/brainstorming/plated4me-app/.memlog.md` — Source brainstorming session log
