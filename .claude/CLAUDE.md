# Bali ViewComponents Development Guide

This file provides guidance to AI coding agents working with the Bali ViewComponents library.

## Reference Documentation

Reference documentation is maintained in `docs/` for use by both Claude Code and OpenCode:

| Document | Purpose |
|----------|---------|
| `docs/reference/afal-design-system.md` | AFAL design system alignment guide (Nexus/Scalo templates) |
| `docs/reference/component-patterns.md` | Standard ViewComponent patterns |
| `docs/reference/stimulus-patterns.md` | Stimulus controller patterns |
| `docs/guides/components.md` | Full component catalog and usage guide |
| `docs/guides/accessibility.md` | WCAG 2.1 accessibility standards |

For the component inventory, list `app/components/bali/` and consult `docs/guides/components.md` — do not rely on a memorized catalog.

Two project skills load on demand: `lookbook-previews` (writing/editing preview files) and `filterform-datatable` (FilterForm + DataTable + Filters integration).

## Development Commands

The Lookbook preview server is not a plain `rails s` — start it with `cd spec/dummy && bin/dev`
and open http://localhost:3001/lookbook. Cypress needs that server already running.

Bulk component review: `./scripts/batch-review.sh` (read the script for its flags).

## Engine Gotchas

### Zeitwerk and preview files

Use `do_not_eager_load` NOT `ignore` when excluding preview files from eager loading in the engine:

```ruby
autoloader.do_not_eager_load(Dir[root.join('app/components/**/preview.rb')])
```

- `ignore` = completely invisible to Zeitwerk → breaks Lookbook on-demand autoloading → 500 errors on preview URLs
- `do_not_eager_load` = skips during `eager_load!` but still autoloads on demand ✓

### Preview file base class

All preview files must inherit from `ApplicationViewComponentPreview`. Do NOT use `Lookbook::Preview` (unavailable in consuming apps without Lookbook) or `ViewComponent::Preview` (inconsistent with the rest of the codebase).

### Cypress tests use Lookbook preview URLs

Cypress tests render Stimulus controllers by visiting `http://localhost:3001/lookbook/preview/bali/[name]/[variant]`. Any change that breaks preview file loading will fail Cypress even if Minitest passes — so check both test suites when touching engine autoloading config.

## Dependency Version Alignment

Bali must stay on the latest Tailwind CSS (`tailwindcss-rails` gem) and daisyUI (npm) to keep all
AFAL apps aligned. Check both at the start of substantial work and update them *before* other
changes if either is behind, then run the full test suite.

## Pre-Commit Checklist

Rubocop and Minitest run automatically via `.githooks` (pre-commit and pre-push). Cypress does
not — run `yarn run cy:run` yourself when you touch JS, and confirm the Lookbook preview renders.

## Which CSS layer a rule belongs in

Since v3 the package's CSS sits in three deliberate positions. Put a new rule in the wrong
one and it either loses to daisyUI or becomes impossible for a host to override.

| Position | What goes there | Why |
|---|---|---|
| `@layer base`, `:where(:root)` | `bali/theme-fallbacks.css` only — the daisyUI tokens Bali shares (`--border`, `--radius-*`, `--size-*`, `--depth`, `--noise`) | Zero specificity in daisyUI's own layer, so a real theme *in that layer* wins. They are fallbacks, not overrides. |
| `@layer components` | Bali's own look — nearly every `index.css` and global sheet | Host utility classes beat it, which is the point. `lg:hidden` just works; **no `!` variant needed**. |
| unlayered | Only rules whose job is to outrank daisyUI (or Tailwind itself) | daisyUI 5 emits its components inside `@layer utilities`, and layers beat specificity — so a rule in `components` loses to daisyUI no matter how specific. |

Unlayered today: `bali/forms.css`, `bali/datepicker.css`, `bali/slim_select.css`,
`bali/container-overrides.css`, `breadcrumb/index.css`, `data_table/index.css`,
`side_menu/daisyui-overrides.css`, `calendar/daisyui-overrides.css`,
`rich_text_editor/daisyui-overrides.css`. Each file's header names the rule it has to beat and
the measurement that put it there — read it before adding to one.

Rule of thumb for a new unlayered rule: the right-most compound is a daisyUI class, and you
are only setting declarations daisyUI also sets. Anything else belongs in `@layer components`.
`container-overrides.css` is the same shape against Tailwind's `.container` utility — the
reason is the layer, not the vendor.

**Specificity only settles ties inside a layer.** Across layers the later one wins outright,
so a `:where()` selector in `base` is not "weak" against `@layer theme` — it beats it. The
practical consequence: a host cannot override Bali's eight structural tokens from `@theme {}`,
because that compiles to `@layer theme`, which comes before `base`. Measured; the table is in
the header of `bali/theme-fallbacks.css`.

**A default and the state that overrides it must share a layer.** A static utility on a
template beats anything in `@layer components`, so the moment Bali's own CSS declares a
`:hover`, an `.is-active` or a density variant for that property, the default has to move into
the sheet next to it or the variant is dead. `command/index.css` carries the worked example.

Careful with `!important` in an unlayered file: it is the *weakest* important in the author
origin, so a host escapes it with `lg:!hidden`. Move that same rule into a layer and it
becomes nearly unbeatable — the opposite of what you usually want.

### CSS Rebuild
After editing component CSS files, rebuild with: `bundle exec rails app:tailwindcss:build`
(`rails tailwindcss:build` is the app's own task and does not exist here — the engine
namespaces it under `app:`.)
Compiled output: `spec/dummy/app/assets/builds/tailwind.css`

## DaisyUI Tooltip Mobile Gotcha

DaisyUI tooltip pseudo-elements (`::before`/`::after`) can cause horizontal scroll on mobile.
Wrap tooltip containers with `max-sm:overflow-hidden` to clip them on small screens.

## Prohibited Patterns

| DON'T | DO INSTEAD |
|-------|------------|
| Add inline styles | Use Tailwind/DaisyUI classes |
| Create complex Stimulus controllers | Keep controllers focused |
| Use non-DaisyUI CSS frameworks | Use DaisyUI + Tailwind classes |
| Skip preview updates | Always update Lookbook preview |
| Skip tests | Always run tests after changes |
| Use jQuery | Use vanilla JS or Stimulus |

## Component Composition (CRITICAL)

**ALWAYS use existing Bali components instead of raw HTML with DaisyUI classes.** This ensures consistency, maintainability, and leverages built-in accessibility features.

### Common Composition Mistakes

| ❌ DON'T USE | ✅ USE INSTEAD |
|--------------|----------------|
| `<div class="card">...</div>` | `<%= render Bali::Card::Component.new %>` |
| `<span class="badge">text</span>` | `<%= render Bali::Tag::Component.new(text: 'text') %>` |
| `<button class="btn">...</button>` | `<%= render Bali::Button::Component.new %>` |
| `<a class="link">...</a>` | `<%= render Bali::Link::Component.new %>` |
| `<div class="alert">...</div>` | `<%= render Bali::Notification::Component.new %>` |
| `<table class="table">...</table>` | `<%= render Bali::Table::Component.new %>` |
| `<div class="dropdown">...</div>` | `<%= render Bali::Dropdown::Component.new %>` |
| `<dialog class="modal">...</dialog>` | `<%= render Bali::Modal::Component.new %>` |

### Example: Building a Grid View

```erb
<%# ❌ BAD: Raw HTML %>
<div class="card bg-base-100 shadow">
  <div class="card-body">
    <span class="badge badge-primary">Tag</span>
  </div>
</div>

<%# ✅ GOOD: Using Bali components %>
<%= render Bali::Card::Component.new(style: :bordered) do %>
  <div class="card-body">
    <%= render Bali::Tag::Component.new(text: 'Tag', color: :primary) %>
  </div>
<% end %>
```

### Before Writing Raw HTML

1. Check for an existing component (`ls app/components/bali/` and `docs/guides/components.md`)
2. If a component exists, use it even if it requires learning its API
3. Only use raw HTML for truly custom layouts not covered by existing components

### Button vs Link (CRITICAL)

Use the correct component based on **what the element does**, not how it looks:

| Use Case | Component | Renders | Example |
|----------|-----------|---------|---------|
| **Navigation** (goes to URL) | `Bali::Link::Component` | `<a>` | "View Details", "Go Back" |
| **Action** (triggers behavior) | `Bali::Button::Component` | `<button>` | "Submit", "Cancel", "Close Modal" |
| **Link styled as button** | `Bali::Link::Component` with `variant:` | `<a class="btn">` | "Create New" (navigates to /new) |

```erb
<%# ✅ CORRECT: Button for actions %>
<%= render Bali::Button::Component.new(name: 'Cancel', variant: :ghost, data: { action: 'modal#close' }) %>
<%= render Bali::Button::Component.new(name: 'Save', variant: :primary, type: :submit) %>

<%# ✅ CORRECT: Link for navigation %>
<%= render Bali::Link::Component.new(name: 'View Users', href: '/users', variant: :primary) %>

<%# ❌ WRONG: Link for action (accessibility issue) %>
<%= render Bali::Link::Component.new(name: 'Cancel', href: '#', data: { action: 'modal#close' }) %>
```

**Why this matters:**
- Screen readers announce buttons and links differently
- Keyboard navigation: buttons activate with Space/Enter, links only with Enter
- Links with `href="#"` are an accessibility anti-pattern

### Common API Gotchas

| Component | Wrong | Correct |
|-----------|-------|---------|
| `PageHeader` back | `back: path` | `back: { href: path }` |
| `Table` rows | `with_body_row` / `with_cell` | `with_row do` + raw `<td>` tags |
| `FormBuilder` select | `select_field_group` | `select_group` |
| `FormBuilder` textarea | `text_area_field_group` | `text_area_group` |
| `SlimSelect` HTML | inline HTML | `data-inner-html` attribute on options |
| Non-model form select param key | expecting `name:` to namespace | `input_name:`/`input_id:` in `select_group`/`slim_select_group` options |
| Drawer/Modal form partial updates | full-page redirect only | respond with `text/vnd.turbo-stream.html` + `data-turbo="true"` on the form — streams are applied and the drawer/modal closes on success |

## Icons

Icons resolve through a pipeline that falls back across several sources, so a name that "should"
be Lucide may not be. Never assume a mapping — read the source:

- `app/components/bali/icon/component.rb` — the resolution pipeline
- `app/components/bali/icon/lucide_mapping.rb` — old Bali names → Lucide (authoritative)
- `app/components/bali/icon/kept_icons.rb` — brand, regional, and custom-domain SVGs

## BlockNote / ProseMirror Gotchas

See `app/components/bali/block_editor/CLAUDE.md` — loads automatically when working in the
editor components.
