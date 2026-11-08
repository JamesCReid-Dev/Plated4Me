---
title: PRD — Risks & NFRs
created: 2026-11-08
updated: 2026-11-08
status: final — post-review decisions applied (C1–S4 resolved)
parent: prd-index.md
---

# PRD: Risks & Non-Functional Requirements

*NFRs, Constraints (detailed), Risks*

---

## 8. Non-Functional Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| NFR-1 | Platform: Mobile application for iOS and Android | Must Have | Flutter framework (decision resolved) |
| NFR-2 | Single-user only | Must Have | No multi-user accounts, sharing, or social features |
| NFR-3 | All data stored locally on device | Must Have | No cloud sync; fully offline |
| NFR-4 | Fully offline capable | Must Have | No server infrastructure required |
| NFR-5 | Logging flow ≤30 seconds from open to save | Must Have | Core fields only: name, address, four ratings, return intent; optional sections (meal total, tip, employee info, line items, journal) expandable but never block save |
| NFR-6 | Search latency <200ms for full-text search across local data | Should Have | Must feel instant on target device |
| NFR-7 | App cold start <2 seconds (first launch and subsequent opens) | Should Have | Measured from app icon tap to first visible screen |

---

## 9. Constraints (Detailed)

| ID | Constraint | Notes |
|----|------------|-------|
| C1 | Mobile application only (iOS + Android via Flutter) | Platform decision resolved; no web or desktop in v1 |
| C2 | Single-user only — no multi-user accounts, sharing, or social features | Architectural simplification: no auth, no user management |
| C3 | All data stored locally on the user's device | No cloud sync in v1; JSON export available for backup (FR-16) |
| C4 | Logging must take under 30 seconds to complete | Drives UX design: core fields first, optional sections expandable |
| C5 | No server infrastructure required — fully offline capable | Voice transcription uses on-device APIs only during MVP; GPS/location services deferred to post-MVP (OQ-11) |

---

## 10. Risks & Mitigations

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|------------|------------|
| R1 | Voice transcription fails or is inaccurate in noisy restaurant environments | High | Medium | Make voice optional; allow text-only logging as fallback. If transcription fails, user can still add manual notes. |
| R2 | Data loss — fully offline means no backup if device is lost or app is uninstalled | High | Low-Medium | Provide JSON data export in Settings (FR-16). Encourage periodic backup during onboarding. |
| R3 | Logging flow exceeds 30 seconds due to UI complexity | Medium | Medium | Timebox MVP logging screens. Use progressive disclosure: show only essential fields first, advanced options expandable. |
| R4 | Hive schema migration issues as data model evolves | Medium | Medium | Version the data schema explicitly. Test migrations with sample data before each release. |
| R5 | User abandons app after a few visits because logging feels like a chore | High | Medium | Keep MVP logging minimal (name, rating, return intent). Defer itemized costs and journal to expandable sections. Four-rating dimensions (food, value, service, overall) kept as compact sliders — no free-text rating fields. |
| R6 | Discovery map performance degrades with many locations | Low-Medium | Low | Defer to v2.0; implement lazy loading for markers if needed. |
| R7 | Logging complexity exceeds 30-second target due to accumulated optional fields (meal total, tip %, employee info, voice notes, photos) | High | Medium | Progressive disclosure: collapsible sections for FR-2 (line items, meal total, tip, employee), FR-5 (allergy-safe foods), FR-6 (journal). "Quick log" mode captures only required fields (name, four ratings, return intent) in ≤10 seconds. Optional sections expandable but never block the save action. |
| R8 | Four rating dimensions add cognitive load vs. original three | Medium | Low-Medium | Service quality (OQ-10) is intuitive for dining (staff attentiveness, accuracy of order). Sliders are compact and fast; pilot-test with 3–5 users to confirm ≤30s target still holds with four sliders instead of three. |

---

*See [PRD Index](prd-index.md) for the full PRD.*
