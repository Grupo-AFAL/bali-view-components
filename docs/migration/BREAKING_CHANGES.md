# Bali 2.0 Breaking Changes & Migration Guide

This document details all breaking changes in the Bulma → Tailwind + DaisyUI migration and provides migration instructions for each affected component.

## Table of Contents

- [Overview](#overview)
- [CSS Framework Migration](#css-framework-migration)
- [Component Breaking Changes](#component-breaking-changes)
  - [Link Component](#link-component)
  - [Card Component](#card-component)
  - [Filters Component](#filters-component)
  - [Breadcrumb Component](#breadcrumb-component)
  - [Tag Component](#tag-component)
  - [Calendar Component](#calendar-component)
  - [Modal Component](#modal-component)
- [Class Mapping Reference](#class-mapping-reference)
- [AI-Assisted Migration](#ai-assisted-migration)

---

## Overview

| Metric | Value |
|--------|-------|
| **Total Components** | 60+ |
| **Breaking Changes** | 6 components |
| **New Components** | 15 |
| **Commits** | 317 |
| **Files Changed** | 533 |

### Migration Effort by Component

| Component | Breaking? | Effort | Notes |
|-----------|-----------|--------|-------|
| Link | Yes | Low | `type:` → `variant:` (backwards compat) |
| Card | Yes | Medium | `footer_items` → `actions` slot |
| Filters | Yes | High | Deprecated, use AdvancedFilters |
| Breadcrumb::Item | Yes | Low | `href:` now optional |
| Tag | Yes | Low | `tag_class:` → `color:` |
| Calendar | Yes | Low | `all_week:` → `weekdays_only:` |
| Modal | Yes | Medium | New slot-based API |
| All Others | No | Low | CSS classes auto-migrated |

---

## CSS Framework Migration

### Before: Bulma (SCSS)
```scss
// app/components/bali/button/component.scss
.button {
  &.is-primary { @extend .has-background-primary; }
  &.is-small { font-size: 0.75rem; }
  &.is-loading { /* loading styles */ }
}
```

### After: Tailwind + DaisyUI (CSS)
```css
/* app/components/bali/button/component.css */
/* Most styling now uses DaisyUI classes directly in templates */
/* Only custom overrides remain in CSS files */
```

```erb
<%# Template uses DaisyUI classes %>
<button class="btn btn-primary btn-sm loading loading-spinner">
  Click me
</button>
```

---

## Component Breaking Changes

### Link Component

**File:** `app/components/bali/link/component.rb`

#### Changes

| Parameter | Before | After | Breaking? |
|-----------|--------|-------|-----------|
| `type:` | Required for styling | Deprecated | Soft (backwards compat) |
| `variant:` | N/A | New styling parameter | No |
| `size:` | N/A | New size parameter | No |
| `plain:` | N/A | Remove button styling | No |
| `authorized:` | N/A | Permission-based render | No |

#### Migration

```ruby
# Before
render Bali::Link::Component.new(
  href: '/users',
  name: 'View Users',
  type: :primary
)

# After (preferred)
render Bali::Link::Component.new(
  href: '/users',
  name: 'View Users',
  variant: :primary
)

# After (with size)
render Bali::Link::Component.new(
  href: '/users',
  name: 'View Users',
  variant: :primary,
  size: :sm
)
```

#### Available Variants
`:primary`, `:secondary`, `:accent`, `:info`, `:success`, `:warning`, `:error`, `:ghost`, `:link`, `:neutral`

#### Available Sizes
`:xs`, `:sm`, `:md`, `:lg`, `:xl`

---

### Card Component

**File:** `app/components/bali/card/component.rb`

#### Changes

| Slot | Before | After | Breaking? |
|------|--------|-------|-----------|
| `footer_items` | Rendered in `card-footer` | **REMOVED** | Yes |
| `actions` | N/A | Renders in `card-actions` | No |
| `header` | Available | Unchanged | No |
| `title` | N/A | New slot | No |
| `image` | Available | Unchanged | No |

#### Migration

```ruby
# Before
render Bali::Card::Component.new do |c|
  c.with_header { "Card Title" }
  c.with_footer_item { render Bali::Button::Component.new(name: 'Cancel') }
  c.with_footer_item { render Bali::Button::Component.new(name: 'Save', variant: :primary) }
end

# After
render Bali::Card::Component.new do |c|
  c.with_header { "Card Title" }
  c.with_action { render Bali::Button::Component.new(name: 'Cancel') }
  c.with_action { render Bali::Button::Component.new(name: 'Save', variant: :primary) }
end
```

#### Search & Replace Pattern
```
# Find (regex)
c\.with_footer_item

# Replace
c.with_action
```

---

### Filters Component

**File:** `app/components/bali/filters/component.rb`

#### Status: DEPRECATED

The `Bali::Filters::Component` is deprecated in favor of `Bali::AdvancedFilters::Component`.

#### Migration

```ruby
# Before: Filters with simple attributes
render Bali::Filters::Component.new(form: filter_form) do |f|
  f.with_attribute(name: 'name_cont', title: 'Name')
  f.with_attribute(name: 'status_eq', title: 'Status', collection: Status.all)
end

# After: AdvancedFilters with typed conditions
render Bali::AdvancedFilters::Component.new(
  url: movies_path,
  available_attributes: [
    { key: 'name', label: 'Name', type: 'text' },
    { key: 'status', label: 'Status', type: 'select', options: Status.options }
  ]
)
```

#### Controller Changes

```ruby
# Before
class MoviesController < ApplicationController
  def index
    @filter_form = Bali::FilterForm.new(Movie.all, params)
    @movies = @filter_form.result
  end
end

# After
class MoviesController < ApplicationController
  def index
    @filter_form = Bali::AdvancedFilterForm.new(Movie.all, params)
    @movies = @filter_form.result
  end
end
```

#### Key Differences

| Feature | Filters | AdvancedFilters |
|---------|---------|-----------------|
| Filter groups | No | Yes (AND/OR) |
| Conditions per group | 1 | Multiple (AND/OR) |
| Type-specific operators | Limited | Full set per type |
| Dynamic add/remove | No | Yes |
| Date range "between" | Manual | Built-in with Flatpickr |

---

### Breadcrumb Component

**File:** `app/components/bali/breadcrumb/item/component.rb`

#### Changes

| Parameter | Before | After | Breaking? |
|-----------|--------|-------|-----------|
| `href:` | Required | Optional | Yes |
| `name:` | Required | Required (now primary) | No |
| `active:` | Manual | Auto-detected from `href` | No |

#### Migration

```ruby
# Before: Active item with href
c.with_item(href: '/dashboard', name: 'Dashboard')
c.with_item(href: '/settings', name: 'Settings', active: true)

# After: Omit href for active item
c.with_item(href: '/dashboard', name: 'Dashboard')
c.with_item(name: 'Settings')  # Auto-active (no href)
```

#### Behavior Changes

- Items without `href` automatically render as active
- Active items render as `<span>` instead of `<a>`
- Added `aria-current="page"` for accessibility
- Links show underline only on hover

---

### Tag Component

**File:** `app/components/bali/tag/component.rb`

#### Changes

| Parameter | Before | After | Breaking? |
|-----------|--------|-------|-----------|
| `tag_class:` | Custom CSS class | Deprecated | Soft |
| `color:` | N/A | DaisyUI color | No |

#### Migration

```ruby
# Before
render Bali::Tag::Component.new(text: 'Active', tag_class: 'is-success')

# After
render Bali::Tag::Component.new(text: 'Active', color: :success)
```

#### Available Colors
`:primary`, `:secondary`, `:accent`, `:info`, `:success`, `:warning`, `:error`, `:ghost`, `:neutral`

---

### Calendar Component

**File:** `app/components/bali/calendar/component.rb`

#### Changes

| Parameter | Before | After | Breaking? |
|-----------|--------|-------|-----------|
| `all_week:` | Boolean (confusing name) | Deprecated | Soft |
| `weekdays_only:` | N/A | Boolean | No |
| `start_date` | String required | Date or String | No |

#### Migration

```ruby
# Before
render Bali::Calendar::Component.new(
  events: @events,
  start_date: '2024-01-15',
  all_week: false  # Shows weekends? Confusing!
)

# After
render Bali::Calendar::Component.new(
  events: @events,
  start_date: Date.new(2024, 1, 15),
  weekdays_only: true  # Clear: only show Mon-Fri
)
```

---

### Modal Component

**File:** `app/components/bali/modal/component.rb`

#### Changes

The Modal now uses a slot-based API with native `<dialog>` element.

| Feature | Before | After |
|---------|--------|-------|
| Element | Custom div structure | `<dialog>` |
| Header | Content-based | `header` slot |
| Body | Main content | `body` slot |
| Footer | Content-based | `actions` slot |
| Close | Custom JS | Native + DaisyUI |

#### Migration

```ruby
# Before
render Bali::Modal::Component.new(title: 'Edit User') do
  # All content mixed together
  tag.div(class: 'modal-header') { 'Edit User' }
  tag.div(class: 'modal-body') { 'Form here' }
  tag.div(class: 'modal-footer') do
    render Bali::Button::Component.new(name: 'Cancel')
    render Bali::Button::Component.new(name: 'Save')
  end
end

# After
render Bali::Modal::Component.new do |m|
  m.with_header { 'Edit User' }
  m.with_body { 'Form here' }
  m.with_actions do
    render Bali::Button::Component.new(name: 'Cancel', variant: :ghost)
    render Bali::Button::Component.new(name: 'Save', variant: :primary)
  end
end
```

---

## Class Mapping Reference

### Button Classes

| Bulma | DaisyUI |
|-------|---------|
| `button` | `btn` |
| `is-primary` | `btn-primary` |
| `is-secondary` | `btn-secondary` |
| `is-success` | `btn-success` |
| `is-danger` | `btn-error` |
| `is-warning` | `btn-warning` |
| `is-info` | `btn-info` |
| `is-link` | `btn-link` |
| `is-outlined` | `btn-outline` |
| `is-small` | `btn-sm` |
| `is-medium` | `btn-md` |
| `is-large` | `btn-lg` |
| `is-loading` | `loading loading-spinner` |

### Layout Classes

| Bulma | DaisyUI/Tailwind |
|-------|------------------|
| `columns` | `grid grid-cols-12` |
| `column` | `col-span-*` |
| `is-half` | `col-span-6` |
| `is-one-third` | `col-span-4` |
| `is-two-thirds` | `col-span-8` |
| `is-one-quarter` | `col-span-3` |
| `is-three-quarters` | `col-span-9` |
| `is-flex` | `flex` |
| `is-justify-content-center` | `justify-center` |
| `is-align-items-center` | `items-center` |

### Card Classes

| Bulma | DaisyUI |
|-------|---------|
| `card` | `card bg-base-100` |
| `card-content` | `card-body` |
| `card-header` | (use slots) |
| `card-footer` | `card-actions` |

### Form Classes

| Bulma | DaisyUI |
|-------|---------|
| `input` | `input input-bordered` |
| `select` | `select select-bordered` |
| `textarea` | `textarea textarea-bordered` |
| `checkbox` | `checkbox` |
| `radio` | `radio` |
| `is-danger` (error state) | `input-error` |
| `help is-danger` | `text-error text-sm` |

### Notification/Alert Classes

| Bulma | DaisyUI |
|-------|---------|
| `notification` | `alert` |
| `is-primary` | `alert-info` |
| `is-success` | `alert-success` |
| `is-warning` | `alert-warning` |
| `is-danger` | `alert-error` |

### Table Classes

| Bulma | DaisyUI |
|-------|---------|
| `table` | `table` |
| `is-striped` | `table-zebra` |
| `is-hoverable` | (built-in) |
| `is-fullwidth` | `w-full` |

### Modal Classes

| Bulma | DaisyUI |
|-------|---------|
| `modal` | `modal` |
| `modal-background` | (built-in backdrop) |
| `modal-content` | `modal-box` |
| `modal-close` | (use form method="dialog") |

### Visibility Classes

| Bulma | Tailwind |
|-------|----------|
| `is-hidden` | `hidden` |
| `is-invisible` | `invisible` |
| `is-hidden-mobile` | `hidden md:block` |
| `is-hidden-tablet` | `md:hidden` |

### Spacing Classes

| Bulma | Tailwind |
|-------|----------|
| `mb-1` | `mb-1` (same) |
| `mt-2` | `mt-2` (same) |
| `mx-auto` | `mx-auto` (same) |
| `p-4` | `p-4` (same) |

### Text Classes

| Bulma | Tailwind |
|-------|----------|
| `has-text-centered` | `text-center` |
| `has-text-weight-bold` | `font-bold` |
| `is-size-1` | `text-4xl` |
| `is-size-7` | `text-sm` |
| `has-text-grey` | `text-base-content/60` |
| `has-text-danger` | `text-error` |
| `has-text-success` | `text-success` |

---

## AI-Assisted Migration

This section provides structured data for AI agents to perform automated migrations.

### JSON Schema for Component Changes

```json
{
  "component": "Bali::Link::Component",
  "file": "app/components/bali/link/component.rb",
  "breaking": true,
  "changes": [
    {
      "type": "parameter_rename",
      "old": "type",
      "new": "variant",
      "backwards_compatible": true
    },
    {
      "type": "parameter_add",
      "name": "size",
      "values": ["xs", "sm", "md", "lg", "xl"]
    }
  ],
  "migration_patterns": [
    {
      "find": "type: :primary",
      "replace": "variant: :primary"
    },
    {
      "find": "type: :danger",
      "replace": "variant: :error"
    }
  ]
}
```

### Automated Search & Replace

For codemod tools, use these patterns:

```ruby
# Link: type → variant
# Regex: Bali::Link::Component\.new\([^)]*type:\s*:(\w+)
# Replace: variant: :$1 (adjust :danger → :error)

# Card: footer_items → actions
# Regex: \.with_footer_item\b
# Replace: .with_action

# Tag: tag_class → color
# Regex: tag_class:\s*['"]is-(\w+)['"]
# Replace: color: :$1

# Calendar: all_week → weekdays_only
# Regex: all_week:\s*(true|false)
# Replace: weekdays_only: !$1 (invert boolean)
```

### Component Manifest

```json
{
  "version": "2.0.0",
  "framework": "tailwind+daisyui",
  "components": {
    "breaking": [
      "Bali::Link::Component",
      "Bali::Card::Component",
      "Bali::Filters::Component",
      "Bali::Breadcrumb::Item::Component",
      "Bali::Tag::Component",
      "Bali::Calendar::Component",
      "Bali::Modal::Component"
    ],
    "new": [
      "Bali::AdvancedFilters::Component",
      "Bali::Button::Component",
      "Bali::Avatar::Group::Component",
      "Bali::Avatar::Upload::Component",
      "Bali::Card::Action::Component",
      "Bali::DataTable::ColumnSelector::Component",
      "Bali::DataTable::Export::Component",
      "Bali::DirectUpload::Component",
      "Bali::Modal::Header::Component",
      "Bali::Modal::Body::Component",
      "Bali::Modal::Actions::Component",
      "Bali::Pagination::Component"
    ],
    "removed": [
      "Bali::Card::FooterItem::Component"
    ],
    "deprecated": [
      "Bali::Filters::Component"
    ]
  }
}
```

---

## Verification Checklist

After migration, verify:

- [ ] All RSpec tests pass (`bundle exec rspec`)
- [ ] Lookbook previews render correctly
- [ ] No console errors in browser
- [ ] Forms submit correctly
- [ ] Modals open/close properly
- [ ] Dropdowns position correctly
- [ ] Tables sort and paginate
- [ ] Filters apply correctly
- [ ] Icons display properly
- [ ] Responsive layouts work on mobile

---

## Support

If you encounter issues:

1. Check this document for the specific component
2. Review the CHANGELOG.md for detailed notes
3. Check component source in `app/components/bali/`
4. Open an issue on GitHub with:
   - Component name
   - Before/after code
   - Error message or screenshot
