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

```bash
# Run Minitest tests
bundle exec rails test

# Run specific component test
bundle exec rails test test/bali/components/button_test.rb

# Start Lookbook preview server
cd spec/dummy && bin/dev
# Open http://localhost:3001/lookbook

# Run Cypress tests (requires server running)
yarn run cy:run   # Headless
yarn run cy:open  # Interactive
```

### Batch Processing (Shell Script)
```bash
./scripts/batch-review.sh                          # Review all components (code-only, parallel)
./scripts/batch-review.sh Button Modal Card        # Review specific components
./scripts/batch-review.sh --with-visual --parallel 4  # With visual verification (needs port coordination)
./scripts/batch-review.sh --dry-run
```

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

Bali must stay on the latest Tailwind CSS and daisyUI to keep all AFAL apps aligned. Check versions at the start of substantial work and update before doing other changes if either is behind:

| Dependency | Source | Spec location |
|------------|--------|---------------|
| **Tailwind CSS** | `tailwindcss-rails` gem | `Gemfile` |
| **daisyUI** | `daisyui` npm package | `package.json` |

```bash
# Update Tailwind CSS (gem)
bundle update tailwindcss-rails

# Update daisyUI (npm)
yarn upgrade daisyui
```

After updating, run the full test suite to confirm nothing breaks.

## Pre-Commit Checklist

Before committing changes:

```bash
# 1. Run tests
bundle exec rails test

# 2. Run Rubocop
bundle exec rubocop -a

# 3. Check Lookbook preview works
cd spec/dummy && bin/dev
# Verify component renders correctly

# 4. Run Cypress tests (if JS changes)
yarn run cy:run
```

## Tailwind v4 CSS Layer Gotcha

Component CSS files (`index.css`) are **unlayered** — they beat Tailwind utility classes in `@layer utilities`.
If a component sets `@apply flex` on `.menu-item`, utility classes like `lg:hidden` will NOT override it.
Use `!important` variants instead: `lg:!hidden`, `max-lg:!hidden`.

### CSS Rebuild
After editing component CSS files, rebuild with: `bundle exec rails tailwindcss:build`
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
| **Link styled as button** | `Bali::Link::Component` with `type:` | `<a class="btn">` | "Create New" (navigates to /new) |

```erb
<%# ✅ CORRECT: Button for actions %>
<%= render Bali::Button::Component.new(name: 'Cancel', variant: :ghost, data: { action: 'modal#close' }) %>
<%= render Bali::Button::Component.new(name: 'Save', variant: :primary, type: :submit) %>

<%# ✅ CORRECT: Link for navigation %>
<%= render Bali::Link::Component.new(name: 'View Users', href: '/users', type: :primary) %>

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

The Bali icon system uses **Lucide icons** as the primary source, with backwards compatibility for existing icon names.

### Icon Resolution Pipeline

When you use `Bali::Icon::Component.new('icon-name')`, the system resolves icons in this order:

1. **Lucide mapping** - Old Bali names mapped to Lucide equivalents (e.g., `edit` → `pencil`)
2. **Direct Lucide** - Use any [Lucide icon](https://lucide.dev/icons) name directly
3. **Kept icons** - Brand logos, regional icons, custom domain icons
4. **Legacy fallback** - Original Bali SVGs for full backwards compatibility

### Icon Categories

| Category | Source | Examples |
|----------|--------|----------|
| **UI Icons** | Lucide (via mapping) | `edit`, `trash`, `search`, `check`, `times` |
| **Direct Lucide** | Lucide | Any icon from [lucide.dev/icons](https://lucide.dev/icons) |
| **Payment Brands** | Kept SVGs | `visa`, `mastercard`, `american-express`, `paypal`, `oxxo` |
| **Social Brands** | Kept SVGs | `whatsapp`, `facebook`, `youtube`, `twitter`, `linkedin` |
| **Regional** | Kept SVGs | `mexico-flag`, `us-flag` |
| **Custom Domain** | Kept SVGs | `recipe-book`, `diagnose`, `day`, `month`, `week` |

### Key Files

| File | Purpose |
|------|---------|
| `app/components/bali/icon/lucide_mapping.rb` | Maps old Bali names → Lucide names (authoritative — check it before assuming a mapping) |
| `app/components/bali/icon/kept_icons.rb` | Brand, regional, and custom icons |
| `app/components/bali/icon/component.rb` | Resolution pipeline |

## BlockNote / ProseMirror Gotchas

### Turbo + React + ProseMirror cleanup
ProseMirror plugins (e.g. Placeholder) remove DOM nodes during destroy. If Turbo detaches the tree first, `removeChild` throws. Fix: destroy `_tiptapEditor` before calling `root.unmount()` in Stimulus `disconnect()`.

### Content serialization with comment marks
`useContentSync` debounces content writes to the hidden input by 500ms. If `save()` reads the input immediately, it may get stale content without comment marks. Fix: flush content synchronously from the editor before reading the hidden input in `save()`.

### BlockNote comment mark cleanup
`ThreadStore.deleteThread()` removes the thread from the store but does NOT remove `comment` marks from the ProseMirror document. Must explicitly call `tr.removeMark()` for the deleted threadId.

### Multiple Stimulus controllers on same page
Document show pages may render multiple overlays (editor + viewer), each with their own `document-editor` controller. Global keyboard listeners (e.g. Cmd+S on `document`) fire on ALL controllers. Guard actions against read-only/empty state.

## Resources

- [ViewComponent Docs](https://viewcomponent.org/)
- [DaisyUI Components](https://daisyui.com/components/)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Lookbook](https://lookbook.build/)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
