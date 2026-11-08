---
title: PRD — Allergy Management
created: 2026-11-08
updated: 2026-11-08
status: final — post-review decisions applied (C1–S4 resolved)
parent: prd-index.md
---

# PRD: Allergy Management

*FR-5*

**Realizes:** US-5.

---

## FR-5: Allergy-safe database per Restaurant (Must Have)

### Consequences (testable):
- Per-Restaurant safe foods list maintained separately from individual Visits
- User can add or remove items from the safe foods list during visit logging
- Safe foods indicator shown in Restaurant detail view (count of confirmed safe foods, with ability to expand and view the full list)

### Notes:
- Severity levels for allergens are tracked at the User level (UserAllergen entity), not per-Restaurant. The Allergy-Safe Database stores only food names — severity context lives in Settings.

---

*See [PRD Index](prd-index.md) for the full PRD.*
