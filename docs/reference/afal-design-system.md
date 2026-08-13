# AFAL Design System Reference

How Bali ViewComponents and the AFAL design system line up. Since v3 the design system
is not an aspiration in a handbook — **it ships in this gem**: daisyUI 5 on Tailwind 4,
the brand themes as importable CSS, and the components as the shared vocabulary every
AFAL app renders. When this document and the code disagree, the code wins; fix the
document.

## What the design system is, concretely

1. **daisyUI 5 semantic classes** on Tailwind CSS 4. Bali tracks the latest of both
   deliberately (see `.claude/CLAUDE.md`, "Dependency Version Alignment") so every
   AFAL app stays on one version of the vocabulary.
2. **The shipped themes** (`css/themes/`): `afal` (the canonical brand palette that
   gobierno-corporativo, afal-apps, identity and opina used to copy by hand),
   `afal-dark` (draft), and `costa-norte`. Adoption, the chrome-theme pattern for
   dark sidebars, and the structural-token rules live in
   `docs/guides/custom-themes.md`.
3. **The components** in `app/components/bali/` — always composed instead of raw
   daisyUI markup (`.claude/CLAUDE.md`, "Component Composition"). The catalogue is
   `docs/guides/components.md`.

## Semantic color, always

Components speak daisyUI's semantic names — never fixed Tailwind colors — so every
theme restyles them for free:

| Semantic color | Usage |
|----------------|-------|
| `primary` / `secondary` / `accent` | Actions and highlights |
| `neutral` | Neutral emphasis |
| `base-100/200/300` + `base-content` | Surfaces (lightest to darkest) and text on them |
| `info` / `success` / `warning` / `error` | Status (it is `error`, never `danger`) |

Use `*-content` on colored backgrounds (`primary-content` on `bg-primary`). Where a
palette must NOT follow the theme (record-status tags a host keys by value), `Tag`
and `EnumBadge` take the fixed status palette (`:slate :red :amber :green …`) as a
deliberate, documented exception — see `docs/guides/enum-badges.md`.

Two structural rules with measurements behind them:

- The eight shared tokens (`--radius-*`, `--size-*`, `--border`, `--depth`, `--noise`)
  are fallbacks in `@layer base` (`bali/theme-fallbacks.css`). A host **cannot**
  override them from `@theme {}` — that compiles to `@layer theme`, which loses to
  `base` outright. Details and the measured table: the file's header and
  `docs/guides/custom-themes.md`.
- Which CSS layer any new rule belongs in is specified in `.claude/CLAUDE.md`
  ("Which CSS layer a rule belongs in").

## Bali component ↔ daisyUI alignment

Verified against the components as shipped — note the ones that are deliberately NOT
the daisyUI widget of the same name:

| Bali component | Renders | Notes |
|----------------|---------|-------|
| `Button` / `Link` / `DeleteLink` | `btn btn-*` | One shared table, three axes: `variant:` (colour), `style:` (`outline`/`soft`), `size:` — `Bali::ButtonTaxonomy` |
| `Card` / `StatCard` | `card bg-base-100 card-border` | StatCard is the Nexus stats pattern, packaged |
| `Table` | `table table-zebra` in an `overflow-x-auto` container | |
| `Tabs` | `tabs` (`tabs-box`/`tabs-border` styles) | ARIA tabs pattern when panelled |
| `Dropdown` | `dropdown dropdown-content menu` | |
| `Modal` | **native `<dialog>`** + daisyUI box styling | Top layer, inert page, Escape from the element — not daisyUI's checkbox modal |
| `Drawer` | **native `<dialog>`**, slide-in panel | NOT daisyUI's `drawer`/`drawer-content`/`drawer-side` — those classes appear nowhere in Bali |
| `Tooltip` | **tippy.js balloon**, portalled to `<body>` by default (#992) | NOT daisyUI's CSS tooltip |
| `Alert` | `alert alert-*` | `Notification`/`Message` are its deprecated v2 shells |
| `Progress` | `progress progress-*` | |
| `Avatar` | `avatar` (photo, or derived initials) | |
| `Stepper` / `WorkflowSteps` | `steps step-*` | Axis is `orientation:` on both |
| `Timeline` | `timeline timeline-*` | |

The daisyUI-native rows exist so hosts inherit theme/token changes for free; the
native-element rows exist because the platform primitive (top layer, focus, Escape)
beats the CSS reimplementation — see `docs/guides/overlays-and-the-top-layer.md`.

## Icons

Icons are **Lucide, inlined as SVG by `lucide-rails`** through the `Bali::Icon`
pipeline — there is no Iconify anywhere in this repo, and no icon font. Never write a
raw `<span class="iconify lucide--home">`; render the component and read the pipeline
before assuming a name maps:

```erb
<%= render Bali::Icon::Component.new('circle-help', class: 'size-4') %>
```

- `app/components/bali/icon/component.rb` — the resolution pipeline
- `app/components/bali/icon/lucide_mapping.rb` — legacy Bali names → Lucide (authoritative)
- `app/components/bali/icon/kept_icons.rb` — brand, regional and custom-domain SVGs

Sizing is Tailwind (`size-3.5`, `size-4`, `size-5`, `size-6`) or the component's
`size:` keyword where it has one.

## The handbook templates (Nexus / Scalo)

The AFAL handbook keeps the purchased daisyUI templates as **visual reference for
patterns Bali does not have yet**:

```
afal/handbook/design-system/
├── DESIGN-SYSTEM.md      # component catalog
├── nexus-html@*/         # admin dashboard template
└── scalo-html@*/         # marketing/landing template
```

| Building this… | Look at |
|----------------|---------|
| Admin UI, dashboards, datatables | Nexus `src/partials/` |
| Landing pages, pricing, heroes, testimonials | Scalo `src/partials/` |

The workflow when a host needs a pattern Bali lacks: check the templates for the
AFAL-approved look, then build it **as a Bali component with Bali primitives** (never
by pasting template HTML into a host — template markup uses Iconify spans and
unthemed structures that do not belong here). `StatCard` is the worked example of a
Nexus pattern that graduated into the gem, and `Kanban`, `Gantt` and `SplitView`
followed the same route from host needs; candidates with a single consumer are
tracked in #730.

## Verifying alignment

1. **Lookbook** (`cd spec/dummy && bin/dev`, port 3001) next to the handbook
   template, and under each theme — the Theme Sampler previews render components
   under `afal`/`afal-dark`/`costa-norte`.
2. **Minitest** (the suite is not RSpec) asserts semantic classes:

   ```ruby
   assert_selector(".card.bg-base-100.card-border")
   assert_selector(".text-success")   # never .text-green-500
   ```

3. **Dark/chrome**: the `dark_chrome` SideMenu preview sanity-checks a chrome theme
   against light content (`docs/guides/custom-themes.md`).

## Resources

- `docs/guides/custom-themes.md` — themes, chrome theme, structural tokens
- `docs/guides/components.md` — the component catalogue
- `docs/guides/accessibility.md` — WCAG 2.1 standards
- **daisyUI docs**: https://daisyui.com/components/
- **AFAL handbook**: `handbook/design-system/DESIGN-SYSTEM.md`
