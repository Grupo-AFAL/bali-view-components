# Bali Tailwind/DaisyUI Migration Status

This is the **single source of truth** for the Bulma → Tailwind/DaisyUI migration.

> **Detailed Logs**: See [.claude/migration-log.md](.claude/migration-log.md) for per-component migration details.
> **Autonomous Workflow**: See [docs/migration/AUTONOMOUS_MIGRATION_WORKFLOW.md](docs/migration/AUTONOMOUS_MIGRATION_WORKFLOW.md) for `/ultrawork` instructions.

---

## Infrastructure Status ✅

| Component      | Status      | Notes                                           |
| -------------- | ----------- | ----------------------------------------------- |
| Tailwind CSS 4 | ✅ Complete | Via `tailwindcss-rails`                         |
| DaisyUI 5      | ✅ Complete | Configured in `tailwind.config.js`              |
| Vite           | ✅ Complete | JavaScript bundling                             |
| Propshaft      | ✅ Complete | Asset pipeline                                  |
| Lookbook       | ✅ Complete | Component previews at `localhost:3001`          |
| CI/CD          | ✅ Complete | RSpec, Rubocop, StandardJS, Cypress all passing |

---

## Verification Stages

| Stage            | Description                                          | Who      |
| ---------------- | ---------------------------------------------------- | -------- |
| **1. Tests**     | RSpec, RuboCop, StandardJS pass                      | CI       |
| **2. AI Visual** | AI verified component renders correctly in Lookbook  | AI Agent |
| **3. DaisyUI**   | AI verified against DaisyUI patterns                 | AI Agent |
| **4. Manual**    | Human verified in Lookbook                           | Human    |
| **5. Quality**   | Code quality score from `/review-cycle` (target: 9+) | AI Agent |

### Quality Score Guide

| Score    | Meaning                               | Action        |
| -------- | ------------------------------------- | ------------- |
| **🔄**   | Review cycle in progress              | ⏳ Wait       |
| **9-10** | Excellent - Rails-worthy code         | ✅ Ready      |
| **7-8**  | Good - Minor improvements possible    | ⚠️ Acceptable |
| **5-6**  | Needs work - Several issues           | 🔄 Re-review  |
| **< 5**  | Poor - Significant refactoring needed | ❌ Blocked    |

---

## Component Verification Matrix

| Component              | Tests | AI Visual | DaisyUI | Manual | Quality | Notes                                                              |
| ---------------------- | :---: | :-------: | :-----: | :----: | :-----: | ------------------------------------------------------------------ |
| ActionsDropdown        |  ✅   |    ✅     |   ✅    |   ✅   | 9.5/10  | Full DaisyUI dropdown, semantic button+ARIA                        |
| AdvancedFilters        |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Code quality improved, class_names helpers added                   |
| Avatar                 |  ✅   |    ✅     |   ✅    |   ✅   | 9.5/10  | Full DaisyUI, tag.div, alt text, options passthrough               |
| BooleanIcon            |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Added nil handling, improved tests and preview                     |
| Breadcrumb             |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Proper DaisyUI breadcrumbs, aria-label, BASE_CLASSES               |
| BulkActions            |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | CLASSES hash, tag.div template, ITEM_CLASSES const                 |
| Calendar               |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | class_names helpers, Link components, aria-labels                  |
| Card                   |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Full DaisyUI card, fixed header badge positioning                  |
| Carousel               |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | class_names, i18n aria-labels, documented slots                    |
| Chart                  |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | Refactored: explicit params, frozen constants, no mutation         |
| Clipboard              |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | DaisyUI join, BASE_CLASSES, aria-label, 18 tests                   |
| Columns                |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | CSS Grid refactor, gap param, col-span-\* classes                  |
| DataTable              |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | i18n, class_names helpers, options hash pattern                    |
| DeleteLink             |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | SIZES const, class_names, explicit params, 20 tests                |
| Drawer                 |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Unique IDs, position param, header/footer slots, WCAG              |
| Dropdown               |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | i18n aria-label, Trigger VARIANTS, 21 tests                        |
| FieldGroupWrapper      |  ✅   |    ✅     |   ✅    |   ❌   |  9/10   | DaisyUI form-control, class_names, 18 tests                        |
| Filters                |  ✅   |    ❌     |   ❌    |   ❌   |    -    | **DEPRECATED** - Use AdvancedFilters instead                       |
| FlashNotifications     |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Private attr_readers, Lookbook params, 6 tests                     |
| **Form Fields**        |       |           |         |        |         | **FormBuilder field modules (see below)**                          |
| ↳ BooleanFields        |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Frozen constants, SIZES/COLORS, private helpers, 32 tests          |
| ↳ CoordinatesPolygon   |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | Frozen constants, Tailwind h-[400px], 7 tests                      |
| ↳ CurrencyFields       |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | DEFAULT_SYMBOL, symbol: option, ADDON_CLASSES, 7 tests             |
| ↳ DateFields           |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Frozen constants, private helpers, i18n aria, 29 tests             |
| ↳ DatetimeFields       |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Frozen const, no mutation, Lookbook preview, 15 tests              |
| ↳ DynamicFields        |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | Frozen constants, Stimulus integration, Lookbook preview, 35 tests |
| ↳ EmailFields          |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Lookbook preview, comprehensive tests (21)                         |
| ↳ FileFields           |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Frozen constants, hidden input, JS icon fix, 32 tests              |
| ↳ NumberFields         |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Self-contained module, Lookbook preview, 23 tests                  |
| ↳ PasswordFields       |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Lookbook preview, comprehensive tests (21)                         |
| ↳ PercentageFields     |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | DEFAULT_SYMBOL const, symbol: option, Lookbook preview, 7 tests    |
| ↳ RadioFields          |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | SIZES/COLORS/ORIENTATIONS constants, DaisyUI join buttons, 28 tests |
| ↳ RecurrentEventRule   |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | Compact layout, Flatpickr datepicker, DaisyUI classes, 33 tests    |
| ↳ RichTextArea         |  ❌   |    ❌     |   N/A   |   ❌   |    -    | Rich text editor (Trix/TipTap, no spec)                            |
| ↳ SearchFields         |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | btn-neutral default, private search_addon helper, 21 tests         |
| ↳ SelectFields         |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | BASE_CLASSES, DaisyUI select-bordered, Lookbook preview, 13 tests  |
| ↳ SlimSelectFields     |  ✅   |    ❌     |   ✅    |   ❌   |  9/10   | Frozen constants, class_names, no mutation, 34 tests               |
| ↳ StepNumberFields     |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Frozen constants, button_tag, i18n aria-labels, 34 tests           |
| ↳ SubmitFields         |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | VARIANTS/SIZES constants, variant:/size: options, 40 tests         |
| ↳ SwitchFields         |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | DaisyUI toggle classes, SIZES/COLORS constants, 31 tests           |
| ↳ TextFields           |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Self-contained module, Lookbook previews with docs, 21 tests       |
| ↳ TextAreaFields       |  ✅   |    ❌     |   ✅    |   ❌   |  9/10   | textarea_field_options helper, consistent pattern, Lookbook, 13 tests |
| ↳ TimeFields           |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Frozen constants, immutable options, time_24hr option, 18 tests    |
| ↳ TimePeriodFields     |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | Frozen constants, immutable options, Lookbook use-case previews, 35 tests |
| ↳ TimeZoneSelect       |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | BASE_CLASSES, immutable options, private helpers, Lookbook, 12 tests |
| ↳ UrlFields            |  ✅   |    ❌     |   ✅    |   ❌   |  9/10   | Module docs, ADDON_CLASSES pattern, Lookbook preview, 22 tests     |
| GanttChart             |  ✅   |    ❌     |   N/A   |   ❌   |  8/10   | Bulma→DaisyUI, explicit action methods, 21 tests                   |
| Heatmap                |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | Frozen constants, required data:, validated dimensions, 26 tests   |
| Hero                   |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Added actions slot, render_with_template preview                   |
| HoverCard              |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | PLACEMENTS const, loading spinner for async, 43 tests              |
| Icon                   |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Lucide integration, resolution pipeline                            |
| ImageField             |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | SIZES const, class_names, Button for clear, i18n, 31 tests         |
| ImageGrid              |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | COLUMNS/GAPS/ASPECT_RATIOS, class_names, 34 tests                  |
| InfoLevel              |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | BASE_CLASSES, ALIGNMENTS.fetch, private attr, 22 tests             |
| LabelValue             |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | LABEL/VALUE_CLASSES, class_names, private options, 7 tests         |
| Level                  |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | BASE_CLASSES, private attr, ALIGNMENTS.fetch, 14 tests             |
| Link                   |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | VARIANTS/SIZES, class_names, variant param, 39 tests               |
| List                   |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | DaisyUI list/list-row, BASE_CLASSES, 19 tests                      |
| Loader                 |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | BASE_CLASSES, WCAG role/aria-label, color on text, 38 tests        |
| LocationsMap           |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | BASE_CLASSES, private attr, DaisyUI card, 19 tests                 |
| Message                |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | BASE_CLASSES, Hash#fetch, private attrs, 23 tests                  |
| Modal                  |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Slots for header/body/actions, WCAG accessibility                  |
| Navbar                 |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Responsive mobile menu, fullscreen toggle, color variants          |
| Notification           |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | BASE_CLASSES, i18n aria-label, fetch fallback, 19 tests            |
| PageHeader             |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | BASE_CLASSES, ALIGNMENTS, Level delegation, 20 tests               |
| Progress               |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Private attr, wrapper_classes, options passthrough, 16 tests       |
| PropertiesTable        |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | DaisyUI table-zebra, th scope=row, class_names, 13 tests           |
| Rate                   |  ✅   |    ❌     |   ❌    |   ❌   |   🔄    | Review in progress                                                 |
| Reveal                 |  ✅   |    ❌     |   ❌    |   ❌   |   🔄    | Review in progress                                                 |
| RichTextEditor         |  ✅   |    ❌     |   N/A   |   ❌   |    -    | Custom (TipTap)                                                    |
| SearchInput            |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                                 |
| SideMenu               |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                                 |
| SortableList           |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                                 |
| Stepper                |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                                 |
| Table                  |  ✅   |    ✅     |   ✅    |   ❌   |    -    | Needs manual review                                                |
| Tabs                   |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Cypress tests fixed                                                |
| Tag                    |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                                 |
| Tags                   |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                                 |
| Timeago                |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                                 |
| Timeline               |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                                 |
| Tooltip                |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                                 |
| TreeView               |  ✅   |    ✅     |   ✅    |   ❌   |    -    | Needs manual review                                                |
| TurboNativeApp         |  ✅   |    ❌     |   N/A   |   ❌   |    -    | Custom component                                                   |

---

## Summary

> **Branch**: All work is on `tailwind-migration` branch.

| Status         |  Tests  | AI Visual | DaisyUI | Manual  | Quality |
| -------------- | :-----: | :-------: | :-----: | :-----: | :-----: |
| ✅ Complete    |   79    |    50     |   56    |   48    |   50    |
| ❌ Not Started |    4    |    33     |   13    |   35    |   33    |
| N/A            |    -    |     -     |   14    |    -    |    -    |
| **Total**      | **83**  |  **83**   | **83**  | **83**  | **83**  |
| **% Done**     | **95%** |  **60%**  | **81%** | **58%** | **60%** |

> **Note**: 83 = 57 original components - 1 (Form header) + 27 form field modules
> **DaisyUI %**: Calculated against 69 applicable components (excluding 14 N/A)

### Quality Score Summary

| Score Range | Count | % of Scored | Components                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
| ----------- | ----- | ----------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 9-10 (✅)   | 51    | 98%         | ActionsDropdown (9.5), AdvancedFilters (9), Avatar (9.5), BooleanIcon (9), BooleanFields (9), Breadcrumb (9), BulkActions (9), Calendar (9), Card (9), Carousel (9), Chart (9), Clipboard (9), Columns (9), CoordinatesPolygon (9), CurrencyFields (9), DataTable (9), DateFields (9), DatetimeFields (9), DeleteLink (9), Drawer (9), Dropdown (9), DynamicFields (9), EmailFields (9), FieldGroupWrapper (9), FileFields (9), FlashNotifications (9), Heatmap (9), Hero (9), HoverCard (9), Icon (9), ImageField (9), ImageGrid (9), InfoLevel (9), LabelValue (9), Level (9), Link (9), List (9), Loader (9), LocationsMap (9), Message (9), Modal (9), Navbar (9), Notification (9), NumberFields (9), PageHeader (9), PasswordFields (9), PercentageFields (9), Progress (9), PropertiesTable (9), RecurrentEventRuleForm (9), StepNumberFields (9) |
| 7-8 (⚠️)    | 1     | 2%          | GanttChart (8)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| < 7 (❌)    | 0     | 0%          | -                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| Not scored  | 31    | -           | Form fields (12), remaining components (19)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |

---

## Fully Verified Components (47)

Components with ✅ in all applicable columns (Tests, AI Visual, DaisyUI/N/A, Manual):

### Core Components (36)

1. **ActionsDropdown** - Full DaisyUI dropdown with align/direction
2. **AdvancedFilters** - Ransack integration
3. **Avatar** - Full DaisyUI implementation
4. **BooleanIcon** - Uses text-success/text-error
5. **Breadcrumb** - Proper DaisyUI breadcrumbs
6. **BulkActions** - Fixed is-hidden→hidden
7. **Calendar** - Uses card, table, btn
8. **Card** - Full DaisyUI card
9. **Carousel** - Glide.js, CSS fixed
10. **Chart** - Custom (Chart.js)
11. **Clipboard** - Tailwind compliant
12. **Columns** - CSS Grid layout
13. **DataTable** - AdvancedFilters, column selector, sorting
14. **DeleteLink** - HoverCard confirmation
15. **Drawer** - Position param, header/footer slots
16. **Dropdown** - i18n aria-label, Trigger VARIANTS
17. **FlashNotifications** - Private attr_readers, Lookbook params
18. **Hero** - Actions slot, render_with_template
19. **HoverCard** - PLACEMENTS const, async loading
20. **Icon** - Lucide integration
21. **ImageField** - SIZES const, Button for clear
22. **ImageGrid** - COLUMNS/GAPS/ASPECT_RATIOS
23. **InfoLevel** - BASE_CLASSES, ALIGNMENTS.fetch
24. **LabelValue** - LABEL/VALUE_CLASSES
25. **Level** - BASE_CLASSES, ALIGNMENTS.fetch
26. **Link** - VARIANTS/SIZES constants
27. **List** - DaisyUI list/list-row
28. **Loader** - WCAG role/aria-label
29. **LocationsMap** - DaisyUI card, template dedup
30. **Message** - BASE_CLASSES, Hash#fetch
31. **Modal** - Slots for header/body/actions
32. **Navbar** - Responsive mobile menu, fullscreen toggle, color variants
33. **Notification** - i18n aria-label, fetch fallback
34. **PageHeader** - ALIGNMENTS, Level delegation
35. **Progress** - wrapper_classes, options passthrough
36. **PropertiesTable** - DaisyUI table-zebra

### Form Fields (11)

37. **BooleanFields** - DaisyUI checkbox, SIZES/COLORS constants
38. **CoordinatesPolygon** - Google Maps polygon, Tailwind h-[400px]
39. **CurrencyFields** - Currency symbol addon, DaisyUI join
40. **DateFields** - Flatpickr integration, i18n aria-labels
41. **DatetimeFields** - Combined date+time picker
42. **DynamicFields** - Stimulus add/remove, frozen constants
43. **EmailFields** - DaisyUI input with addons
44. **FileFields** - Hidden input pattern, file list UI
45. **NumberFields** - DaisyUI input with constraints
46. **PasswordFields** - DaisyUI input with addons
47. **PercentageFields** - Symbol addon, DaisyUI join

---

## DaisyUI Component Mapping

### High Priority

| Bali         | DaisyUI                                                    | Status     |
| ------------ | ---------------------------------------------------------- | ---------- |
| Avatar       | [avatar](https://daisyui.com/components/avatar/)           | ✅ Done    |
| Card         | [card](https://daisyui.com/components/card/)               | ✅ Done    |
| Table        | [table](https://daisyui.com/components/table/)             | ✅ Done    |
| Breadcrumb   | [breadcrumbs](https://daisyui.com/components/breadcrumbs/) | ✅ Done    |
| Modal        | [modal](https://daisyui.com/components/modal/)             | ✅ Done    |
| Dropdown     | [dropdown](https://daisyui.com/components/dropdown/)       | ✅ Done    |
| Tabs         | [tabs](https://daisyui.com/components/tab/)                | ❌ Pending |
| Navbar       | [navbar](https://daisyui.com/components/navbar/)           | ✅ Done    |
| Drawer       | [drawer](https://daisyui.com/components/drawer/)           | ✅ Done    |
| Notification | [alert](https://daisyui.com/components/alert/)             | ✅ Done    |

### Medium Priority

| Bali     | DaisyUI                                              | Status     |
| -------- | ---------------------------------------------------- | ---------- |
| Loader   | [loading](https://daisyui.com/components/loading/)   | ✅ Done    |
| Progress | [progress](https://daisyui.com/components/progress/) | ✅ Done    |
| Rate     | [rating](https://daisyui.com/components/rating/)     | ❌ Pending |
| Stepper  | [steps](https://daisyui.com/components/steps/)       | ❌ Pending |
| Tag      | [badge](https://daisyui.com/components/badge/)       | ❌ Pending |
| Timeline | [timeline](https://daisyui.com/components/timeline/) | ❌ Pending |
| Tooltip  | [tooltip](https://daisyui.com/components/tooltip/)   | ❌ Pending |

### Custom (No DaisyUI equivalent)

Chart, GanttChart, LocationsMap, RichTextEditor

---

## Verification Commands

```bash
# Run all tests
bundle exec rspec spec/bali/components/

# Fix RuboCop issues
bundle exec rubocop app/components/bali/ --autocorrect-all

# Verify single component
/verify-component ComponentName

# Full migration cycle
/component-cycle ComponentName

# Autonomous migration
/ultrawork
```

---

## Change Log

| Date       | Component                      | Change                                                                                        | By         |
| ---------- | ------------------------------ | --------------------------------------------------------------------------------------------- | ---------- |
| 2026-01-15 | DataTable                      | Migrated to AdvancedFilters, added column selector, sorting/pagination demos                  | AI + Human |
| 2026-01-15 | AdvancedFilters                | NEW: Complex filter UI with Ransack                                                           | AI         |
| 2026-01-15 | Tabs                           | Fixed Cypress selectors for DaisyUI                                                           | AI         |
| 2026-01-15 | CI                             | Fixed Cypress workflow                                                                        | AI         |
| 2026-01-14 | Columns                        | Flexbox layout fix                                                                            | AI + Human |
| 2026-01-14 | Carousel                       | CSS nesting, arrows, swipe/drag                                                               | AI + Human |
| 2026-01-13 | Multiple (11)                  | Manual verification                                                                           | Human      |
| 2026-01-13 | Table, TreeView, BulkActions   | Fixed is-hidden→hidden                                                                        | AI         |
| 2026-01-17 | Infrastructure                 | Add parallel review tooling + quality score tracking                                          | AI         |
| 2026-01-17 | Card                           | Score 8→9: Fixed header badge positioning, removed redundant border classes                   | AI         |
| 2026-01-17 | Modal                          | Score 7→9: Added header/body/actions slots, WCAG aria-describedby                             | AI         |
| 2026-01-17 | ActionsDropdown                | Score 9.5: Semantic button, ARIA attrs, consistent preview API                                | AI         |
| 2026-01-17 | AdvancedFilters                | Score 9: Removed unused @options, added class_names helpers, fixed trailing spaces            | AI         |
| 2026-01-17 | Avatar                         | Score 9.5: Group tag.div+options, alt text support, fixed preview path                        | AI         |
| 2026-01-17 | BooleanIcon                    | Score 9: Added nil value handling, improved tests, all_states preview                         | AI         |
| 2026-01-17 | Breadcrumb                     | Score 9: Added aria-label, BASE_CLASSES constant, private attr_readers                        | AI         |
| 2026-01-17 | BulkActions                    | Score 9: CLASSES hash, tag.div template, ITEM_CLASSES constant                                | AI         |
| 2026-01-17 | Calendar                       | Score 9: class_names helpers, Bali::Link components, aria-labels                              | AI         |
| 2026-01-17 | Carousel                       | Score 9: class_names refactor, i18n aria-labels, documented slots                             | AI         |
| 2026-01-17 | Columns                        | Score 9: Flexbox→CSS Grid, gap param, col-span-\* classes, narrow→auto                        | AI         |
| 2026-01-17 | Chart                          | Score 9: Explicit params, frozen constants, Dataset refactor, Tailwind title                  | AI         |
| 2026-01-17 | Clipboard                      | Score 9: DaisyUI join pattern, BASE_CLASSES, aria-label, 18 tests                             | AI         |
| 2026-01-17 | DeleteLink                     | Score 9: SIZES const, class_names, explicit authorized param, 20 tests                        | AI         |
| 2026-01-17 | Dropdown                       | Score 9: i18n aria-label, Trigger VARIANTS const, 21 tests                                    | AI         |
| 2026-01-17 | Drawer                         | Score 9: Unique IDs, POSITIONS const, header/footer slots, WCAG, 32 tests                     | AI         |
| 2026-01-17 | FieldGroupWrapper              | Score 9: DaisyUI form-control, class_names, no options mutation, 18 tests                     | AI         |
| 2026-01-17 | FlashNotifications             | Score 9: Private attr_readers, Lookbook params, 6 tests                                       | AI         |
| 2026-01-17 | Filters                        | **DEPRECATED**: Emits warning, recommend AdvancedFilters                                      | AI         |
| 2026-01-17 | AdvancedFilters                | Date range: Flatpickr range mode, locale-aware formats, fix "between" reload                  | AI         |
| 2026-01-17 | Form (FormBuilder)             | Score 9: Full Bulma→DaisyUI migration across 12 modules, 117 tests                            | AI         |
| 2026-01-17 | GanttChart                     | Score 8: Bulma→DaisyUI (join, weekend), explicit action methods, 21 tests                     | AI         |
| 2026-01-17 | Hero                           | Score 9: Private attr_reader, Hash#fetch, preview uses Bali::Button                           | AI         |
| 2026-01-17 | Heatmap                        | Score 9: Frozen constants, required data:, validated dimensions, 26 tests                     | AI         |
| 2026-01-17 | Icon                           | Score 9: Lucide integration, SIZE_SVG_CLASSES const, normalize_constant_name helper, 41 tests | AI         |
| 2026-01-17 | DeleteLink                     | Manually verified: HoverCard confirmation renders correctly                                   | Human      |
| 2026-01-17 | Drawer                         | Manually verified: Fixed Tailwind JIT for open class, render_with_template for slots preview  | Human      |
| 2026-01-17 | HoverCard                      | Score 9: PLACEMENTS/TRIGGERS constants, class_names, data merge, 43 tests                     | AI         |
| 2026-01-17 | ImageField                     | Score 9: SIZES const, src: keyword, Button for clear action, i18n, memory cleanup, 31 tests   | AI         |
| 2026-01-17 | InfoLevel                      | Score 9: BASE_CLASSES, ALIGNMENTS.fetch, nav→div semantics, private attr, 22 tests            | AI         |
| 2026-01-17 | LabelValue                     | Score 9: LABEL/VALUE_CLASSES, class_names, private options, 7 tests                           | AI         |
| 2026-01-17 | HoverCard                      | Manually verified: Loading spinner for async content, all placements work                     | Human      |
| 2026-01-17 | InfoLevel                      | Manually verified: Alignment options, heading/title slots render correctly                    | Human      |
| 2026-01-17 | List                           | Score 9: DaisyUI list/list-row, ul/li semantics, BASE_CLASSES, 19 tests                       | AI         |
| 2026-01-17 | Level                          | Score 9: BASE_CLASSES, private attr, ALIGNMENTS.fetch, preview params fixed, 14 tests         | AI         |
| 2026-01-17 | Level                          | Manually verified: Left/right sides, alignment options render correctly                       | Human      |
| 2026-01-17 | Link                           | Score 9: VARIANTS/SIZES constants, class_names, variant param (type deprecated), 39 tests     | AI         |
| 2026-01-17 | Loader                         | Score 9: BASE_CLASSES, WCAG role/aria-label, options passthrough, 30 tests                    | AI         |
| 2026-01-17 | Link                           | Manually verified: All variants, icons, sizes, and states render correctly                    | Human      |
| 2026-01-17 | Loader                         | Manually verified: All types, sizes, colors apply to spinner and text                         | Human      |
| 2026-01-17 | Message                        | Score 9: BASE_CLASSES, Hash#fetch, private attrs, 23 tests                                    | AI         |
| 2026-01-17 | Message                        | Manually verified: All colors, sizes, title/header variations render correctly                | Human      |
| 2026-01-17 | LocationsMap                   | Score 9: BASE_CLASSES, private attr, DaisyUI card, template dedup, 19 tests                   | AI         |
| 2026-01-17 | LocationsMap                   | Manually verified: Map renders, markers display, cards highlight on click                     | Human      |
| 2026-01-17 | Documentation                  | Added external-services.md guide for Google Maps API setup                                    | AI         |
| 2026-01-17 | List                           | Manually verified: Title/subtitle stacking, actions with buttons visible                      | Human      |
| 2026-01-17 | Navbar                         | Score 9: BASE_CLASSES, COLORS, private attr, i18n aria-labels, 34 tests                       | AI         |
| 2026-01-17 | Progress                       | Score 9: Private attr_reader, wrapper_classes, options passthrough, 16 tests                  | AI         |
| 2026-01-17 | Notification                   | Score 9: BASE_CLASSES, i18n aria-label, fetch fallback, tag.div template, 19 tests            | AI         |
| 2026-01-17 | PropertiesTable                | Score 9: DaisyUI table-zebra, th scope=row, class_names, 13 tests                             | AI         |
| 2026-01-17 | PropertiesTable                | Manually verified: Clean zebra styling, proper label hierarchy                                | Human      |
| 2026-01-17 | PageHeader                     | Score 9: BASE_CLASSES, ALIGNMENTS→Level delegation, private helpers, 20 tests                 | AI         |
| 2026-01-17 | Notification                   | Manually verified: All types render correctly, dismiss/fixed modes work                       | Human      |
| 2026-01-17 | BooleanFields (FormBuilder)    | Score 9: DaisyUI checkbox, SIZES/COLORS, private helpers, 32 tests                            | AI         |
| 2026-01-17 | Progress                       | Manually verified: All colors render, percentage display works                                | Human      |
| 2026-01-17 | PageHeader                     | Manually verified: Title, subtitle, back button, right content all render                     | Human      |
| 2026-01-17 | BooleanFields (FormBuilder)    | Manually verified: All sizes and colors render correctly in Lookbook                          | Human      |
| 2026-01-17 | CoordinatesPolygon             | Score 9: Frozen constants, Tailwind h-[400px], fetch+except, 7 tests                          | AI         |
| 2026-01-17 | CoordinatesPolygon             | Manually verified: Map polygon drawing and clear buttons work correctly                       | Human      |
| 2026-01-17 | CoordinatesPolygon             | AI visual verified: Google Maps loads, buttons render, no console errors                      | AI         |
| 2026-01-17 | DateFields (FormBuilder)       | Score 9: Frozen constants, private helpers, i18n aria-labels, 29 tests                        | AI         |
| 2026-01-17 | DynamicFields (FormBuilder)    | Score 9: Frozen constants, Stimulus integration, private helpers, 35 tests                    | AI         |
| 2026-01-17 | DateFields (FormBuilder)       | Manually verified: Selected day visible, DaisyUI colors aligned                               | Human      |
| 2026-01-17 | EmailFields (FormBuilder)      | Manually verified: Default, addons, errors, help text render correctly                        | Human      |
| 2026-01-17 | CurrencyFields (FormBuilder)   | Manually verified: Currency symbol options render correctly in Lookbook                       | Human      |
| 2026-01-17 | PercentageFields (FormBuilder) | Score 9: DEFAULT_SYMBOL const, symbol: option, Lookbook preview, 7 tests                      | AI         |
| 2026-01-17 | DatetimeFields (FormBuilder)   | Score 9: Frozen const, no options mutation, alias test, 15 tests                              | AI         |
| 2026-01-17 | DatetimeFields (FormBuilder)   | Manually verified: Date+time picker renders correctly in Lookbook                             | Human      |
| 2026-01-17 | PasswordFields (FormBuilder)   | Score 9: Lookbook preview, comprehensive tests (21), parens fix                               | AI         |
| 2026-01-17 | PasswordFields (FormBuilder)   | Manually verified: Default, errors, addons, help text render correctly                        | Human      |
| 2026-01-17 | NumberFields (FormBuilder)     | Score 9: Self-contained module, Lookbook preview, 23 tests                                    | AI         |
| 2026-01-17 | NumberFields (FormBuilder)     | Manually verified: Default, addons, constraints, help text render correctly                   | Human      |
| 2026-01-17 | PercentageFields (FormBuilder) | Manually verified: Symbol options render correctly in Lookbook                                | Human      |
| 2026-01-17 | FileFields (FormBuilder)       | Score 9: Frozen constants, hidden input, JS file list icons, 32 tests                         | AI         |
| 2026-01-17 | FileFields (FormBuilder)       | Manually verified: Single/multiple modes, file list UI, remove buttons work                   | Human      |
| 2026-01-17 | DynamicFields (FormBuilder)    | Manually verified: Add/remove fields, Stimulus integration works                              | Human      |
| 2026-01-17 | Navbar                         | Refactor: Responsive mobile menu, fullscreen toggle, color dropdown fix                       | AI         |
| 2026-01-17 | Navbar                         | Manually verified: Mobile menu, fullscreen, all colors, dropdown contrast                     | Human      |
| 2026-01-17 | SearchFields (FormBuilder)     | Score 9: DEFAULT_BUTTON_CLASSES const, private search_addon helper, Lookbook preview, 21 tests | AI         |
| 2026-01-17 | SearchFields (FormBuilder)     | Manually verified: Changed default to btn-neutral, all variants render correctly             | Human      |
| 2026-01-17 | SlimSelectFields (FormBuilder) | Score 9: Frozen constants, class_names helper, no hash mutation, DaisyUI hidden class, 34 tests | AI         |
| 2026-01-17 | SubmitFields (FormBuilder)     | Score 9: VARIANTS/SIZES constants, variant:/size: options, button for modal/drawer cancel, 40 tests | AI         |
| 2026-01-17 | SelectFields (FormBuilder)     | Score 9: BASE_CLASSES const, DaisyUI select-bordered on element, Lookbook preview, 13 tests  | AI         |
| 2026-01-17 | RadioFields (FormBuilder)      | Score 9: Frozen constants, SIZES/COLORS, cursor-pointer labels, no hash mutation, 22 tests   | AI         |
| 2026-01-18 | RadioFields (FormBuilder)      | Manually verified: ORIENTATIONS for vertical/horizontal, DaisyUI join togglers, field_with_errors CSS fix, 28 tests | Human      |
| 2026-01-17 | RecurrentEventRuleForm         | Score 9: Keyword args, frozen constants, DaisyUI classes, Lookbook preview, 33 tests         | AI         |
| 2026-01-17 | StepNumberFields (FormBuilder) | Score 9: Frozen constants, button_tag, i18n aria-labels, DaisyUI Stimulus, 34 tests          | AI         |
| 2026-01-17 | SelectFields (FormBuilder)     | Manually verified: DaisyUI select styling, help text, error states render correctly          | Human      |
| 2026-01-17 | StepNumberFields (FormBuilder) | Manually verified: +/- buttons work, constraints enforced, all previews render correctly     | Human      |
| 2026-01-17 | TextFields (FormBuilder)       | Score 9: Self-contained module with text_field override, Lookbook preview docs, 21 tests     | AI         |
| 2026-01-17 | TextAreaFields (FormBuilder)   | Score 9: textarea_field_options helper, consistent pattern with sibling modules, Lookbook preview, 13 tests | AI         |
| 2026-01-18 | SwitchFields (FormBuilder)     | Score 9: DaisyUI toggle classes, SIZES/COLORS constants, Lookbook preview, 31 tests          | AI         |
| 2026-01-18 | SwitchFields (FormBuilder)     | Manually verified: All toggle sizes/colors render correctly, error states work               | Human      |
| 2026-01-18 | TimeFields (FormBuilder)       | Score 9: Frozen constants, immutable options pattern, Lookbook preview, 17 tests             | AI         |
| 2026-01-18 | TimePeriodFields (FormBuilder) | Score 9: Frozen constants, immutable options, extracted helpers, Stimulus integration, 35 tests | AI         |
| 2026-01-18 | TextFields (FormBuilder)       | Manually verified: All previews render correctly, help text and error states work            | Human      |
| 2026-01-18 | SubmitFields (FormBuilder)     | Manually verified: All variants/sizes render, submit_actions and modal_actions work          | Human      |
| 2026-01-18 | TimeZoneSelect (FormBuilder)   | Score 9: BASE_CLASSES const, immutable options (no hash mutation), private helpers, Lookbook preview, 12 tests | AI         |
| 2026-01-18 | UrlFields (FormBuilder)        | Score 9: Module docs, ADDON_CLASSES pattern, Lookbook preview with all variants, 22 tests    | AI         |
| 2026-01-18 | TimeFields (FormBuilder)       | Manually verified: All previews render, time_24hr option works correctly                     | Human      |
| 2026-01-18 | RecurrentEventRuleForm         | Manually verified: Compact layout, Flatpickr datepicker, RRULE examples with explanations    | Human      |
| 2026-01-18 | TimeZoneSelect (FormBuilder)   | Manually verified: All previews render, priority zones and help text work correctly          | Human      |
| 2026-01-18 | TimePeriodFields (FormBuilder) | Improved Lookbook: 4 use-case previews (quarterly, monthly, weekly, analytics) with docs     | AI + Human |
