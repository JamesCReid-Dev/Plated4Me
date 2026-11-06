# Plated4Me — Brainstorming Session Summary

**Date:** November 3, 2026  
**Session Type:** Creative Partner Brainstorming  
**Techniques Used:** Job to Be Done → SCAMPER → Cross-Pollination → Worst Possible Idea  

---

## Product Overview

**Project Name:** Plated4Me  
**Platform:** Mobile (Flutter)  
**User Base:** Single-user personal app  
**Core Purpose:** Track restaurants and stores visited, rate different criteria, and make informed decisions about future visits.

---

## Job to Be Done

> *"When I'm about to visit a restaurant or store, I want to read my past insights so that I can decide whether to go in or select another place."*

---

## Rating Weights

| Factor | Weight |
|--------|--------|
| Food quality | 40% |
| Portion size vs. price | 40% |
| Overall experience (ambiance, service) | 20% |

---

## Pain Points Uncovered

1. **Food allergies** — Online info and staff knowledge are unreliable; needs a personal verified record of safe foods per location
2. **"Ripped off" feeling** — Emotional pain of wasting money on bad value experiences
3. **Memory gaps** — App serves as an external memory system to avoid repeating bad decisions

---

## Feature List (13 Items)

### Core Logging & Tracking
1. **Quick 30-second logging** — Voice notes + photo + quick sliders for fast post-visit entry
2. **Itemized cost tracking** — Track individual item costs (meal, drink, beer) not just total bill
3. **Weighted ratings per visit** — Rate using the 40/40/20 weighted criteria
4. **"Would I come back?" binary flag** — Quick yes/no for future reference

### Food & Allergy Management
5. **Allergy-safe database** — Per-restaurant safe foods list that updates over time
6. **Food journal** — Log what you ordered + impressions (bite 1 vs bite 5)

### Organization & Discovery
7. **Favorites collection** — Auto-surfaced by category when needed
8. **Occasion tagging** — Tag visits as date night, quick lunch, family dinner, business meal
9. **Object-based list view** — Filterable by cuisine, price, rating, occasion, allergy status
10. **Random suggestion by cuisine type** — Pick Italian, Indian, etc., get a random place with "new" or "visited" indicator

### Visual & Gamification
11. **Discovery map** — Visual history of visited places (fog-of-war style clearing)
12. **Game layer** — Achievement badges, stats dashboard, quest prompts
13. **Blacklist/avoid list** — Places to never return to due to bad experiences

---

## Key Design Decisions

- **Voice-first logging** — Capture impressions while walking out, not later from memory
- **Itemized costs** — Granular value analysis per item type (meal vs drink)
- **Dual view modes** — Object-based filterable list + visual discovery map
- **Game layer is optional enhancement** — Core utility comes first

---

## Next Steps

1. Create SPEC.md with detailed requirements
2. Define Flutter architecture
3. Break into epics and user stories
4. Begin sprint planning
