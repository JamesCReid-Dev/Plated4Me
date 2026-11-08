---
title: PRD — Favorites & Occasions
created: 2026-11-08
updated: 2026-11-08
status: final — post-review decisions applied (C1–S4 resolved)
parent: prd-index.md
---

# PRD: Favorites & Occasions

*FR-7, FR-8*

**Realizes:** US-7, US-8.

---

## FR-7: Favorites collection auto-surfaced (Must Have)

### Consequences (testable):
- Auto-detection rule: a Restaurant is automatically added to Favorites when it meets **all three** conditions across its Visit history:
  - At least **2 Visits** logged, AND
  - Average composite score ≥ **80% of the chosen scale maximum** (i.e., ≥4.0 on a 5-star scale, or ≥8.0 on a 10-star scale), AND
  - `returnIntent = true` on at least **1 of those Visits**
- When the user changes their rating scale in Settings, all existing composite scores are re-derived and auto-detection rules re-run; restaurants that cross the threshold are automatically added to or removed from Favorites (manual pins always take precedence over auto-detection)
- Manual override: user can pin/unpin any Restaurant as a favorite at any time (from Restaurant detail view or list card). Manual pins are always respected regardless of auto-detection score.
- Favorites grouped by cuisine type or occasion for easy browsing
- Favorites list is the default landing view when the user opens the app and no recent Visits exist

---

## FR-8: Occasion tagging (Should Have)

### Consequences (testable):
- Predefined occasion tags available during visit logging ("date night," "quick lunch," "family dinner," "business meal")
- User can add custom occasion tags at any time
- Visits filterable by occasion tag in list views

---

*See [PRD Index](prd-index.md) for the full PRD.*
