---
title: PRD — Post-MVP Features
created: 2026-11-08
updated: 2026-11-08
status: final — post-review decisions applied (C1–S4 resolved)
parent: prd-index.md
---

# PRD: Post-MVP Features

*FR-18, FR-19, FR-20*

**Realizes:** US-10, US-11, US-12.

---

## FR-18: Random cuisine suggestion (Could Have — Release 1.5)

**Realizes:** US-10.

### Consequences (testable):
- "Random Suggestion" button/feature available from the main browse view
- Filterable by cuisine type before generating suggestion
- Indicator showing whether the suggested Restaurant is new (never visited) or already in the user's history

---

## FR-19: Discovery map with fog-of-war (Could Have — Release 2.0)

**Realizes:** US-11. `[ASSUMPTION: The user will want to enable location services on their device for this feature; it is opt-in and not required for core functionality.]`

### Consequences (testable):
- Map view displays visited Restaurants with markers
- Fog-of-war effect: unvisited areas remain obscured
- Areas clear progressively as the user visits more locations
- Configurable threshold distance for city/country boundaries (Settings)

---

## FR-20: Game layer — achievements, stats, quests (Could Have — Release 2.5+)

**Realizes:** US-12.

### Consequences (testable):
- Achievement badges (e.g., "Food Explorer" for 10 cuisine types, "Value Hunter" for great portion-to-price ratios)
- Stats dashboard showing visit counts, average ratings, favorite cuisines
- Quest prompts suggesting new experiences
- **Opt-in feature** — user enables in Settings; default is disabled

---

*See [PRD Index](prd-index.md) for the full PRD.*
