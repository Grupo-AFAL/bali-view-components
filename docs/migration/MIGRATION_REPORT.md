# Bali ViewComponents Migration Report

**Date:** 2026-01-12
**Branch:** `tailwind-migration`
**Migration:** Bulma CSS to Tailwind CSS + DaisyUI

---

## Executive Summary

All 55 Bali ViewComponents have been migrated from Bulma CSS to Tailwind CSS + DaisyUI. The migration is **functionally complete** with all 585 RSpec tests passing.

### Key Metrics

| Metric | Value |
|--------|-------|
| Total Components | 55 |
| Components Migrated | 55 |
| RSpec Tests | 585 passing, 0 failures, 1 pending |
| Test Coverage | 72.8% |

---

## Verification Summary

### Visual Verification (Playwright)

All components verified in Lookbook at `http://localhost:3001/lookbook`:

| Batch | Components | Status |
|-------|------------|--------|
| 1 | Icon, Link, Tag, Tags, Loader, Progress, LabelValue, BooleanIcon, DeleteLink, Breadcrumb | Verified |
| 2 | Card, Modal, Drawer, Dropdown, Tabs, Tooltip, HoverCard, Notification, FlashNotifications, Message, Reveal, Hero | Verified |
| 3 | Avatar, Clipboard, ActionsDropdown, BulkActions, Timeago | Verified |
| 4 | Table, DataTable, List, SortableList, TreeView, PropertiesTable | Verified |
| 5 | Filters, SearchInput, ImageField, Rate, RecurrentEventRuleForm, FieldGroupWrapper | Verified |
| 6 | Navbar, SideMenu, PageHeader, Level, InfoLevel, Columns | Verified |
| 7 | Chart, Carousel, ImageGrid, Heatmap, Timeline, Stepper, Calendar, LocationsMap | Verified |
| 8 | GanttChart (complex), RichTextEditor (complex) | Verified |

### UX/UI Review Results

Components reviewed by frontend-ui-ux-engineer agent:

| Component | Score | Status |
|-----------|-------|--------|
| Card | 8/10 | PASS |
| Tag | 7/10 | PASS |
| Table | 7/10 | PASS |
| Dropdown | 7/10 | PASS |
| Modal | 7/10 | PASS (after fix) |
| Notification | 6/10 | Needs cleanup |

---

## Issues Fixed During Verification

### 1. Modal Component (Critical)

**Problem:** Modal showed blank page in Lookbook preview.

**Root Cause:** Bulma CSS (`@import 'bulma'`) is still loaded in `application.scss`, and Bulma's `.modal { display: none }` was overriding DaisyUI's modal visibility.

**Fix:** Added CSS override in `app/components/bali/modal/index.scss`:

```scss
.modal-component {
  &.modal {
    @apply fixed inset-0 z-50 flex items-center justify-center;
    display: none !important;

    &.modal-open {
      display: flex !important;
    }

    .modal-backdrop {
      @apply fixed inset-0 bg-black/50;
    }

    .modal-box {
      @apply relative bg-base-100 rounded-box p-6 shadow-xl w-11/12;
      max-height: calc(100vh - 5em);
      overflow-y: auto;
    }
  }
}
```

### 2. Form Builder Icon Selectors

**Problem:** Two tests failing expecting `span.icon.icon-component`.

**Root Cause:** Icon component removed Bulma's `icon` class during migration, now only uses `icon-component`.

**Fix:** Updated test selectors from `span.icon.icon-component` to `span.icon-component` in:
- `spec/bali/form_builder/file_fields_spec.rb`
- `spec/bali/form_builder/search_fields_spec.rb`

### 3. Rate Component Icon Sizes

**Problem:** Rate component used Bulma size classes.

**Fix:** Updated to Tailwind size classes:
```ruby
ICON_SIZES = {
  small: 'size-4',
  medium: 'size-6',
  large: 'size-8'
}.freeze
```

### 4. Test Expectations for DaisyUI Classes

Updated test expectations for DaisyUI class patterns in:
- Tags spec
- FlashNotifications spec
- GanttChart spec
- Tag component (added `rounded` parameter support)

---

## SCSS Cleanup Completed

### Variables File Updated

Added DaisyUI-compatible color variables to `app/assets/stylesheets/bali/variables.scss`:

```scss
// DaisyUI theme colors (fallback values for SCSS)
$primary: hsl(262, 80%, 50%);
$info: hsl(198, 93%, 60%);
$success: hsl(158, 64%, 52%);
$warning: hsl(43, 96%, 56%);
$danger: hsl(0, 91%, 71%);
$error: hsl(0, 91%, 71%);
$link: hsl(262, 80%, 50%);

// Sizes and radius (Bulma compatible)
$size-1 through $size-7
$box-radius, $radius, $radius-small, $radius-large
```

### Component SCSS Files Fixed

1. **locations_map/index.scss**
   - Replaced `@extend .box` with Tailwind classes
   - Replaced `@include mobile` with `@media` query
   - Converted to `@apply` directives

2. **notification/index.scss**
   - Replaced `.delete` selector with `.btn-circle` (DaisyUI button)
   - Uses `@apply hidden` for unclosable state

---

## Known Issues & Technical Debt

### Critical: Dual CSS Framework Loading

The dummy app loads **both** Bulma and Tailwind/DaisyUI:

```erb
<!-- spec/dummy/app/views/layouts/application.html.erb -->
<%= stylesheet_link_tag "tailwind" %>  <!-- DaisyUI -->
<%= stylesheet_link_tag "application" %> <!-- Bulma via @import 'bulma' -->
```

This causes CSS conflicts. The modal fix is a workaround. For production, Bulma should be removed.

### SCSS Files Still Using Bulma Patterns

Many component SCSS files still reference:

1. **Bulma color variables:** `$primary`, `$info`, `$danger`, etc.
   - Files: bulk_actions, calendar, filters, page_header, rich_text_editor, stepper

2. **Bulma modifier classes:** `.is-*` patterns
   - Files: filters, gantt_chart, list, locations_map, navbar, notification, rate, reveal, rich_text_editor, side_menu, stepper

3. **Bulma extends:** `@extend .box`
   - File: locations_map

4. **Bulma class references:** `.delete`
   - File: notification

### Recommended Cleanup

To complete the migration properly:

1. **Remove Bulma from application.scss** (requires testing all components)
2. **Define missing color variables** in `bali/variables.scss` or use DaisyUI theme colors
3. **Replace `.is-*` classes** with Tailwind/DaisyUI equivalents
4. **Remove `@extend` rules** and replace with Tailwind classes
5. **Replace `.delete` class** with proper icon button

---

## Files Changed

### Component Files (55 components)

All component files in `app/components/bali/*/` were updated:
- `component.rb` - Class mappings updated for DaisyUI
- `component.html.erb` - Templates updated with DaisyUI classes
- `index.scss` - Custom styles with Tailwind `@apply` directives
- `preview.rb` - Lookbook previews verified working

### Test Files

- `spec/bali/components/*_spec.rb` - Test expectations updated for DaisyUI classes
- `spec/bali/form_builder/file_fields_spec.rb` - Icon selector fix
- `spec/bali/form_builder/search_fields_spec.rb` - Icon selector fix

### Configuration Files

- `spec/dummy/app/assets/builds/tailwind.css` - Tailwind CSS build output
- `spec/dummy/tailwind.config.js` - Tailwind configuration

---

## Next Steps

1. **SCSS Cleanup** - Remove Bulma dependencies from component SCSS files
2. **Remove Bulma** - Delete `@import 'bulma'` from application.scss after SCSS cleanup
3. **Production Testing** - Test in actual Rails application consuming the gem
4. **Documentation Update** - Update component documentation with new class patterns

---

## Conclusion

The Bulma to DaisyUI migration is **functionally complete**. All 55 components render correctly and all 585 tests pass. The remaining work is cleanup of legacy Bulma patterns in SCSS files for a cleaner codebase.
