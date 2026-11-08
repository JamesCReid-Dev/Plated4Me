# UX Design Handoff — Plated4Me

**Source:** PRD shards (final, post-review 2026-11-08)  
**Target:** UX designer / design agent  
**Scope:** MVP (v1.0) — single-user, fully offline Flutter mobile app (iOS + Android)

---

## 1. Product Context

Plated4Me is a **personal restaurant visit log**. The sole user logs dining experiences in under 30 seconds and consults their own verified records before deciding where to eat. No social features, no cloud sync — just their data.

**Core Jobs To Be Done:**
- *"Before I go out: show me what happened last time I was here."*
- *"While at the restaurant: let me log this quickly before I forget."*
- *"When planning a specific occasion: where's a good date night / family dinner spot?"*
- *"What foods have I confirmed are safe for my allergies at this place?"*

**Design Constraints:**
- Mobile-first (iOS + Android)
- Logging flow ≤30 seconds (core path), ideally ≤10 seconds for quick log
- Single user — no auth screens, no onboarding complexity beyond first launch
- All data local — no loading states for network operations
- Progressive disclosure: essential fields always visible, optional sections expandable

---

## 2. Information Architecture

```
Plated4Me
├── Onboarding (first-run only)
│   ├── Food allergies (optional)
│   ├── Preferred cuisine types (~20 presets + custom)
│   ├── Rating scale preference (5-star or 10-star)
│   └── Default occasion tags
│
├── Home / Browse View (default landing)
│   ├── Search bar (full-text search across all fields)
│   ├── Filter controls (cuisine, price range, rating, occasion, allergy-safe)
│   ├── Visit cards list (restaurant name, date, composite score, return intent flag)
│   │   └── Default sort: most recent first
│   └── Favorites section (auto-surfaced when no recent visits exist)
│       └── Grouped by cuisine type or occasion
│
├── Visit Detail View
│   ├── Restaurant info + composite score breakdown
│   ├── Individual ratings (food, value, service, overall)
│   ├── Return intent flag
│   ├── Meal total, tip %, employee/server info
│   ├── Photos & voice notes
│   ├── Journal entries (per-dish impressions)
│   ├── Visit line items (dish names + optional prices)
│   ├── Blacklist toggle + reason
│   └── Notes
│
├── Restaurant Detail View
│   ├── Name, address, cuisine type
│   ├── Allergy-safe foods list (expandable with count)
│   ├── General notes (persistent across all visits)
│   ├── Visit history (chronological list)
│   └── Favorite toggle (pin/unpin)
│
├── Log Visit Flow
│   ├── Step 1: Restaurant identification (name + optional address)
│   │   └── Auto-creates restaurant if new; disambiguation picker if name collision
│   ├── Step 2: Ratings (four sliders — instant composite score display)
│   ├── Step 3: Optional expandable sections
│   │   ├── Meal total + tip % + employee/server
│   │   ├── Visit line items ("Add items")
│   │   ├── Food journal ("Add dish impressions")
│   │   ├── Allergy-safe foods (add/remove)
│   │   └── Restaurant general notes (pre-populated if exists)
│   ├── Step 4: Photos + voice note
│   └── Save button always visible and accessible
│
├── Settings
│   ├── Allergen management (add/edit/remove with severity: Mild/Moderate/Severe)
│   ├── Rating scale customization (5-star ↔ 10-star)
│   ├── Preferred cuisines & default occasion tags
│   ├── Data export (JSON backup)
│   └── Clear blacklist entries
│
└── Post-MVP (deferred — not in MVP scope)
    ├── Random cuisine suggestion
    ├── Discovery map with fog-of-war
    └── Game layer: achievements, stats, quests
```

---

## 3. Key User Journeys & Screen Flows

### UJ-1: Log a Visit (Core ≤30s Path)

```
[Home] → Tap "Log Visit" → [Restaurant ID] → [Ratings] → [Save]
                                    ↓ (name collision)
                              [Disambiguation Picker]
                                    ↓
                              [Ratings] → [Save]

Optional expandables (never block save):
  ┌─ Meal total + tip + employee ─┐
  ├─ Visit line items             │
  ├─ Food journal                 │
  ├─ Allergy-safe foods           │
  └─ Restaurant general notes     │
```

**Screen-by-screen:**

1. **Restaurant ID Screen**
   - Text field: Restaurant name (required)
   - Text field: Address (conditional — only if another restaurant shares the same name)
   - If new restaurant → auto-create, proceed to ratings
   - If name collision → show disambiguation picker (≤3 options, sorted by most recent visit)
   - "Continue" button always visible

2. **Ratings Screen**
   - Four compact horizontal sliders:
     - Food Quality (40% weight)
     - Value for Money (30% weight)
     - Service Quality (15% weight)
     - Overall Experience (15% weight)
   - Composite score displayed in real-time below sliders
   - Return intent toggle: "Would I come back?" (Yes/No)
   - "Save" button always visible at bottom

3. **Optional Sections** (expandable accordions, appear after ratings or alongside):
   - Meal total + tip % + employee/server name + note
   - Visit line items (add dish name + optional price)
   - Food journal (add dish name + impressions text)
   - Allergy-safe foods (add/remove from per-restaurant list)
   - Restaurant general notes (pre-populated if exists, editable)

4. **Media** (optional):
   - Camera button / gallery picker for photos
   - Voice note record button (with transcription indicator)

---

### UJ-2: Browse & Discover

```
[Home/Browse] → [Search bar at top]
                ├── Type query → Results ranked by relevance
                └── No search → List of visits + favorites section
                    ↓ Tap filter icon
                  [Filter sheet: cuisine, rating, occasion, allergy-safe]
                    ↓ Apply filters
                  [Updated list — one frame response]

Visit card shows:
  ├── Restaurant name
  ├── Date
  ├── Composite score (visual indicator)
  └── Return intent flag (✓ or ✗)
```

**Favorites section:**
- Auto-surfaced when no recent visits exist OR at top of browse view
- Restaurants meeting all three criteria: ≥2 visits, avg composite ≥80% max scale, ≥1 returnIntent=true
- Manual pin/unpin always respected
- Grouped by cuisine type or occasion

---

### UJ-3: First-Run Onboarding

```
[Launch] → [Onboarding Flow — one-time, <2 min]
           ├── Screen 1: Food allergies (optional, skip allowed)
           │   └── Add allergen name + severity (Mild/Moderate/Severe)
           ├── Screen 2: Preferred cuisine types
           │   └── Multi-select from ~20 presets + "add custom"
           ├── Screen 3: Rating scale preference
           │   └── Choose 5-star or 10-star
           └── Screen 4: Default occasion tags
               └── Pre-populated suggestions, user selects/edits

[After onboarding] → [Home/Browse View — empty state]
```

---

## 4. Component Specifications

### Visit Card (List Item)

| Element | Details |
|---------|---------|
| Restaurant name | Truncated if long, bold |
| Date | Relative ("2 days ago") or formatted date |
| Composite score | Visual: colored bar or star display based on chosen scale |
| Return intent | Green checkmark or red X icon |
| Blacklist indicator | Subtle greyed-out overlay if blacklisted |
| Tap action | Navigate to Visit Detail View |

### Rating Slider

| Element | Details |
|---------|---------|
| Label | Dimension name (e.g., "Food Quality") |
| Weight indicator | Small text showing weight (40%, 30%, etc.) — optional, may be hidden in compact view |
| Scale | User's chosen scale (5 or 10) shown as tick marks |
| Value display | Current value visible on slider thumb or below |
| Composite update | Real-time recalculation as any slider moves |

### Filter Controls

| Filter | UI Pattern | Options |
|--------|-----------|---------|
| Cuisine type | Multi-select chip group | Preset cuisines + custom |
| Price range | **Excluded from MVP** | — |
| Rating | Range selector (min composite score) | Slider or min/max inputs |
| Occasion | Chip multi-select | User's occasion tags |
| Allergy-safe | Toggle | Show only allergy-safe restaurants |

### Search Results Ranking

Relevance order (highest to lowest):
1. Exact restaurant name match
2. Partial name + address match
3. Employee/server name match
4. Journal dish name match
5. Voice transcript / journal note match
6. Restaurant general notes match
7. Occasion tag match
8. General visit notes match

**Visual:** Matching text highlighted in search results.

---

## 5. Edge Cases & Error States

| Scenario | UX Handling |
|----------|-------------|
| Name collision during logging | Disambiguation picker (≤3 options, sorted by most recent) |
| Name matches null-address restaurant | Require at least one location field before proceeding |
| Voice transcription fails | Show error toast, allow manual text entry fallback |
| No search results | "No visits found" empty state with suggestion to log a visit |
| Empty favorites | Show message: "Favorites appear here when you have 2+ great visits" |
| Restaurant has no visits yet | Show "No visits logged yet" in restaurant detail view |
| Data loss risk (no backup) | Encourage JSON export during onboarding with clear messaging |

---

## 6. Design Decisions Already Made (Do Not Redesign)

- **Composite score weights:** Fixed at 40/30/15/15 for MVP — food/value/service/overall
- **Restaurant identity:** `(name, address)` tuple — two entries with same name but different addresses are distinct
- **Blacklist scope:** Per-Visit only (not per-Restaurant)
- **Line items:** Independent of meal total — do NOT sum to meal total
- **Service quality:** Fourth rating dimension at 15% weight
- **Value for money:** Retained in composite at 30%
- **GPS/location:** Deferred to post-MVP — no location auto-detection in v1
- **Per-visit cuisine type:** Excluded from MVP — stored on Restaurant only
- **Per-dish rating:** Deferred to post-MVP — journal notes are free-text only

---

## 7. Post-MVP Features (Out of Scope for MVP Design)

These should be designed with future expansion in mind but NOT implemented or designed in detail for v1:

| Feature | Target Release | Notes |
|---------|---------------|-------|
| Random cuisine suggestion | 1.5 | "Surprise me" button from browse view |
| Discovery map with fog-of-war | 2.0 | Requires GPS infrastructure |
| Game layer (achievements, stats, quests) | 2.5+ | Opt-in feature in Settings |

---

## 8. Data Model Reference for UX

Key entities the designer needs to understand:

- **Restaurant** — name, address, cuisine type, occasion tags, favorite status, general notes
- **Visit** — date, four ratings, composite score, return intent, meal total, photos, voice note, blacklist state
- **VisitItem** — dish name, optional price (line item within a visit)
- **JournalEntry** — dish name + impressions text (per-dish memory)
- **AllergySafeFood** — food name + confirmed date (per-restaurant safe list)
- **UserAllergen** — allergen name + severity (user-level, not per-restaurant)

---

## 9. Non-Functional UX Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NFR-5 | Logging flow ≤30 seconds from open to save | Core path: name → ratings → save |
| NFR-6 | Search feels instant | <200ms on target device |
| NFR-7 | App cold start <2 seconds | Icon tap to first visible screen |

---

## 10. Deliverables Expected from UX Design

1. **Wireframes** for all MVP screens listed in Section 3
2. **Interactive prototype** covering the three key user journeys (UJ-1, UJ-2, UJ-3)
3. **Component library** — reusable patterns for visit cards, rating sliders, filter chips, etc.
4. **Empty states** — what the app shows when there's no data yet
5. **Dark mode considerations** — Flutter supports both; design should account for light/dark themes
6. **Responsive layouts** — consider various phone screen sizes (not tablet in MVP)

---

*This handoff is derived from final PRD shards (post-review 2026-11-08). All feature decisions, constraints, and resolved open questions in the PRD are binding — the UX design should work within these parameters, not renegotiate them.*
