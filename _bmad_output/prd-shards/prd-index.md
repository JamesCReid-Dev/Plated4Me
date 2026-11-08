---
title: PRD Index — Plated4Me
created: 2026-11-08
updated: 2026-11-08
status: final — post-review decisions applied (C1–S4 resolved)
---

# PRD: Plated4Me

*Personal restaurant visit log — mobile app built in Flutter.*

## Document Purpose

This PRD defines the requirements for **Plated4Me**, a personal mobile application for logging and reviewing restaurant/food experiences. It is intended for the sole stakeholder (the product owner, James Reid) and serves as the canonical input for downstream UX design, architecture, and sprint planning.

**Post-review decisions (2026-11-08):** Composite score weights reverted to 40/30/30 (§C1). Original v3.0 cost model restored — manual meal total + tip % + employee/server tracking (§C2). Service quality added as fourth rating dimension at 15% weight (40/30/15/15) (§C3/OQ-10). Value-for-money retained in composite at 30% (§C3/OQ-9). GPS/location auto-population deferred to post-MVP (§C3/OQ-11). Restaurant identity simplified to `(name, address)` tuple (§S2). Blacklist moved from per-Restaurant to per-Visit (§S4).

---

## 1. Vision

Plated4Me is a personal mobile app that helps you make better dining decisions by maintaining a verified, private record of your past restaurant visits. When you open it before walking into a new or returning establishment, you should be able to decide within 10 seconds — confidently walk in because your own data supports it, or choose elsewhere to avoid repeating a bad experience.

Online reviews are unreliable and staff knowledge about food allergies is inconsistent. The emotional pain of being "ripped off" on portion size, quality, or price is real and repeatable. Plated4Me solves this by putting **your** verified record front and center — no noise, no social features, no algorithmic opinions. Just your own data, organized and searchable, in under 30 seconds from open to save.

This is a single-user, fully offline product. No cloud sync, no accounts, no server infrastructure. The app lives on your device and belongs entirely to you.

---

## 2. Target User

### Jobs To Be Done

- **Before I go out to eat:** "Show me what happened the last time I was here — was the food good? Were portions worth the price? Would I come back?"
- **While I'm at the restaurant:** "I need to log this experience quickly before I forget, without spending 10 minutes filling out forms."
- **When planning a specific occasion:** "Where's a place for a date night / family dinner / business meal that was actually good?"
- **Managing food allergies:** "What foods have I confirmed are safe for me to eat at this restaurant?"

### Key User Journeys

**UJ-1. James logs a visit right after eating.** — See [PRD: Quick Visit Logging](prd-quick-log.md)

**UJ-2. James decides where to eat using search and filters.** — See [PRD: Browse & Discover](prd-browse.md)

**UJ-3. James sets up Plated4Me on first launch.** — See [PRD: Setup & Configuration](prd-setup.md)

---

## 3. Glossary

| Term | Definition |
|------|-----------|
| **Allergy-Safe Database** | Per-Restaurant list of foods confirmed safe for the user to consume, updated over time as the user visits and verifies. |
| **Blacklist** | User-curated list of places they never want to return to, with reasons stored (bad experience, allergy reaction, poor value, overpriced). Blacklisted places are excluded from suggestions. |
| **Composite Score** | Weighted rating for a Visit: food quality × 40% + value for money × 30% + service quality × 15% + overall experience × 15%. Expressed on the user's chosen scale (5-star or 10-star). |
| **Favorites Collection** | Auto-surfaced list of highly-rated restaurants grouped by cuisine type or occasion, plus any manually pinned entries. Serves as the default landing view when no recent visits exist. |
| **Food Journal** | Per-Visit log of individual dishes ordered, with free-text impressions (e.g., "great at first, soggy by bite 5"). |
| **Occasion Tag** | Context label applied to a Visit (date night, quick lunch, family dinner, business meal). Predefined tags available; user can create custom tags. |
| **Restaurant** | A dining establishment identified uniquely by the `(name, address)` tuple. Two entries with the same name but different addresses are distinct Restaurants. A Restaurant has many Visits and one Allergy-Safe Database. |
| **Visit** | A single dining experience at a Restaurant, logged as one entry containing ratings (food quality, value for money, service quality, overall experience), composite score, return intent flag, optional voice notes, photos, journal entries, line items, meal total, tip %, employee/server info, and blacklist status. |
| **VisitItem** | An individual line item within a Visit (e.g., "Margherita Pizza" at $14.50), representing a specific dish or drink ordered. |

---

## 7. Success Metrics

**Primary**
- **SM-1: Weekly active logging rate** — % of weeks where the user logs ≥1 Visit. Target: ≥60% of weeks in the first 8 weeks after onboarding. Validates FR-1, FR-9. *Counter-metric SM-C1:* Do not optimize for total Visit count at the expense of data quality.

**Secondary**
- **SM-2: Time-to-decision** — Average time from opening the app to making a dining decision (logging or looking up past Visits). Target: ≤10 seconds. Validates FR-9, FR-11.
- **SM-3: Onboarding completion rate** — % of first-time users who complete the full onboarding flow vs. skipping. Target: ≥80% complete all steps. Validates FR-14.

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

## PRD Shards Index

| Shard | File | Covers |
|-------|------|--------|
| Quick Visit Logging | [prd-quick-log.md](prd-quick-log.md) | FR-1, FR-2, FR-3, FR-4 + UJ-1 |
| Allergy Management | [prd-allergy.md](prd-allergy.md) | FR-5 |
| Food Journal | [prd-journal.md](prd-journal.md) | FR-6 |
| Favorites & Occasions | [prd-favorites.md](prd-favorites.md) | FR-7, FR-8 |
| Browse & Discover | [prd-browse.md](prd-browse.md) | FR-9, FR-10, FR-11, FR-17 |
| Setup & Configuration | [prd-setup.md](prd-setup.md) | FR-14, FR-16 |
| Post-MVP Features | [prd-post-mvp.md](prd-post-mvp.md) | FR-18, FR-19, FR-20 |
| Data Model | [prd-data-model.md](prd-data-model.md) | §13 entities + relationships |
| Risks & NFRs | [prd-risks-nfrs.md](prd-risks-nfrs.md) | NFRs, Constraints (detailed), Risks |

---

## Appendix: Companion Files

- `planning_artifacts/prd-plated4me-app.md` — Source PRD (v2.0, Draft) from which this BMad-formatted document was derived
- `_bmad_output/review-rubric.md` — Quality review against the bmad-prd rubric
