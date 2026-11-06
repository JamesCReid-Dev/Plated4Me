# BMad Review — PRD v3.0 (Plated4Me)

**Document:** `planning_artifacts/prd-plated4me-app.md`  
**Review Date:** November 6, 2026  
**Reviewer:** BMad Review Lenses (Adversarial, Edge-Case Hunter, Structure, Prose)  
**Status:** Findings exported for backup — not yet resolved

---

## Lens 1: Adversarial — What's Missing or Weak

| # | Location | Trigger Condition | Guard Snippet | Potential Consequence |
|---|---|---|---|---|
| A-1 | §2 Release Plan / MVP table | US-2b has non-standard ID; no explicit FR↔US traceability note. FR-2b exists but numbering scheme (US-2b, US-13–US-16) breaks sequential mapping. | **RESOLVED:** All US/FR IDs renumbered sequentially (US-1 through US-17 for MVP + post-MVP). Added explicit traceability note in §2: "Each user story (US-N) maps 1:1 to a functional requirement (FR-N)." Future releases table updated to reference US-15, US-16, US-17. |
| A-2 | §5 Data Model — Visit entity | `portionPriceRating` field exists but rating dimension was renamed from "portion size vs. price" to "value for money" in US-3 and FR-3. Field name is stale. | **RESOLVED:** Renamed to `valueForMoneyRating`. Updated all references: Glossary (Composite Score, Visit), FR-1, FR-3, OQ-8, and §13 Data Model. | Architect/Developer will implement a field whose name contradicts stated requirements, causing confusion during implementation. |
| A-3 | §5 Data Model — Visit entity | `compositeScore` stored as persisted number but recalculated from three slider inputs. No explicit note about when it's calculated vs. stored. | **RESOLVED:** Added design decision preamble to §13: "`compositeScore` calculated at write time and re-derived if any input rating changes — not stored as an independent source of truth." Also added Structure lens preamble covering UUID keys, optional location fields, and composite score behavior. | Stale composite scores after rating edits — data inconsistency between inputs and derived value. |
| A-4 | §3 US-1 AC | ≤30-second logging constraint mentioned but no explicit required/optional field matrix. Meal total, tip %, employee info labeled optional — what about ratings? Are all three sliders required or optional? | **RESOLVED:** Added Required / Optional Fields table to FR-1 section with 8 fields explicitly classified (name: required, address: conditional, all 3 ratings + return intent: required, voice/photo: optional). Also fixed stale "portion vs price" → "value for money" in UJ-1 and updated FR-3 Notes to match OQ-8 resolution. | Developer may make too many fields required (slowing logging) or too many optional (producing unusable data). |
| A-5 | §3 US-7 Favorites Collection | Auto-detection uses `compositeScore ≥ 80% of max scale`. If user changes rating scales (1–5 vs. 1–10) or weights, threshold may need adjustment. No mention of scale normalization. | **RESOLVED:** Added AC bullet to FR-7: "When the user changes their rating scale in Settings, all existing composite scores are re-derived and auto-detection rules re-run; restaurants that cross the threshold are automatically added to or removed from Favorites (manual pins always take precedence over auto-detection)." Also partially resolves E-8 (manual unpin vs. auto-add precedence). | Threshold becomes incorrect after a scale preference change; favorites auto-detection breaks silently. |
| A-6 | §3 US-9 List View | Filters listed: "cuisine type, price range, rating, occasion, allergy-safe status." No filter for value-for-money or tip/employee data from US-2b. | **RESOLVED:** Added clarifying bullet to FR-9 AC: "Cost-related filters (tip %, meal total range) are excluded from MVP — they require additional UI complexity and are not core to the dining decision use case." | User expects to filter on new financial data; gap creates frustration when not found. |
| A-7 | §8 Risks — R5 | "User abandons app after a few visits because logging feels like a chore" — mitigation says "Keep MVP logging minimal." But logging now includes: name, location (5+ fields), meal total, tip %, employee name + note, 3 rating sliders, return intent, optional voice/photo. Scope creep is real and not addressed. | **RESOLVED:** Added risk R7 to §10 Risks table with mitigation: progressive disclosure via collapsible sections for FR-2/FR-5/FR-6, plus "quick log" mode capturing only required fields in ≤10 seconds. Optional sections expandable but never block save action. | The app becomes too slow to use, undermining the core value proposition. |
| A-8 | §5 Data Model — Restaurant entity | `formattedAddress` documented as computed/read-only but no specification of *how* it's composed (locale ordering, null handling, separator). | **RESOLVED:** The `formattedAddress` field was removed from the PRD in favor of a single plain-text `address: string` on the Restaurant entity. Display formatting is an implementation detail handled by the presentation layer — no composition algorithm needed in the PRD. | Inconsistent address display across list cards, detail views, and search results. |
| A-9 | §3 US-2b Restaurant General Notes | No mention of whether general notes are visible during visit logging or only in restaurant detail view. AC says "editable during visit logging" but doesn't specify the UI touchpoint. | **RESOLVED:** Added note to FR-2: "Restaurant general notes (if any exist for the selected restaurant) appear as an expandable 'Restaurant Notes' section in the logging form, pre-populated with existing notes. The user can edit or clear them during logging." | Developer may implement it only in detail view, contradicting the AC. |
| A-10 | §9 OQ-8 | Resolved to "fixed 40/30/30 for MVP; make configurable in v2 if needed" — creates a dependency on v2 that may never materialize. If weights are wrong, no way to adjust without a release. | Change resolution: "Fixed 40/30/30 for MVP. Weights stored as constants (not user-configurable) with a clear path to make them configurable if usage data shows demand." | False promise of configurability; technical debt when someone expects it in v2. |
| A-11 | §5 Data Model — Visit entity | No field for `cuisineType` on Visit. Cuisine is only on Restaurant, but a restaurant can change cuisine over time. Per-visit cuisine would let user rate "the pasta night" vs. "the sushi night." | **RESOLVED:** Excluded from MVP. Added note to Visit entity in §13: "Cuisine type is stored on Restaurant, not Visit. Per-visit cuisine excluded from MVP — a restaurant's cuisine rarely changes, and adding it would increase logging form complexity." | User can't distinguish between different cuisine experiences at a returning restaurant that changed its offering. |
| A-12 | §3 US-15 Full-Text Search | Search scope expanded to include all granular location fields, employee names, and general notes — but no mention of search result ranking or relevance scoring. How are results ranked when multiple fields match? | **RESOLVED:** Added explicit relevance model to FR-15 AC: "exact restaurant name match > partial name + city match > journal dish name match > voice transcript / journal note match > general visit notes match." Field weights fixed for MVP; tuning deferred based on usage data. | Search returns irrelevant results at the top; user loses trust in the feature. |

---

## Lens 2: Edge-Case Hunter — Unhandled Behavioral Paths

| # | Location | Unhandled Path / Condition | Consequence if Triggered |
|---|---|---|---|
| E-1 | US-1 AC (auto-create) | User enters restaurant name with no address/location fields filled. Identity tuple `(name, street, city, state)` would match every restaurant since all location fields are null and equal. | Every matching restaurant appears in disambiguation picker — overwhelming the user; wrong pick misattributes all data. | **RESOLVED:** Added AC bullet to FR-1: "If the entered restaurant name matches an existing Restaurant that has no address/location fields filled, the user must provide at least one location field (street, city, or state) before proceeding — name-only matching against null-location entries is not permitted." Also partially addresses E-6 (GPS denied + no manual fallback). |
| E-2 | US-1 AC (disambiguation) | Two restaurants have same `(name, street, city)` but different `state` values. Disambiguation shows ≤3 options sorted by most recent visit. If 5+ matches across states, user can't find target. | User picks wrong restaurant; all subsequent data is misattributed. |
| E-3 | US-2b (meal total) | User enters meal total but no line items. Or enters line items with individual prices that don't sum to the meal total. No guidance on relationship between them. | Confusion: are per-item prices additive? Do they need to match? Data inconsistency. |
| E-4 | US-2b (tip %) | User tips in dollars instead of percentage, or enters 30 thinking it means $3 not 30%. No input format guidance. | Incorrect tip data stored; future service analysis is corrupted. |
| E-5 | US-2b (employee) | User enters employee name but no note, or vice versa. Is the employee name required if there's a note? No cardinality defined. | Inconsistent data: some visits have names without notes, others have notes without names. |
| E-6 | §5 Data Model — GPS | Device location permission denied (OQ-11). User logs visit at "Joe's Pizza" in NYC but GPS fails and no street/city/state filled either. Restaurant identity becomes just `name`. | Every "Joe's Pizza" matches; disambiguation is impossible. | **RESOLVED:** Added AC bullet to FR-1: "When GPS location is unavailable or permission denied, the logging form requires manual entry of at least one location field (street, city, or state) if the restaurant name matches any existing entry — this prevents ambiguous identity resolution." Complements E-1 validation (which handles new restaurants with no existing matches). Together, E-1 + E-6 cover both branches of the GPS-denied edge case. |
| E-7 | US-9 (filters) | User filters by "allergy-safe status = true." Allergy-safe database is per-restaurant, not per-visit. A restaurant may have some safe foods and some unsafe. Filter semantics ambiguous. | Filter doesn't answer the user's actual question; misleading results. |
| E-8 | US-7 (favorites) | Restaurant meets auto-detection criteria but user manually unpinned it as a favorite. AC says "manual pins are always respected" — does manual unpin override auto-detection? Implied but not explicit. | Unclear precedence: does auto-add re-pin after manual unpin? |
| E-9 | US-13 (blacklist) | Blacklisted restaurant is later visited again (user forgets, or visits for a different reason). What happens — does the app warn? Does it still log the visit? Is blacklist status resettable? | No guidance on post-blacklist behavior; user may lose data or get confused. |
| E-10 | §5 Data Model — JournalEntry | `rating` is optional per-dish, but no relationship between a JournalEntry and a VisitItem (same dish could be both). If user logs "Margherita Pizza" as both line item (cost) and journal entry (impressions), are they linked? | Duplicate entries for the same dish; no way to correlate cost with impressions. |
| E-11 | US-2b (restaurant notes) | User edits general notes from a visit logging form that's auto-creating a *new* restaurant. Notes written to a Restaurant record that doesn't exist yet in the database. Is the note persisted if creation fails? | Lost notes on failure; inconsistent state between Visit and Restaurant. |
| E-12 | §5 Data Model — AllergySafeFood | `confirmedAt` is set when food added, but no field for *when it was last confirmed* or *when it was disproven*. A food safe 3 years ago and never tested again may not actually be safe. | Stale allergy data gives false confidence; potential health risk. |

---

## Lens 3: Structure — Pyramid Model Evaluation

**Model:** Strategic/Context (Pyramid) — conclusion/status first, grouping logical, most critical info first, MECE arguments.

| Pass | Original Text | Disposition | Changes |
|---|---|---|---|
| structure | §2 Release Plan lists MVP features before §1 Problem Statement is fully restated in release context | QUESTION | The problem statement (§1) and success criteria (§1.2) are well-placed, but the MVP table in §2 doesn't reference them explicitly. Consider adding a one-line bridge: "MVP delivers on the three problems stated in §1.1 by..." | saves 0 words, improves flow |
| structure | §3 User Stories (14 stories across two subsections) followed immediately by §4 Functional Requirements which duplicates the same information in table form | MERGE | The US→FR duplication is intentional for traceability but creates a scanning burden. Consider collapsing to a single table with columns: `ID \| Type (US/FR) \| Description \| Priority \| Notes` — or keep separate but add a cross-reference note. | saves ~80 words, improves scanability |
| structure | §5 Data Model is the longest single section (~75 lines of entity definitions) with no accompanying narrative explaining design decisions | CONDENSE | The entity trees are clear but dense. Add a brief preamble: "Key design decisions: (1) UUID primary keys for offline-first independence, (2) all location fields optional to support name-only logging, (3) compositeScore calculated at write time." | saves ~40 words, improves comprehension |
| structure | §8 Risks lists 6 risks but doesn't include any risk from the new US-2b / GPS features introduced in v3.0 | MOVE | Add a risk for GPS location permissions and a risk for the expanded logging form complexity. These are direct consequences of recent changes and should be visible before architecture work begins. | — |
| structure | §9 Open Questions has OQ-1 through OQ-11 with mixed resolved/open status | CONDENSE | Group into "Resolved" (strikethrough or collapsed) and "Open" sections. Currently they're interleaved, making it hard to see what still needs decisions before architecture/UX work. | saves ~20 words of scanning effort |
| structure | §12 Appendix A Glossary has 10 entries but no cross-references between related terms | PRESERVE | The glossary is well-organized alphabetically. No structural change needed — it serves its purpose as a quick lookup. | — |

---

## Lens 4: Prose — Copy Editing

| Pass | Original Text | Revised Text | Changes |
|---|---|---|---|
| prose | US-2 AC line 3: "User enters a **tip percentage** (%) during visit logging" | "User enters a tip percentage (%) during visit logging" | Bold on "tip percentage" is redundant with surrounding bold in the user story statement. Remove inline emphasis. | saves ~5 chars, reduces visual noise |
| prose | US-2 AC line 7: "Line items without a price do not affect the meal total — they serve as dish memory, not cost accounting" | "Line items without a price do not affect the meal total; they serve as dish memory, not cost accounting." | Replace em-dash with semicolon for formal tone consistency. | minor style fix |
| prose | US-9 title: "Object-Based List View with Filters" | "Filterable List View with Cards" | "Object-based" is implementation terminology; users think in cards or entries. Match the language of the user, not the developer. | improves user-centricity |
| prose | FR-2 description: "Meal cost & tip tracking (manual meal total, optional per-item price, tip %, employee name + note)" | "Meal cost and tip tracking (manual meal total, optional per-item price, tip percentage, employee name and note)" | Expand ampersands and abbreviations for formal document tone. | style consistency |
| prose | FR-2b description: "Restaurant general notes (persistent across visits, searchable)" | "Restaurant general notes (persistent across visits; included in search results)" | "Searchable" is vague — specify *where* it's searchable. | improves precision |
| prose | OQ-6 answer: "Two 'Starbucks' on different streets (or even in different cities/states) are distinct restaurants." | 'Two "Starbucks" locations on different streets (or in different cities or states) are distinct restaurants.' | Remove parenthetical for cleaner flow; use "locations" to clarify we mean physical establishments. | improves readability |
| prose | Glossary — Visit definition: "...logged as one entry containing ratings, photos, voice notes, meal total, tip %, and employee/server info" | "...logged as one entry containing ratings, photos, voice notes, meal total, tip percentage, and server/employee information." | Expand abbreviations for consistency with Microsoft Writing Style Guide. | style consistency |

---

## Summary

**Adversarial lens:** 12 findings — all resolved. A-1 through A-12 complete.

**Edge-Case Hunter:** 12 findings — the most critical remaining is E-12 (stale allergy data is a health risk). E-1 and E-6 resolved.

**Structure lens:** 5 findings — mostly about duplication (US↔FR tables) and organization (open questions interleaved with resolved). No major structural flaws.

**Prose lens:** 7 findings — all minor style/consistency fixes. The document's voice is clear and professional throughout.

**Overall verdict:** The PRD is in good shape for v3.0. All 12 adversarial findings and the two most critical edge-case findings (E-1, E-6) have been resolved. Remaining open items are: one remaining high-priority edge case (E-12 — stale allergy data), structural organization improvements (grouping Open/Resolved OQs), and minor prose consistency fixes. These should be addressed before passing to architecture or epic/story creation.

---

*This file was auto-exported from a BMad review run. Do not edit manually — changes belong in the PRD itself.*
