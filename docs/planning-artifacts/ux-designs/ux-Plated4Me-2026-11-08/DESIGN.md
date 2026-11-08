---
name: Plated4Me
description: Restaurant visit log — mobile-first, offline-only Flutter app for iOS and Android. Calm, functional, speed-oriented design for a single user who logs dining experiences in under 30 seconds.
colors:
  surface-base: '#FAFAFA'
  surface-raised: '#FFFFFF'
  surface-overlay: '#F5F5F5'
  ink-primary: '#1A1A1A'
  ink-secondary: '#6E6E6E'
  ink-disabled: '#BDBDBD'
  accent: '#E8710A'
  accent-light: '#FFF3E0'
  positive: '#2E7D32'
  positive-light: '#E8F5E9'
  negative: '#C62828'
  negative-light: '#FFEBEE'
  border-hairline: '#E0E0E0'
  border-subtle: '#EEEEEE'
  surface-base-dark: '#121212'
  surface-raised-dark: '#1E1E1E'
  surface-overlay-dark: '#2A2A2A'
  ink-primary-dark: '#EAEAEA'
  ink-secondary-dark: '#9E9E9E'
  ink-disabled-dark: '#5A5A5A'
  accent-dark: '#FFB74D'
  accent-light-dark: '#3E2723'
  positive-dark: '#66BB6A'
  positive-light-dark: '#1B3A1C'
  negative-dark: '#EF5350'
  negative-light-dark: '#3E1A1A'
  border-hairline-dark: '#333333'
  border-subtle-dark: '#262626'
typography:
  display:
    note: 'Flutter Display Large — 32px / fontWeight 400 (only on splash/empty states)'
  headline:
    note: 'Flutter Headline Medium — 20px / fontWeight 500'
  title:
    note: 'Flutter Title Medium — 16px / fontWeight 600'
  body-large:
    note: 'Flutter Body Large — 16px / fontWeight 400'
  body-medium:
    note: 'Flutter Body Medium — 14px / fontWeight 400'
  label:
    note: 'Flutter Label Large — 14px / fontWeight 500'
  caption:
    note: 'Flutter Caption — 12px / fontWeight 400'
rounded:
  xs: 4px
  sm: 6px
  md: 10px
  lg: 16px
spacing:
  '1': 4px
  '2': 8px
  '3': 12px
  '4': 16px
  '5': 20px
  '6': 24px
  '8': 32px
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

## Brand & Style

Plated4Me is a personal restaurant visit log — a tool, not a social network. The sole user logs dining experiences in under 30 seconds and consults their own verified records before deciding where to eat next. No accounts, no cloud sync, no notifications. Just data.

The visual language reflects this: **calm surfaces, high-contrast text, minimal chrome**. Every pixel either displays information or enables an action — nothing exists purely for decoration. The design is speed-oriented but never rushed; the interface breathes enough to feel intentional while moving fast enough to respect the user's time.

One accent color — a warm amber/orange — signals primary actions and the composite score. State uses semantic colors (green for positive, red for negative) sparingly. The palette is neutral by default, chromatic only when it matters.

Dark mode is fully supported from day one. All tokens have light/dark variants; no hardcoded hex values in widget code.

## Colors

The palette is restrained on purpose — a logging tool should not compete with the data it presents.

### Light Mode

- **Surface Base (`#FAFAFA`)** — The primary canvas. Slightly warm to avoid clinical sterility while staying neutral enough for data-dense lists.
- **Surface Raised (`#FFFFFF`)** — Cards, modals, and input backgrounds. Elevated from base by tone alone; no shadows in MVP.
- **Surface Overlay (`#F5F5F5`)** — Filter sheets, bottom drawers, and expandable section backgrounds.
- **Ink Primary (`#1A1A1A`)** — Headlines, restaurant names, primary labels. Near-black for maximum legibility.
- **Ink Secondary (`#6E6E6E`)** — Dates, metadata, secondary labels, placeholder text.
- **Ink Disabled (`#BDBDBD`)** — Disabled controls, empty rating sliders, inactive states.
- **Accent (`#E8710A`)** — The single chromatic color. Used for primary action buttons (Save, Log Visit), the composite score indicator, and active filter chips. Warm amber that reads as energetic but not urgent.
- **Positive (`#2E7D32`)** — Return intent "Yes" flag, allergy-safe indicators, successful save states.
- **Negative (`#C62828`)** — Blacklist toggle, return intent "No" flag, destructive actions.
- **Border Hairline (`#E0E0E0`)** — List item dividers, input borders at rest. Lowest legible contrast for separation without visual weight.

### Dark Mode

- **Surface Base (`#121212`)** — Dark canvas. Not pure black; avoids smearing on OLED while staying deep.
- **Surface Raised (`#1E1E1E`)** — Cards and elevated surfaces.
- **Surface Overlay (`#2A2A2A`)** — Filter sheets, expandable sections.
- **Ink Primary (`#EAEAEA`)** — Primary text in dark mode.
- **Ink Secondary (`#9E9E9E`)** — Secondary text and metadata.
- **Accent (`#FFB74D`)** — Accent in dark mode; warmer and lighter for contrast against dark surfaces.
- **Positive (`#66BB6A`)**, **Negative (`#EF5350`)** — Semantic colors adjusted for dark surface legibility.

### Usage Rules

| Element | Color Token |
|---------|------------|
| Save / primary action button | `accent` (light) / `accent-dark` (dark) |
| Composite score indicator | `accent` → green gradient when ≥80% |
| Return intent ✓ | `positive` background pill with white checkmark |
| Return intent ✗ | `negative` background pill with white X |
| Allergy-safe badge | `positive` text on light `positive-light` background |
| Blacklisted visit overlay | 40% opacity `ink-disabled` grey overlay |
| Disabled / empty state | `ink-disabled` |

Avoid: more than one accent color, gradient fills on surfaces, saturated backgrounds behind text blocks.

## Typography

Platform-native Flutter typography tokens are the spec. Dynamic type honored at every level — the UI must remain legible at the largest accessibility setting without truncation or layout break.

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| Display Large | 32px | 400 | Splash screen, empty-state headline (rare) |
| Headline Medium | 20px | 500 | Screen titles, restaurant name in visit card |
| Title Medium | 16px | 600 | Section headers, filter sheet titles |
| Body Large | 16px | 400 | Primary text, journal entries, dish impressions |
| Body Medium | 14px | 400 | Visit card metadata, rating slider labels |
| Label Large | 14px | 500 | Button text, chip labels, tab labels |
| Caption | 12px | 400 | Weights on sliders (40%, 30%), timestamps |

No all-caps labels. No display sizes outside empty states. Headlines are rare — they appear at screen titles and restaurant names in list items only. Everything else lives in body or caption size.

## Layout & Spacing

Scale: **4 / 8 / 12 / 16 / 20 / 24 / 32 px**. All spacing derives from this base unit. Vertical rhythm follows a simple rule: related elements get 8px, unrelated sections get 16px+, major surfaces get 24-32px.

### Mobile Margins

- iOS: 16pt horizontal margins
- Android: 16dp horizontal margins
- Single-column always; no side-by-side layouts in MVP

### Screen Layout Patterns

| Pattern | Description |
|---------|-------------|
| **Full-width card** | Content fills screen width with 16px horizontal padding. Used for visit cards, rating sliders. |
| **Sectioned form** | Grouped fields with section headers and hairline dividers. Used in Log Visit optional sections. |
| **Sheet overlay** | Bottom sheet slides up from bottom (filter controls, disambiguation picker). |
| **Detail view** | Single-column scrollable content with sticky header. Used for Visit Detail, Restaurant Detail. |

### Horizontal Rhythm

```
[16px margin] [content area — flex: 1] [16px margin]
```

No content touches the screen edge except full-width backgrounds (surface-base). All interactive elements have minimum 16px horizontal breathing room from screen edges.

## Elevation & Depth

MVP uses **tone-based elevation only** — no shadows, no blur effects. Surfaces are distinguished by background tone:

| Level | Surface Token | Usage |
|-------|--------------|-------|
| Base | `surface-base` / `surface-base-dark` | App background |
| Raised | `surface-raised` / `surface-raised-dark` | Cards, input fields, list rows |
| Overlay | `surface-overlay` / `surface-overlay-dark` | Filter sheets, expandable section backgrounds |

Elevation as a visual device (shadows, blur) is deferred to post-MVP. In MVP, hierarchy comes from layout, spacing, and tone — not shadow.

## Shapes

| Token | Value | Usage |
|-------|-------|-------|
| `xs` (4px) | 4px rounded | Input field corners, small badges |
| `sm` (6px) | 6px rounded | List rows, rating slider containers, chip borders |
| `md` (10px) | 10px rounded | Visit cards, section headers, modal surfaces |
| `lg` (16px) | 16px rounded | Primary action buttons, empty-state illustrations |

Nothing fully rounded in MVP — no pills for surfaces. Chips and tags use `sm`. Buttons use `lg`. Cards use `md`. Inputs use `xs`. Imagery follows container corners exactly.

## Components

### Visit Card (List Item)

| Property | Value |
|----------|-------|
| Background | `surface-raised` |
| Padding | 12px horizontal, 8px vertical |
| Restaurant name | `headline` weight, `ink-primary`, truncated with ellipsis if >40 chars |
| Date | `caption`, `ink-secondary`, relative ("2 days ago") or formatted |
| Composite score | Visual bar — accent color fill proportional to score. Full width at bottom of card, 3px height. |
| Return intent | Small pill (16×16) in top-right: green checkmark if true, red X if false |
| Blacklist overlay | When blacklisted: 40% `ink-disabled` grey overlay on entire card |
| Tap action | Navigate to Visit Detail View |

### Rating Slider

| Property | Value |
|----------|-------|
| Container | `surface-raised`, rounded `sm`, padding 8px |
| Label | `body-medium`, `ink-primary`, left-aligned |
| Weight indicator | `caption`, `ink-secondary`, right-aligned on same line as label (e.g., "Food Quality · 40%") |
| Scale track | Horizontal bar, 3px height, `border-subtle` background |
| Thumb | Circle, 16px diameter, `accent` color |
| Value display | `body-medium`, `ink-primary`, shown below or beside thumb |
| Composite score | Real-time display below all four sliders — large number in `headline` weight, accent color |

### Filter Chip

| Property | Value |
|----------|-------|
| Rest state | Outlined border `border-hairline`, `ink-secondary` text, `surface-raised` background |
| Active state | Fill `accent-light`, `accent` text and border |
| Shape | Pill (fully rounded), padding 8px horizontal, 4px vertical |
| Font | `label-large`, weight 500 |

### Search Bar

| Property | Value |
|----------|-------|
| Container | `surface-raised`, rounded `md`, full width, padding 12px |
| Icon | Magnifying glass (left), `ink-secondary` |
| Placeholder | "Search restaurants, dishes, notes…" — `ink-disabled` |
| Active state | Border `accent`, cursor visible |
| Clear button | X icon appears when text entered, right side |

### Save Button (Primary Action)

| Property | Value |
|----------|-------|
| Background | `accent` / `accent-dark` |
| Text | White, `label-large`, weight 600 |
| Shape | Rounded `lg`, full width at bottom of screen |
| Padding | 14px vertical, 24px horizontal |
| Disabled state | `ink-disabled` background, 50% opacity text (when required fields incomplete) |

### Allergy-Safe Badge

| Property | Value |
|----------|-------|
| Background | `positive-light` / `positive-light-dark` |
| Text | `positive` / `positive-dark`, `label-medium` |
| Icon | Checkmark circle (left of text) |
| Shape | Rounded `sm`, compact padding |

### Status Lozenge (Composite Score)

| Property | Value |
|----------|-------|
| Excellent (≥80%) | Green fill, white text |
| Good (60-79%) | Yellow/amber fill, dark text |
| Fair (40-59%) | Orange fill, dark text |
| Poor (<40%) | Red fill, white text |

## Do's and Don'ts

| Do | Don't |
|----|-------|
| One accent color for primary actions only | Color-code by cuisine type, occasion, or sentiment |
| Platform-native navigation patterns (back button, tab bar) | Custom drawer navigation, hamburger menus |
| Tone-based elevation (no shadows in MVP) | Drop shadows, blur effects, gradient fills on surfaces |
| Progressive disclosure — optional sections expandable | Show all fields on every screen at once |
| Real-time composite score feedback during rating | Require user to tap "Calculate" or wait for save |
| Dark mode parity with light mode | Hardcoded colors that break in dark mode |
| 16px horizontal margins, single-column layout | Edge-to-edge content without breathing room |
| Semantic colors (green/red) only for state | Use accent color for success/error feedback |
