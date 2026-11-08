---
name: Plated4Me
description: Experience spine for Plated4Me — information architecture, interaction patterns, state management, and key user journeys for the restaurant visit log MVP.
status: final
sources:
  - _bmad_output/ux-handoff.md
  - _bmad_output/prd-shards/prd-index.md
  - _bmad_output/prd-shards/prd-data-model.md
  - _bmad_output/prd-shards/prd-post-mvp.md
  - _bmad_output/prd-shards/prd-quick-log.md
  - _bmad_output/prd-shards/prd-allergy.md
  - _bmad_output/prd-shards/prd-favorites.md
  - _bmad_output/prd-shards/prd-journal.md
  - _bmad_output/prd-shards/prd-browse.md
  - _bmad_output/prd-shards/prd-risks-nfrs.md
updated: 2026-11-08
---

# Plated4Me — Experience Spine

> Single-surface mobile (iOS + Android parity). Consumer posture, calm and functional. Offline-first, single-user, no auth. Paired with `DESIGN.md` for visual identity reference.

## Foundation

Single-surface mobile, iOS + Android with parity. No named UI system — inherits platform conventions for navigation, system gestures, dynamic type. `DESIGN.md` is the visual identity reference; this spine defines how the app behaves.

**Form factor:** Phone only (not tablet in MVP). Flutter single codebase targeting both platforms.

**Core constraint:** The logging flow must complete in ≤30 seconds from open to save on the core path. Every interaction is optimized for speed without sacrificing clarity.

## Information Architecture

| Surface | Reached From | Purpose |
|---------|-------------|---------|
| **Onboarding** | First app launch (one-time) | Capture allergies, cuisine preferences, rating scale, default occasions |
| **Browse / Home** | App open (default), tab bar | Search, filter, and list visits; surface favorites when no recent visits exist |
| **Log Visit — Restaurant ID** | Browse "Log Visit" button, or floating action button | Identify restaurant by name (+ address if needed); auto-create or disambiguate |
| **Log Visit — Ratings** | After restaurant ID confirmed | Rate food, value, service, overall via sliders; set return intent |
| **Log Visit — Optional Sections** | Expandable from ratings screen (or after save) | Meal total, line items, journal entries, allergy-safe foods, general notes |
| **Log Visit — Media** | From optional sections or alongside | Attach photos, record voice note |
| **Visit Detail** | Browse visit card tap | View full visit data: ratings, meal info, journal, line items, blacklist toggle |
| **Restaurant Detail** | Visit detail restaurant name tap, or browse search result | Restaurant info, allergy-safe list, general notes, visit history, favorite toggle |
| **Settings** | Browse header (gear icon), or system settings | Allergen management, rating scale customization, cuisine preferences, data export, blacklist cleanup |

### Navigation Structure

```
Browse/Home (default landing)
├── Search bar (top of screen, always visible)
├── Filter controls (filter icon in header → bottom sheet)
├── Visit cards list (scrollable, most recent first)
│   └── Favorites section (auto-surfaced when no recent visits OR at top)
└── Log Visit entry point (floating action button or header button)

Modal / Sheet Overlays:
├── Filter sheet (bottom sheet — cuisine, rating range, occasion, allergy-safe)
├── Disambiguation picker (bottom sheet — ≤3 options when name collision)
└── Settings (full-screen detail view)
```

No drawer navigation. No tab bar in MVP — single-column scroll with header actions. Back navigation follows platform conventions (iOS swipe/gesture, Android system back).

## Voice and Tone

Microcopy. Brand voice and aesthetic posture live in `DESIGN.md`.

| Context | Do | Don't |
|---------|----|-------|
| Save confirmation | "Saved." | "✓ Visit logged successfully!" |
| Empty browse list | "No visits yet — tap + to log your first." | "Get started by logging a restaurant visit!" |
| Search empty | "No matches." | "We couldn't find any results. Try different keywords." |
| Allergy warning | "Contains: [allergen]" | "⚠️ WARNING: This restaurant may serve foods with allergens!" |
| Rating slider label | "Food Quality" | "How was the food? (1-10)" |
| Return intent prompt | "Would you come back?" | "Rate your likelihood of returning (Yes/No)" |
| Blacklist confirm | "Blacklist this visit?" | "Are you sure you want to blacklist this restaurant visit? This action can be undone." |

**Rules:** Short, complete sentences. No exclamation marks. No encouragement or gamification language. No system-speak ("Network error", "Operation failed"). State indicators are text-only — no icon + text combos for status.

## Component Patterns

Behavioral. Visual specs live in `DESIGN.md` Components.

### Visit Card

| Property | Behavior |
|----------|----------|
| Tap | Navigate to Visit Detail View |
| Long-press | Reserved for future actions (context menu); no-op in MVP |
| Blacklisted state | Grey overlay + dimmed text; tap still navigates to detail |
| Composite score bar | Fills proportionally from left — visual only, not interactive |

### Rating Slider

| Property | Behavior |
|----------|----------|
| Drag thumb | Real-time composite score recalculation as any slider moves |
| Tap on track | Thumb jumps to tapped position |
| Scale | User's chosen scale (5 or 10) shown as tick marks below track |
| Composite display | Updates live — no "Calculate" button needed |

### Filter Controls

| Property | Behavior |
|----------|----------|
| Open filter sheet | Slides up from bottom; dims background |
| Apply filters | Sheet closes; list updates in one frame (local data, instant) |
| Clear all filters | Reset button in filter sheet header |
| Active filters | Filter icon in header shows dot/badge when any filter is active |

### Search Bar

| Property | Behavior |
|----------|----------|
| Focus | Keyboard appears; list updates as user types (debounced 200ms) |
| Clear button | Tapping X clears text and dismisses keyboard |
| No results | "No visits found" message replaces list |
| Matching text | Highlighted in search results (bold or accent-colored) |

### Log Visit Flow — Restaurant ID Screen

| Property | Behavior |
|----------|----------|
| Name field | Required. Auto-suggests previously visited restaurants as user types |
| Address field | Conditional — only shown if another restaurant shares the typed name AND has a non-null address |
| New restaurant | Auto-creates on "Continue"; proceeds to ratings screen |
| Name collision | Shows disambiguation picker (≤3 options, sorted by most recent visit date) |

### Log Visit Flow — Ratings Screen

| Property | Behavior |
|----------|----------|
| Four sliders | Stacked vertically. Food (40%), Value (30%), Service (15%), Overall (15%) |
| Composite score | Displayed below all sliders in large format; updates live |
| Return intent toggle | "Would I come back?" — Yes / No pill toggle |
| Save button | Always visible at bottom. Enabled when all four ratings have values |
| Optional sections | Expandable accordions below save button or on a separate screen after save |

### Log Visit Flow — Optional Sections (Accordion Pattern)

Each section is independently expandable/collapsible:

| Section | Fields | Required? |
|---------|--------|-----------|
| Meal total + tip | Total amount, tip %, employee/server name, note | No |
| Visit line items | Add dish name (+ optional price); "Add another" button | No |
| Food journal | Add dish name + impressions text; "Add another" button | No |
| Allergy-safe foods | Add/remove from per-restaurant safe list | No |
| Restaurant notes | Pre-populated if restaurant exists; editable | No |

**Rule:** Optional sections never block save. User can save immediately after ratings and add details later from Visit Detail View.

### Media (Photos + Voice Note)

| Property | Behavior |
|----------|----------|
| Camera button | Opens device camera; photo attached to visit |
| Gallery picker | Opens photo library; multiple selection allowed |
| Voice note record | Long-press to record; release to stop; waveform indicator during recording |
| Transcription | If transcription succeeds, shows "Transcribed" badge; if fails, error toast + manual text entry fallback |

## State Patterns

| State | Surface | Treatment |
|-------|---------|----------|
| Cold open (no visits) | Browse/Home | Empty state: large icon/illustration area, headline "No visits yet", subtext "Tap + to log your first dining experience", + button highlighted |
| Cold open (has visits) | Browse/Home | Visit cards list, most recent first. Favorites section at top if auto-surfaced criteria met. |
| Empty search results | Browse/Home | "No matches." centered message. No suggestions. |
| Empty favorites | Browse/Home (when no recent visits) | "Favorites appear here when you have 2+ great visits with a return intent." — informational, not actionable |
| Restaurant has no visits | Restaurant Detail | "No visits logged yet" in restaurant info area |
| Name collision during logging | Log Visit — Restaurant ID | Disambiguation picker bottom sheet: ≤3 options sorted by most recent visit date. Each option shows name + address (if available). |
| New restaurant auto-created | Log Visit — Ratings | Seamless transition; no confirmation needed. Restaurant name pre-filled in detail view header. |
| Voice transcription fails | Any screen with voice note | Error toast: "Transcription failed — you can still add text manually." Does not block save. |
| Data export | Settings | "Export your data as JSON" button. On tap: file picker opens; user chooses destination. Confirmation toast: "Data exported successfully." |
| Allergy-safe list empty | Restaurant Detail (allergy section) | "No safe foods recorded for this restaurant yet." — shown during visit logging when adding allergy-safe items |

## Interaction Primitives

- **Tap to act** — Primary interaction on every surface.
- **Swipe** — Not used in MVP. Reserved for post-MVP (swipe-to-delete, swipe-to-blacklist).
- **Long-press** — Reserved for system text selection only. No custom long-press actions in MVP.
- **Pull-to-refresh** — Not needed (local data, always current). Omitted from MVP.
- **Pinch-to-zoom** — Not used. Text scales via Dynamic Type instead.
- **Back navigation** — Platform native: iOS swipe-from-left-edge or system back button; Android system back button.

### Banned Interactions in MVP

Carousels, hero animations, badge counts on list items, pull-to-refresh (unnecessary for local data), haptic feedback patterns that mimic gamification.

## Accessibility Floor

Behavioral. Visual contrast lives in `DESIGN.md`.

- **VoiceOver / TalkBack:** Every interactive element labeled with role + state. Save indicator announces "Saved" on transition. Rating sliders announce current value and scale ("Food Quality, 7 out of 10").
- **Dynamic Type:** Honored through `DESIGN.md` typography tokens. UI must remain legible at the largest accessibility setting — no truncated controls, no overlapping text. Visit cards may show fewer metadata fields at extreme sizes but never truncate the restaurant name.
- **Reduce Motion:** Skip any future animations (save indicator fade, sheet slide transitions). Show state changes immediately without transition.
- **Tap targets:** ≥ 44pt (iOS) / ≥ 48dp (Android) for all interactive elements. Rating slider tracks and thumbs meet this minimum.
- **Focus traversal:** Follows reading order on every surface. Logical tab order from top to bottom, left to right.
- **Color contrast:** All text meets WCAG AA 4.5:1 ratio against its background in both light and dark mode. State indicators (green/red) are never the sole carrier of information — always paired with an icon or text label.

## Key Flows

### Flow 1 — Log a Visit (James, right after lunch at a new ramen shop)

**Protagonist:** James Reid, solo user. Just finished eating. Wants to log before memories fade. Target: ≤30 seconds.

1. James opens the app. Browse/Home loads instantly (cached data).
2. He taps the **+** button in the header.
3. **Restaurant ID screen** appears. He types "Ichiran Ramen" — no suggestions match (new restaurant). The address field does not appear (no name collision).
4. He taps **Continue**. Auto-creates the restaurant. Transitions to ratings screen.
5. **Ratings screen** appears with four sliders pre-set to neutral (middle of each track). He drags: Food 9/10, Value 7/10, Service 8/10, Overall 8/10. Composite score displays live: **82%** — greenExcellent lozenge.
6. He toggles return intent to **Yes** (green checkmark).
7. He taps **Save**. Button shows "Saved." briefly.
8. **Climax:** He's back on Browse/Home. The new visit card appears at the top of the list — restaurant name, date, composite score bar filled to 82%, green return intent checkmark.

**Failure path:** If he accidentally taps away before saving, a draft prompt appears: "You have an unsaved visit. Save or discard?" Both options are tappable; no auto-discard.

### Flow 2 — Browse & Discover (James, planning dinner for a date night)

**Protagonist:** James, at home in the evening, thinking about where to take his partner.

1. James opens the app. Browse/Home shows his visit cards list.
2. He taps the **filter icon** in the header. Filter sheet slides up from bottom.
3. He selects occasion tag "Date night" and toggles "Show allergy-safe only."
4. He taps **Apply**. Sheet closes. List updates instantly — filtered visits shown.
5. He scrolls through results. One restaurant has a green allergy-safe badge next to its name.
6. He taps that restaurant's visit card. **Visit Detail** opens.
7. He taps the restaurant name in the detail header. **Restaurant Detail** opens.
8. He checks the allergy-safe foods list — expandable section shows 3 confirmed safe items.
9. **Climax:** He knows this place is date-night appropriate and allergy-safe. He closes the app.

**Empty state path:** If no visits match the filters, "No matches." appears centered in the list area. No suggestions offered.

### Flow 3 — First-Run Onboarding (James, opening Plated4Me for the first time)

**Protagonist:** James, fresh install. Has eaten at many restaurants with no record of any. Target: <2 minutes.

1. James launches the app. **Onboarding flow** begins automatically (first-run only).
2. **Screen 1 — Allergies:** "Do you have any food allergies?" Skip button always visible. He taps "Add allergen," enters "Shellfish," selects severity "Moderate." Taps Next.
3. **Screen 2 — Cuisine preferences:** "Which cuisines do you enjoy?" Multi-select from ~20 preset chips (Japanese, Mexican, Italian, etc.) plus a "Custom" chip for free-text entry. He selects Japanese, Thai, Mexican. Taps Next.
4. **Screen 3 — Rating scale:** "How would you like to rate your visits?" Two options displayed as large tappable cards: ★★★★★ (5-star) or ⭐ × 10 (10-star). He chooses 10-star. Taps Next.
5. **Screen 4 — Default occasions:** "Which occasions do you log most often?" Pre-populated suggestions shown as chips: Date Night, Family Dinner, Business Lunch, Quick Bite, Celebration, Trying Something New. He selects Date Night, Quick Bite, Trying Something New. Can edit the list. Taps Done.
6. **Climax:** Browse/Home loads — empty state with "No visits yet" message and a prominent + button. James is ready to log.

**Skip path:** Every onboarding screen has a "Skip for now" option. Skipped settings use sensible defaults: 5-star rating scale, no allergies, all occasions available.

### Flow 4 — Review a Past Visit (James, remembering how he felt about a dish)

**Protagonist:** James, three weeks after a visit, trying to recall his impressions of a specific dish.

1. James opens the app. Browse/Home shows recent visits.
2. He scrolls or uses search to find the restaurant. Types "Ichiran" — partial match finds it.
3. He taps the visit card. **Visit Detail** opens.
4. He scrolls past ratings and meal info to the **Journal entries** section.
5. Journal entry shows: dish name in `title` weight, impressions text in `body-large`.
6. **Climax:** He remembers exactly how he felt — the entry captures it. He taps Back to return to Browse/Home.

## Inspiration & Anti-patterns

### Lifted From

- **Yelp (but stripped down):** The visit card as a compact summary of a dining experience — name, score, date. But without Yelp's noise: no reviews from strangers, no business info, no ads.
- **Day One (journaling app):** The single-entry framing. One visit logged at a time, with room for rich detail (journal entries, photos) that doesn't block the core action.
- **Google Keep:** The optional-sections accordion pattern — essential fields always visible, everything else expandable. Speed-first design where save is one tap away.

### Rejected

- **Duolingo streaks / gamification:** Plated4Me is a personal tool, not a habit app. No streak counters, no achievement badges, no re-engagement notifications. The value is in the data, not the engagement metrics.
- **Yelp's review system:** Yelp asks for structured reviews written for an audience. Plated4Me captures memories for the self — no star ratings out of 5 for the restaurant itself, only the user's personal composite score.
- **Google Maps' "Want to go" pins:** Saving restaurants without visiting them creates clutter. Plated4Me only records actual visits. Favorites are earned through repeated great experiences, not bookmarked from a wish list.
- **Health tracking apps' data walls:** Calorie counters and macro trackers overwhelm with numbers. Plated4Me's data is about experience, not nutrition. Numbers serve the story, not replace it.

## Responsive & Platform

### iOS

- Navigation: Swipe-from-left-edge back gesture, system back button on Android.
- Tab bar: Not used in MVP — single-column scroll with header actions.
- Safe area: Respect notch and home indicator insets.
- Haptic feedback: None in MVP (deferred to post-MVP).

### Android

- Navigation: System back button, navigation gestures where available.
- Material You: Adaptive theming supported via Flutter's Material 3; tokens from `DESIGN.md` map to dynamic color scheme where possible.
- Back gesture: Edge-swipe back navigation.
- Long-press: System text selection only.

### Cross-platform Parity

Both platforms share the same layout, interactions, and visual language. Platform differences are limited to:
- Navigation gestures (iOS swipe vs Android back button)
- Typography tokens (platform-native sizing)
- Safe area handling (notch vs notched/not-notched devices)

No platform-specific feature divergence in MVP. The experience is identical; only system-level interactions differ per platform convention.
