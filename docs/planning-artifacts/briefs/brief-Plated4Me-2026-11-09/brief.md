---
title: Plated4Me — Product Brief
status: draft
created: 2026-11-09
updated: 2026-11-09
---

# Plated4Me — Product Brief

## Vision

Plated4Me is a personal mobile app that helps you make better dining decisions by maintaining a verified, private record of your past restaurant visits. Open it before walking into an establishment and decide within 10 seconds — confidently walk in because your own data supports it, or choose elsewhere to avoid repeating a bad experience.

## The Problem

Online reviews are unreliable. Restaurant staff knowledge about food allergies is inconsistent. The emotional pain of being "ripped off" on portion size, quality, or price is real and repeatable. There's no simple way to track your own dining experiences across visits in a format that's quick to log and fast to search.

## What It Is

A single-user, fully offline mobile app (iOS + Android via Flutter) that lets you:
- Log restaurant visits in under 30 seconds with ratings, photos, voice notes, meal totals, and journal entries
- Track food allergies per restaurant with an allergy-safe foods list
- Discover favorite restaurants through search, filters, and auto-computed favorites
- Plan occasions (date night, family dinner, business meal) using occasion tags

## Target User

**James Reid** — the product owner. A food-conscious individual who dines out regularly and wants a personal, private record of experiences. Key jobs-to-be-done:
- **Before going out:** "Show me what happened last time I was here."
- **While at the restaurant:** "Log this quickly before I forget."
- **Planning an occasion:** "Where's a good place for a date night?"
- **Managing allergies:** "What foods are confirmed safe here?"

## Key Features (MVP)

| Area | What's Included |
|------|----------------|
| Visit Logging | Ratings (food 40%, value 30%, service 15%, overall 15%), photos, voice notes, meal total + tip, employee/server tracking |
| Allergy Management | Per-restaurant allergy-safe foods list, add/remove during logging |
| Browse & Search | Filterable card list, full-text search across all data, cuisine/rating/occasion/allergy filters |
| Favorites | Auto-surfaced (≥2 visits, avg composite ≥80%, ≥1 return "yes"), manual pin/unpin override |
| Food Journal | Per-dish impressions within visit logging |
| Onboarding | First-run guided setup: allergies, cuisine preferences, rating scale, default occasions |
| Settings | Allergy management, rating scale customization, JSON data export, blacklist management |

## Post-MVP (Parked)

- Random cuisine suggestions with discovery map (fog-of-war)
- Game layer: achievements, stats dashboard, quest prompts (opt-in)
- GPS/location auto-population
- Dark mode

## Constraints

- **Single-user only** — no accounts, no sharing, no social features
- **Fully offline** — all data stored locally on device via Isar; JSON export for backup
- **30-second logging target** — core fields first, optional sections expandable but never blocking
- **Light mode only** for MVP — dark mode reserved for post-MVP
- **No server infrastructure** required

## Success Metrics

| Metric | Target | Validates |
|--------|--------|-----------|
| Weekly active logging rate | ≥60% of weeks in first 8 weeks | Core logging flow usability |
| Time-to-decision | ≤10 seconds from app open to dining decision | Search, browse, and info density |
| Onboarding completion rate | ≥80% complete all steps | Onboarding flow clarity |

## Architecture Highlights

- **Framework:** Flutter 3.16+ (iOS + Android)
- **State Management:** Riverpod (`AsyncNotifierProvider`)
- **Storage:** Isar (local NoSQL, not Hive)
- **Architecture:** Clean Architecture — domain, application, infrastructure, presentation layers
- **Navigation:** Bottom nav bar (Browse, Favorites, Settings) + full-screen Quick Log modal

## Status & Next Steps

This brief is a **draft** based on existing PRD shards, architecture docs, UX designs, and epics. Pending review and finalization by the product owner.
