---
title: PRD — Browse & Discover
created: 2026-11-08
updated: 2026-11-08
status: final — post-review decisions applied (C1–S4 resolved)
parent: prd-index.md
---

# PRD: Browse & Discover

*FR-9, FR-10, FR-11, FR-17*

**Realizes:** US-9, US-11, US-13, UJ-2.

---

## FR-9: Filterable list view (Must Have)

**Realizes:** US-9, UJ-2.

### Consequences (testable):
- List view displays Visits as cards with key info: Restaurant name, date, composite score, return intent flag
- Filter controls for: cuisine type, price range, rating, occasion, allergy-safe status. Cost-related filters (tip %, meal total range) are excluded from MVP — they require additional UI complexity and are not core to the dining decision use case.
- Results update within one frame (~16ms) of filter change
- Default sort: most recent first

---

## FR-10: Blacklist / avoid list (Should Have)

**Realizes:** US-11.

### Consequences (testable):
- Blacklist toggle available during visit logging and from Visit detail view
- Reason for blacklisting stored and displayed (free text with suggested categories: bad experience, allergy reaction, poor value, overpriced)
- Blacklisted visits excluded from favorites auto-detection computation (blacklisting a visit does not blacklist the entire Restaurant; the Restaurant remains browsable and can still be revisited); also excluded from random suggestions (FR-18, post-MVP)

---

## FR-11: Full-text search (Must Have)

**Realizes:** US-13.

### Consequences (testable):
- Search bar at top of list view
- Searches across: Restaurant name, address, voice note transcripts, journal dish names, journal notes, occasion tags, employee/server names, restaurant general notes
- Results ranked by relevance (most relevant first); simple full-text matching with field weighting (Restaurant name weighted higher than notes) — BM25 or equivalent if library permits, otherwise basic term frequency `[ASSUMPTION: The expected data volume (<500 Restaurants, <2000 Visits) is small enough that even basic term-frequency search feels instant on a modern smartphone]`
- Relevance model (highest to lowest priority): exact restaurant name match > partial name + address match > employee/server name match > journal dish name match > voice transcript / journal note match > restaurant general notes match > occasion tag match > general visit notes match. Field weights are fixed for MVP; tuning if needed is deferred based on usage data.
- Search highlights matching text in results

---

## FR-17: Restaurant general notes (Should Have)

**Realizes:** US-3.

### Consequences (testable):
- Each Restaurant has an editable general notes field (free-text) that persists across all Visits
- Notes are stored at the Restaurant level and visible from both the Restaurant detail view and any associated Visit
- During visit logging, existing restaurant notes appear as a pre-populated expandable section the user can edit or clear
- General notes are included in full-text search results (FR-11)

### Notes:
- This is a standalone feature restored from original v3.0 US-3/FR-3, which was absorbed into FR-2 during BMAD reformatting. Persistent restaurant-level notes differ from per-visit journal entries (FR-6): restaurant notes capture enduring information ("best patio seating in summer," "call ahead on weekends") that applies to the establishment as a whole, not just one visit.

---

*See [PRD Index](prd-index.md) for the full PRD.*
