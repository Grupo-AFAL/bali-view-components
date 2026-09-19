# Bali ViewComponents Development Guide

This file provides guidance to AI coding agents working with the Bali ViewComponents library.

## Reference Documentation

Reference documentation is maintained in `docs/` for use by both Claude Code and OpenCode:

| Document | Purpose |
|----------|---------|
| `docs/reference/afal-design-system.md` | AFAL design system alignment guide (Nexus/Scalo templates) |
| `docs/reference/component-patterns.md` | Standard ViewComponent patterns |
| `docs/reference/widget-design-notes.md` | Why `Bali::Widget` is shaped the way it is |
| `docs/reference/stimulus-patterns.md` | Stimulus controller patterns |
| `docs/guides/components.md` | Full component catalog and usage guide |
| `docs/guides/accessibility.md` | WCAG 2.1 accessibility standards |

For the component inventory, list `app/components/bali/` and consult `docs/guides/components.md` — do not rely on a memorized catalog.

Three project skills load on demand: `lookbook-previews` (writing/editing preview files), `filterform-datatable` (FilterForm + DataTable + Filters integration) and `performance-profiling`.

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

### Constants inside a preview file go written in full

A `preview.rb` must name its sibling constants completely — `Bali::Icon::LucideMapping`, never
`LucideMapping` — even though the short form reads fine and works on a cold server.

`Module.nesting` is captured at parse time and holds a reference to the module *object*. Lookbook
loads every preview at boot to build its navigation and keeps the class in its own registry, so a
later `reload!` leaves that class resolving sibling constants against a `Bali::Icon` Zeitwerk has
already discarded: `uninitialized constant Bali::Icon::Preview::LucideMapping` over the request
path, on a constant `bin/rails runner` resolves without complaint (#843). Ordinary component files
do not have this problem — they are re-parsed by the same reload that replaces the namespace.

`test/requests/icon_previews_test.rb` fails the build if any `preview.rb` reintroduces the pattern.

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

**The PR body opens with `Closes #NNN` — in English.** GitHub only closes the issue on merge with
`Closes` / `Fixes` / `Resolves`. «Cierra #NNN» reads fine and closes nothing. The rest of the body
stays in Spanish. Enforced by `.claude/hooks/pr-closes-keyword.sh` (PreToolUse).

## Comments, and the language everything is written in

**Everything in the repo is written in English** — code, identifiers, tests, comments, and the
copy inside Lookbook previews. Spanish stays in the prose written for the team: the CHANGELOG,
the commit message and the PR body.

Sample data is content, not code: a preview seeding `Ana García López` or `Priorización` is
showing a Mexican app what it will look like, and that name is the input to an initials test.
`config/locales/bali_view.es.yml` is content too, and so is
`app/services/rrule/spanish_humanizer.rb`, whose output *is* Spanish. What has to be English is
what a reader of the source reads: identifiers, comments and test names — Cypress
`describe`/`it` included, where 32 of the 37 Spanish ones live.

**Never add Spanish. Translate what is there as you touch it.** `bundle exec rubocop` is what
enforces it now: `Bali/EnglishOnly`, from the fleet's `bali-rubocop` gem, reads comments and test
names — accented Spanish and accent-free Spanish alike — and today's debt is frozen in
`.rubocop_todo.yml`, 142 files and 938 findings. Anything outside that list is already red, so a
new or moved file is born in English. Adding Spanish is a review blocker; translating the old is
opportunistic, never a sweep of its own.

**When you translate a file, delete its line from `.rubocop_todo.yml`.** Never regenerate the
file to make a run go green, and never add a line to it: the list only shrinks. An entry for a
file that no longer exists, or one already translated, costs nothing and fails nothing — that is
deliberate, so two translation PRs never break each other on merge.

Three pockets the cop cannot reach, all on review: the `<%# %>` comments of the 610 `.erb`
templates and the `describe`/`it` of the Cypress specs (rubocop only parses Ruby), and the ten
`preview.rb` that `AllCops` excludes wholesale.

Its one false positive is an English test name quoting Spanish UI — `test "renders the
Configuración entry"`, 1 in 938 here. Put the term in `AllowedWords` under
`inherit_mode: { merge: [AllowedWords] }`, or disable that line; do not translate the UI string
to satisfy the cop.

**A comment has to carry what the code cannot.** One of these:

- a **measurement** — a contrast ratio, a byte count, a benchmark. The number is not recoverable
  by reading the line.
- a **constraint invisible from here** — a selector daisyUI emits, a Zeitwerk behaviour, an
  ordering that some other file depends on.
- **why the obvious thing is wrong**, where the next person would otherwise undo the line in
  good faith.

Everything else is noise: narrating the change (the diff already says it), recounting the
investigation or what you decided *not* to do (that belongs in the PR body), restating in prose
the declaration written underneath. The headers of the unlayered CSS files are the shape to
copy — the rule they have to beat and the measurement that put them there, and nothing else.

Three kinds are not prose and are not optional: `@param` and `@label` in a `preview.rb` (Lookbook
builds the preview's controls from them), YARD on a public API, and the pragmas
(`frozen_string_literal`, `rubocop:disable`).

The CHANGELOG is held to the same bar: what changed, who it affects, what they have to do about
it. The evidence behind it lives in the PR.

**Calibration.** #1165 changed three lines of CSS and four dependency versions, and carried ~40
lines of comment plus a 66-line CHANGELOG entry. Two sentences earned their place: the daisyUI
5.7.42 selector that broke the premise written at the top of that file, and the measured contrast
it cost (6.98 → 1.06, AA wants 4.5). Aim for those two.

## Which CSS layer a rule belongs in

Since v3 the package's CSS sits in three deliberate positions. Put a new rule in the wrong
one and it either loses to daisyUI or becomes impossible for a host to override.

| Position | What goes there | Why |
|---|---|---|
| `@layer base`, `:where(:root)` | `bali/theme-fallbacks.css` only — the daisyUI tokens Bali shares (`--border`, `--radius-*`, `--size-*`, `--depth`, `--noise`) | Zero specificity in daisyUI's own layer, so a real theme *in that layer* wins. They are fallbacks, not overrides. |
| `@layer components` | Bali's own look — nearly every `index.css` and global sheet, and any default the caller is meant to be able to override | Host utility classes beat it, which is the point. `lg:hidden` just works; **no `!` variant needed**. Written on the template instead, that same default stays in `@layer utilities` and the caller needs `!` — see below. |
| unlayered | Only rules whose job is to outrank daisyUI (or Tailwind itself) | daisyUI 5 emits its components inside `@layer utilities`, and layers beat specificity — so a rule in `components` loses to daisyUI no matter how specific. |

Unlayered today: `bali/forms.css`, `bali/datepicker.css`, `bali/slim_select.css`,
`bali/container-overrides.css`, `breadcrumb/index.css`, `data_table/index.css`,
`toast/index.css`, `feedback_widget/index.css`, `side_menu/daisyui-overrides.css`,
`calendar/daisyui-overrides.css`, `rich_text_editor/daisyui-overrides.css`,
`gauge/daisyui-overrides.css`, `alert/daisyui-overrides.css`, `tag/daisyui-overrides.css`.
Each file's header names the rule it has to beat and the measurement that put it there —
read it before adding to one.

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

**A default the host must be able to beat goes in the sheet, not in the template's `class`.**
Two utilities for the same property both land in `@layer utilities` at the same specificity,
and inside one layer only emission order breaks the tie — not authorship, and not who wrote
theirs last. Tailwind emits each family ascending by value, 0 first (`.ml-0` sits immediately
before `.ml-1` in the compiled sheet), so a `pb-6` written on a Bali template always sorted
after a host's `pb-0` and always won; the host's only escape was `pb-0!`, and whether their
value won at all depended on which number it was. Declared in the component's `index.css` the
same default sits in `@layer components`, which every host utility beats outright — at any
value and with no `!`. `reveal/index.css` is the worked example: the trigger's `pb-6 mb-6`,
the content's `mb-8` and the chevron's `h-3.5`, all three defaults a caller has a hook for
(#1148). The give-away is a constant that concatenates Bali's value with the caller's own
option for the same property.

This is the opposite reading of the same measurement as `pagination_footer/component.rb:31-45`,
which writes its spacing as named variant constants precisely because the pair resolves by
stylesheet order — the note there is right about the mechanism and settles it inline. Reveal is
the only component migrated so far; the pattern is dominant in the library (~19 `*_CLASSES`
constants) and a sweep is debt with its own issue, not something to do in passing.

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
| `SlimSelect` HTML | inline HTML | `data-inner-html` attribute on options |
| Non-model form select param key | expecting `name:` to namespace | `input_name:`/`input_id:` in `select_group`/`slim_select_group` options |
| Drawer/Modal form partial updates | full-page redirect only | respond with `text/vnd.turbo-stream.html` + `data-turbo="true"` on the form — streams are applied and the drawer/modal closes on success |

## FormBuilder naming

There is nothing to look up: **`<type>_group`** renders the control inside its fieldset,
**`<type>_field`** renders the bare control, and everything after the attribute is a
keyword. `text_group`/`text_field`, `select_group`/`select_field`,
`text_area_group`/`text_area_field`. Attributes for the element itself go in `html:` on
the four families that have two hashes (`select_*`, `slim_select_*`,
`time_zone_select_*`, `radio_*`).

The submit pair follows the same rule: `submit_group` is the actions row, `submit_field`
the button on its own.

One exception, which needs no lookup table: `f.text_area`, `f.rich_text_area`,
`f.time_zone_select` and `f.submit` are Rails' names, kept as overrides so they keep
rendering Bali's markup. Not deprecated; prefer the `<type>_field` spelling in new code.
`search_group` has no bare half at all — Rails' `search_field` is left alone, because
overriding it would change what host call sites already using it render.

The v2 `*_field_group` names and `submit_actions` still resolve for one cycle where a host
app actually used them, warning through `Bali.deprecator` — see
`lib/bali/form_builder/deprecated_names.rb`. Do not write them in new code.

`required:` is a plain HTML attribute passthrough, not a Bali option: it reaches the
control on the families that render one, and is dropped by the ones whose control is a
widget over a hidden field. `test/bali/form_builder/required_option_test.rb` names which
is which, and fails if a new family lands in neither list.

Four class options, four destinations, and nothing to invent: `class:` lands on the
`<fieldset>` **and** the control — both halves are load-bearing in host apps, so it is
not to be narrowed — `field_class:` on the `<fieldset>`, `control_class:` on the box
around the control, `input_class:` on the control itself (and `html: { class: }` is the
older spelling of that last one in the four families with two hashes). The box is the
`.control` div, or the `.join` when an addon replaces it.

Which one a property wants is measured, not a matter of taste: inherited properties come
down from the box, so `control_class:` is enough; width belongs to the box too, because
every control is `w-full` — but as a `max-w-*`, since a bare `w-32` loses to that
`w-full` on the same element; and anything the control paints for itself (background,
border, radius) is hidden behind the control if you put it on the box, so it needs
`input_class:` (#1147).

`test/bali/form_builder/control_class_option_test.rb` and
`input_class_option_test.rb` are the authoritative lists — each declares every family in
one of its two camps and fails if a new family lands in neither.

## Icons

Icons resolve through a pipeline that falls back across several sources, so a name that "should"
be Lucide may not be. Never assume a mapping — read the source:

- `app/components/bali/icon/component.rb` — the resolution pipeline
- `app/components/bali/icon/lucide_mapping.rb` — old Bali names → Lucide (authoritative)
- `app/components/bali/icon/kept_icons.rb` — brand, regional, and custom-domain SVGs

## BlockNote / ProseMirror Gotchas

See `app/components/bali/block_editor/CLAUDE.md` — loads automatically when working in the
editor components.
