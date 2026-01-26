# Bali 2.0 Breaking Changes & Migration Guide

This document details all breaking changes in the Bulma → Tailwind + DaisyUI migration and provides migration instructions for each affected component.

## Table of Contents

- [Overview](#overview)
- [CSS Framework Migration](#css-framework-migration)
- [Component Breaking Changes](#component-breaking-changes)
  - [Avatar Component](#avatar-component) ⚠️ **MAJOR**
  - [Icon Component](#icon-component) ⚠️ **MAJOR**
  - [Link Component](#link-component)
  - [Card Component](#card-component)
  - [Filters Component](#filters-component)
  - [Breadcrumb Component](#breadcrumb-component)
  - [Tag Component](#tag-component)
  - [Calendar Component](#calendar-component)
  - [Modal Component](#modal-component)
  - [Progress Component](#progress-component) ⚠️ **NEW**
  - [Loader Component](#loader-component) ⚠️ **NEW**
  - [Rate Component](#rate-component) ⚠️ **NEW**
  - [Tabs Component](#tabs-component) ⚠️ **NEW**
  - [Tooltip Component](#tooltip-component) ⚠️ **NEW**
  - [ImageField Component](#imagefield-component) ⚠️ **NEW**
  - [Notification Component](#notification-component) ⚠️ **NEW**
- [Class Mapping Reference](#class-mapping-reference)
- [AI-Assisted Migration](#ai-assisted-migration)

---

## Overview

| Metric | Value |
|--------|-------|
| **Total Components** | 60+ |
| **Breaking Changes** | 14 components |
| **New Components** | 15 |
| **Commits** | 317+ |
| **Files Changed** | 900+ |

### Migration Effort by Component

| Component | Breaking? | Effort | Notes |
|-----------|-----------|--------|-------|
| **Avatar** | **Yes** | **High** | Complete API overhaul - now display-only component |
| **Icon** | **Yes** | **High** | New Lucide-based resolution pipeline |
| Link | Yes | Low | `type:` → `variant:` (backwards compat) |
| Card | Yes | Medium | `footer_items` → `actions` slot |
| Filters | Yes | High | Deprecated, use AdvancedFilters |
| Breadcrumb::Item | Yes | Low | `href:` now optional |
| Tag | Yes | Low | `tag_class:` → `color:` |
| Calendar | Yes | Low | `all_week:` → `weekdays_only:` |
| Modal | Yes | Medium | New slot-based API |
| **Progress** | **Yes** | **Medium** | `percentage:` → `show_percentage:`, `color_code:` → `color:` |
| **Loader** | **Yes** | **Medium** | New `type:`, `size:`, `color:` parameters |
| **Rate** | **Yes** | **Low** | Size values changed (`:medium` → `:md`) |
| **Tabs** | **Yes** | **Low** | New `style:`, `size:` params; `tabs_class:` removed |
| **Tooltip** | **Yes** | **Low** | `trigger:` → `trigger_event:`, `small:` removed |
| **ImageField** | **Yes** | **Low** | Positional `image_url` → keyword `src:` |
| **Notification** | **Yes** | **Low** | CSS classes changed (API compatible) |
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

### Avatar Component

**File:** `app/components/bali/avatar/component.rb`

#### Status: MAJOR API CHANGE ⚠️

The Avatar component has been completely redesigned. It was previously a **file upload** component; it is now a **display-only** component for showing user avatars.

#### Changes

| Parameter | Before | After | Breaking? |
|-----------|--------|-------|-----------|
| `form:` | Required for file upload | **REMOVED** | **Yes** |
| `method:` | Required for file upload | **REMOVED** | **Yes** |
| `placeholder_url:` | String URL | **REMOVED** (use placeholder slot) | **Yes** |
| `formats:` | Accepted file formats | **REMOVED** | **Yes** |
| `src:` | N/A | Image URL to display | New |
| `size:` | N/A | `:xs`, `:sm`, `:md`, `:lg`, `:xl` | New |
| `shape:` | N/A | `:square`, `:rounded`, `:circle` | New |
| `mask:` | N/A | `:heart`, `:squircle`, `:hexagon`, etc. | New |
| `status:` | N/A | `:online`, `:offline` | New |
| `ring:` | N/A | DaisyUI color for ring | New |

#### Migration

```ruby
# BEFORE: File upload component
render Bali::Avatar::Component.new(
  form: @form,
  method: :avatar_url,
  placeholder_url: 'default.png',
  formats: %i[jpg jpeg png]
)

# AFTER: Display-only avatar
render Bali::Avatar::Component.new(
  src: user.avatar_url,
  size: :md,
  shape: :circle
)

# With placeholder slot (for initials)
render Bali::Avatar::Component.new(size: :lg) do |c|
  c.with_placeholder { "JD" }
end

# With picture slot
render Bali::Avatar::Component.new(size: :md) do |c|
  c.with_picture(image_url: user.avatar_url)
end

# With status indicator
render Bali::Avatar::Component.new(
  src: user.avatar_url,
  status: :online,
  ring: :success
)
```

#### For File Upload Functionality

If you need avatar file upload, use the new `Bali::Avatar::Upload::Component` (or create a custom implementation using `Bali::ImageField::Component`).

---

### Icon Component

**File:** `app/components/bali/icon/component.rb`

#### Status: MAJOR ARCHITECTURE CHANGE ⚠️

The Icon component now uses **Lucide icons** as the primary source with backwards compatibility for legacy Bali icon names.

#### Changes

| Feature | Before | After | Breaking? |
|---------|--------|-------|-----------|
| **Icon source** | `Bali::Icon::Options::MAP` | Lucide icons + mapping | **Yes** |
| **Resolution** | Single source | 5-level pipeline | **Yes** |
| `size:` | N/A | `:small`, `:medium`, `:large` | New |
| **Icon names** | Bali-specific | Lucide names (1600+ available) | Partial |

#### New Resolution Pipeline

1. **Lucide mapping** - Old Bali names → Lucide equivalents
2. **Direct Lucide** - Use any [Lucide icon](https://lucide.dev/icons) directly
3. **Kept icons** - Brand logos, regional icons, custom domain icons
4. **Custom icons** - Via `Bali.custom_icons`
5. **Legacy fallback** - Original DefaultIcons for backwards compatibility

#### Key Icon Name Mappings

| Old Bali Name | Lucide Name |
|---------------|-------------|
| `edit` | `pencil` |
| `trash` | `trash-2` |
| `cog` | `settings` |
| `times` | `x` |
| `check-circle` | `circle-check` |
| `info-circle` | `info` |
| `alert` | `triangle-alert` |
| `user` | `user` |
| `search` | `search` |

See `app/components/bali/icon/lucide_mapping.rb` for full mapping.

#### Migration

```ruby
# Old Bali names still work (via mapping)
render Bali::Icon::Component.new('edit')    # → renders Lucide 'pencil'
render Bali::Icon::Component.new('trash')   # → renders Lucide 'trash-2'

# New: Use Lucide names directly (1600+ icons)
render Bali::Icon::Component.new('activity')
render Bali::Icon::Component.new('git-branch')
render Bali::Icon::Component.new('cloud-download')

# New: Size parameter
render Bali::Icon::Component.new('check', size: :large)
render Bali::Icon::Component.new('alert', size: :medium, class: 'text-error')
```

#### Brand Icons (Kept)

Brand icons are NOT mapped to Lucide and remain as original Bali SVGs:
`visa`, `mastercard`, `paypal`, `whatsapp`, `facebook`, `youtube`, `twitter`, `linkedin`, etc.

---

### Progress Component

**File:** `app/components/bali/progress/component.rb`

#### Changes

| Parameter | Before | After | Breaking? |
|-----------|--------|-------|-----------|
| `value:` | Default `50` | Default `0` | Soft |
| `percentage:` | Boolean | **REMOVED** → `show_percentage:` | **Yes** |
| `color_code:` | CSS color string | **REMOVED** → `color:` (symbol) | **Yes** |
| `max:` | N/A | Default `100` | New |
| `color:` | N/A | DaisyUI semantic color | New |

#### Migration

```ruby
# BEFORE
render Bali::Progress::Component.new(
  value: 75,
  percentage: true,
  color_code: 'hsl(196, 82%, 78%)'
)

# AFTER
render Bali::Progress::Component.new(
  value: 75,
  max: 100,
  show_percentage: true,
  color: :info
)
```

#### Available Colors

`:primary`, `:secondary`, `:accent`, `:neutral`, `:info`, `:success`, `:warning`, `:error`

#### Search & Replace Pattern

```ruby
# Find (regex)
percentage:\s*(true|false)

# Replace
show_percentage: $1
```

---

### Loader Component

**File:** `app/components/bali/loader/component.rb`

#### Changes

| Parameter | Before | After | Breaking? |
|-----------|--------|-------|-----------|
| `text:` | Only parameter | Still supported | No |
| `type:` | N/A | Loader animation type | New |
| `size:` | N/A | Loader size | New |
| `color:` | N/A | Loader color | New |
| `hide_text:` | N/A | Hide text display | New |

#### Migration

```ruby
# BEFORE: Simple text-only loader
render Bali::Loader::Component.new(text: 'Loading...')

# AFTER: Same API still works
render Bali::Loader::Component.new(text: 'Loading...')

# NEW: With type, size, and color options
render Bali::Loader::Component.new(
  text: 'Loading...',
  type: :spinner,    # :spinner, :dots, :ring, :ball, :bars, :infinity
  size: :lg,         # :xs, :sm, :md, :lg, :xl
  color: :primary    # DaisyUI semantic colors
)

# Loader only (no text)
render Bali::Loader::Component.new(
  type: :dots,
  size: :lg,
  hide_text: true
)
```

**Note:** The default behavior has changed. Old simple loaders will now render with the default `:spinner` type and `:lg` size, which may look different than before.

---

### Rate Component

**File:** `app/components/bali/rate/component.rb`

#### Changes

| Parameter | Before | After | Breaking? |
|-----------|--------|-------|-----------|
| `size:` | `:medium` (Bulma) | `:md` (DaisyUI) | **Yes** |
| `color:` | N/A | New parameter (default `:warning`) | New |

| Method | Before | After | Breaking? |
|--------|--------|-------|-----------|
| `star_dom_id(rate)` | With unique identifier | `star_id(rate)` - simpler | **Yes** |

#### Migration

```ruby
# BEFORE
render Bali::Rate::Component.new(
  value: 3,
  form: @form,
  method: :rating,
  size: :medium
)

# AFTER
render Bali::Rate::Component.new(
  value: 3,
  form: @form,
  method: :rating,
  size: :md,          # Changed from :medium
  color: :warning     # New optional parameter
)
```

#### Available Sizes

`:xs`, `:sm`, `:md`, `:lg`

#### Available Colors

`:warning` (default), `:primary`, `:secondary`, `:accent`, `:success`, `:error`, `:info`

#### Search & Replace Pattern

```ruby
# Find
size: :medium

# Replace
size: :md
```

---

### Tabs Component

**File:** `app/components/bali/tabs/component.rb`

#### Changes

| Parameter | Before | After | Breaking? |
|-----------|--------|-------|-----------|
| `tabs_class:` | Custom class option | **REMOVED** | **Yes** |
| `style:` | N/A | Tab style (default `:border`) | New |
| `size:` | N/A | Tab size (default `:md`) | New |

#### Migration

```ruby
# BEFORE
render Bali::Tabs::Component.new(tabs_class: 'custom-tabs') do |t|
  t.with_tab(name: 'Tab 1') { 'Content 1' }
  t.with_tab(name: 'Tab 2') { 'Content 2' }
end

# AFTER
render Bali::Tabs::Component.new(style: :border, size: :md, class: 'custom-tabs') do |t|
  t.with_tab(name: 'Tab 1') { 'Content 1' }
  t.with_tab(name: 'Tab 2') { 'Content 2' }
end
```

#### Available Styles

`:default`, `:border`, `:box`, `:lift`

#### Available Sizes

`:xs`, `:sm`, `:md`, `:lg`, `:xl`

---

### Tooltip Component

**File:** `app/components/bali/tooltip/component.rb`

#### Changes

| Parameter | Before | After | Breaking? |
|-----------|--------|-------|-----------|
| `trigger:` | Event type string | **RENAMED** → `trigger_event:` | **Yes** |
| `placement:` | String (`'top'`) | Symbol (`:top`) | **Yes** |
| `small:` | Boolean for small size | **REMOVED** | **Yes** |

#### Migration

```ruby
# BEFORE
render Bali::Tooltip::Component.new(
  trigger: 'mouseenter focus',
  placement: 'top',
  small: true
) do |t|
  t.with_trigger { 'Hover me' }
end

# AFTER
render Bali::Tooltip::Component.new(
  trigger_event: 'mouseenter focus',  # Renamed from trigger:
  placement: :top                      # Symbol instead of string
) do |t|
  t.with_trigger { 'Hover me' }
end
```

#### Available Placements

`:top`, `:bottom`, `:left`, `:right`

---

### ImageField Component

**File:** `app/components/bali/image_field/component.rb`

#### Changes

| Parameter | Before | After | Breaking? |
|-----------|--------|-------|-----------|
| `image_url` | **Positional** first argument | **REMOVED** → use `src:` | **Yes** |
| `src:` | N/A | Keyword argument for image URL | New |
| `image_options:` | Custom options hash | **REMOVED** (auto-generated) | **Yes** |
| `size:` | N/A | `:xs`, `:sm`, `:md`, `:lg`, `:xl` | New |

#### Migration

```ruby
# BEFORE: Positional argument
render Bali::ImageField::Component.new(
  'https://example.com/photo.jpg',              # Positional
  placeholder_url: 'https://placehold.jp/128x128.png',
  image_options: { class: 'image is-128x128' }
)

# AFTER: Keyword argument
render Bali::ImageField::Component.new(
  src: 'https://example.com/photo.jpg',         # Keyword
  placeholder_url: 'https://placehold.jp/128x128.png',
  size: :md                                     # New size parameter
)
```

#### Available Sizes

`:xs` (64px), `:sm` (96px), `:md` (128px), `:lg` (160px), `:xl` (192px)

---

### Notification Component

**File:** `app/components/bali/notification/component.rb`

#### Changes

| Feature | Before | After | Breaking? |
|---------|--------|-------|-----------|
| **API** | Same | Same | No |
| **CSS classes** | `notification is-{type}` | `alert alert-{type}` | Soft |
| **HTML structure** | Bulma notification | DaisyUI alert | Soft |

#### Migration

```ruby
# NO CODE CHANGES NEEDED - API is the same
render Bali::Notification::Component.new(
  type: :success,
  delay: 3000,
  fixed: true,
  dismiss: true
) { 'Success message' }
```

**Note:** While the API is unchanged, the underlying CSS classes have changed from Bulma to DaisyUI. If you have custom CSS targeting `.notification` or `.is-success`, update to `.alert` and `.alert-success`.

#### CSS Class Changes

| Before | After |
|--------|-------|
| `notification is-success` | `alert alert-success` |
| `notification is-danger` | `alert alert-error` |
| `notification is-warning` | `alert alert-warning` |
| `notification is-info` | `alert alert-info` |

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

```json
{
  "component": "Bali::Avatar::Component",
  "file": "app/components/bali/avatar/component.rb",
  "breaking": true,
  "severity": "major",
  "changes": [
    {
      "type": "parameter_remove",
      "name": "form",
      "migration": "Use Bali::Avatar::Upload::Component for file upload"
    },
    {
      "type": "parameter_remove",
      "name": "method",
      "migration": "Use Bali::Avatar::Upload::Component for file upload"
    },
    {
      "type": "parameter_remove",
      "name": "placeholder_url",
      "migration": "Use placeholder slot instead"
    },
    {
      "type": "parameter_remove",
      "name": "formats",
      "migration": "Use Bali::Avatar::Upload::Component for file upload"
    },
    {
      "type": "parameter_add",
      "name": "src",
      "description": "Image URL to display"
    },
    {
      "type": "parameter_add",
      "name": "size",
      "values": ["xs", "sm", "md", "lg", "xl"]
    },
    {
      "type": "parameter_add",
      "name": "shape",
      "values": ["square", "rounded", "circle"]
    }
  ],
  "note": "Component purpose changed from file upload to display-only"
}
```

```json
{
  "component": "Bali::Progress::Component",
  "file": "app/components/bali/progress/component.rb",
  "breaking": true,
  "changes": [
    {
      "type": "parameter_rename",
      "old": "percentage",
      "new": "show_percentage",
      "backwards_compatible": false
    },
    {
      "type": "parameter_remove",
      "name": "color_code",
      "migration": "Use color: with semantic DaisyUI colors"
    },
    {
      "type": "parameter_add",
      "name": "color",
      "values": ["primary", "secondary", "accent", "neutral", "info", "success", "warning", "error"]
    },
    {
      "type": "parameter_add",
      "name": "max",
      "default": 100
    }
  ],
  "migration_patterns": [
    {
      "find": "percentage: true",
      "replace": "show_percentage: true"
    },
    {
      "find": "color_code: 'hsl(196, 82%, 78%)'",
      "replace": "color: :info"
    }
  ]
}
```

```json
{
  "component": "Bali::Rate::Component",
  "file": "app/components/bali/rate/component.rb",
  "breaking": true,
  "changes": [
    {
      "type": "parameter_value_change",
      "name": "size",
      "old_values": ["small", "medium", "large"],
      "new_values": ["xs", "sm", "md", "lg"]
    },
    {
      "type": "parameter_add",
      "name": "color",
      "values": ["warning", "primary", "secondary", "accent", "success", "error", "info"],
      "default": "warning"
    }
  ],
  "migration_patterns": [
    {
      "find": "size: :medium",
      "replace": "size: :md"
    },
    {
      "find": "size: :small",
      "replace": "size: :sm"
    },
    {
      "find": "size: :large",
      "replace": "size: :lg"
    }
  ]
}
```

```json
{
  "component": "Bali::Tooltip::Component",
  "file": "app/components/bali/tooltip/component.rb",
  "breaking": true,
  "changes": [
    {
      "type": "parameter_rename",
      "old": "trigger",
      "new": "trigger_event",
      "backwards_compatible": false
    },
    {
      "type": "parameter_type_change",
      "name": "placement",
      "old_type": "string",
      "new_type": "symbol"
    },
    {
      "type": "parameter_remove",
      "name": "small"
    }
  ],
  "migration_patterns": [
    {
      "find": "trigger:",
      "replace": "trigger_event:"
    },
    {
      "find": "placement: 'top'",
      "replace": "placement: :top"
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

# Progress: percentage → show_percentage
# Regex: percentage:\s*(true|false)
# Replace: show_percentage: $1

# Progress: color_code → color (requires manual mapping)
# Regex: color_code:\s*['"][^'"]+['"]
# Replace: color: :info (or appropriate semantic color)

# Rate: size :medium → :md
# Regex: (Bali::Rate::Component\.new[^)]*size:\s*):medium
# Replace: $1:md

# Tooltip: trigger → trigger_event
# Regex: (Bali::Tooltip::Component\.new[^)]*)\btrigger:
# Replace: $1trigger_event:

# Tooltip: placement string → symbol
# Regex: (Bali::Tooltip::Component\.new[^)]*placement:\s*)['"](\w+)['"]
# Replace: $1:$2

# Tabs: tabs_class → class
# Regex: (Bali::Tabs::Component\.new[^)]*)\btabs_class:
# Replace: $1class:

# ImageField: positional image_url → src keyword
# Regex: Bali::ImageField::Component\.new\(\s*['"]([^'"]+)['"]
# Replace: Bali::ImageField::Component.new(src: '$1'
```

### Component Manifest

```json
{
  "version": "2.0.0",
  "framework": "tailwind+daisyui",
  "components": {
    "breaking": [
      "Bali::Avatar::Component",
      "Bali::Icon::Component",
      "Bali::Link::Component",
      "Bali::Card::Component",
      "Bali::Filters::Component",
      "Bali::Breadcrumb::Item::Component",
      "Bali::Tag::Component",
      "Bali::Calendar::Component",
      "Bali::Modal::Component",
      "Bali::Progress::Component",
      "Bali::Loader::Component",
      "Bali::Rate::Component",
      "Bali::Tabs::Component",
      "Bali::Tooltip::Component",
      "Bali::ImageField::Component",
      "Bali::Notification::Component"
    ],
    "major_breaking": [
      "Bali::Avatar::Component",
      "Bali::Icon::Component"
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
