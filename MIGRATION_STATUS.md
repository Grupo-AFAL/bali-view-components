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

| Stage            | Description                                         | Who      |
| ---------------- | --------------------------------------------------- | -------- |
| **1. Tests**     | RSpec, RuboCop, StandardJS pass                     | CI       |
| **2. AI Visual** | AI verified component renders correctly in Lookbook | AI Agent |
| **3. DaisyUI**   | AI verified against DaisyUI patterns                | AI Agent |
| **4. Manual**    | Human verified in Lookbook                          | Human    |
| **5. Quality**   | Code quality score from `/review-cycle` (target: 9+)| AI Agent |

### Quality Score Guide

| Score | Meaning | Action |
|-------|---------|--------|
| **🔄** | Review cycle in progress | ⏳ Wait |
| **9-10** | Excellent - Rails-worthy code | ✅ Ready |
| **7-8** | Good - Minor improvements possible | ⚠️ Acceptable |
| **5-6** | Needs work - Several issues | 🔄 Re-review |
| **< 5** | Poor - Significant refactoring needed | ❌ Blocked |

---

## Component Verification Matrix

| Component              | Tests | AI Visual | DaisyUI | Manual | Quality | Notes                                              |
| ---------------------- | :---: | :-------: | :-----: | :----: | :-----: | -------------------------------------------------- |
| ActionsDropdown        |  ✅   |    ✅     |   ✅    |   ✅   | 9.5/10  | Full DaisyUI dropdown, semantic button+ARIA        |
| AdvancedFilters        |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Code quality improved, class_names helpers added   |
| Avatar                 |  ✅   |    ✅     |   ✅    |   ✅   | 9.5/10  | Full DaisyUI, tag.div, alt text, options passthrough |
| BooleanIcon            |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Added nil handling, improved tests and preview     |
| Breadcrumb             |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Proper DaisyUI breadcrumbs, aria-label, BASE_CLASSES |
| BulkActions            |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | CLASSES hash, tag.div template, ITEM_CLASSES const |
| Calendar               |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | class_names helpers, Link components, aria-labels  |
| Card                   |  ✅   |    ✅     |   ✅    |   ✅   |  9/10  | Full DaisyUI card, fixed header badge positioning  |
| Carousel               |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | class_names, i18n aria-labels, documented slots   |
| Chart                  |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | Refactored: explicit params, frozen constants, no mutation |
| Clipboard              |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | DaisyUI join, BASE_CLASSES, aria-label, 18 tests   |
| Columns                |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | CSS Grid refactor, gap param, col-span-* classes   |
| DataTable              |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | i18n, class_names helpers, options hash pattern    |
| DeleteLink             |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | SIZES const, class_names, explicit params, 20 tests |
| Drawer                 |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Unique IDs, position param, header/footer slots, WCAG |
| Dropdown               |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | i18n aria-label, Trigger VARIANTS, 21 tests        |
| FieldGroupWrapper      |  ✅   |    ✅     |   ✅    |   ❌   |  9/10   | DaisyUI form-control, class_names, 18 tests        |
| Filters                |  ✅   |    ❌     |   ❌    |   ❌   |    -    | **DEPRECATED** - Use AdvancedFilters instead       |
| FlashNotifications     |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Private attr_readers, Lookbook params, 6 tests     |
| **Form Fields**        |       |           |         |        |         | **FormBuilder field modules (see below)**          |
| ↳ BooleanFields        |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Checkbox/boolean inputs with DaisyUI               |
| ↳ CoordinatesPolygon   |  ✅   |    ❌     |   N/A   |   ❌   |    -    | Custom map polygon input                           |
| ↳ CurrencyFields       |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Currency input with DaisyUI input classes          |
| ↳ DateFields           |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Date picker with Flatpickr                         |
| ↳ DatetimeFields       |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Datetime picker with Flatpickr                     |
| ↳ DynamicFields        |  ❌   |    ❌     |   ❌    |   ❌   |    -    | Dynamic form fields (no spec)                      |
| ↳ EmailFields          |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Email input with DaisyUI input classes             |
| ↳ FileFields           |  ✅   |    ❌     |   ✅    |   ❌   |    -    | File upload input                                  |
| ↳ NumberFields         |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Number input with DaisyUI input classes            |
| ↳ PasswordFields       |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Password input with DaisyUI input classes          |
| ↳ PercentageFields     |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Percentage input with addon                        |
| ↳ RadioFields          |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Radio buttons with DaisyUI radio classes           |
| ↳ RecurrentEventRule   |  ❌   |    ❌     |   N/A   |   ❌   |    -    | Recurrence rule input (no spec)                    |
| ↳ RichTextArea         |  ❌   |    ❌     |   N/A   |   ❌   |    -    | Rich text editor (Trix/TipTap, no spec)            |
| ↳ SearchFields         |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Search input with DaisyUI input classes            |
| ↳ SelectFields         |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Native select with DaisyUI select classes          |
| ↳ SlimSelectFields     |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Slim Select enhanced dropdown                      |
| ↳ StepNumberFields     |  ✅   |    ❌     |   ✅    |   ❌   |    -    | +/- step number input                              |
| ↳ SubmitFields         |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Submit button with DaisyUI btn classes             |
| ↳ SwitchFields         |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Toggle switch with DaisyUI toggle classes          |
| ↳ TextFields           |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Text input with DaisyUI input classes              |
| ↳ TextAreaFields       |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Textarea with DaisyUI textarea classes             |
| ↳ TimeFields           |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Time picker with Flatpickr                         |
| ↳ TimePeriodFields     |  ❌   |    ❌     |   N/A   |   ❌   |    -    | Time period input (no spec)                        |
| ↳ TimeZoneSelect       |  ✅   |    ❌     |   ✅    |   ❌   |    -    | Time zone selector with DaisyUI select             |
| ↳ UrlFields            |  ❌   |    ❌     |   ✅    |   ❌   |    -    | URL input (no spec)                                |
| GanttChart             |  ✅   |    ❌     |   N/A   |   ❌   |  8/10   | Bulma→DaisyUI, explicit action methods, 21 tests   |
| Heatmap                |  ✅   |    ❌     |   N/A   |   ✅   |  9/10   | Frozen constants, required data:, validated dimensions, 26 tests |
| Hero                   |  ✅   |    ❌     |   ✅    |   ❌   |  9/10   | Private attr_reader, Hash#fetch, Bali::Button preview |
| HoverCard              |  ✅   |    ✅     |   N/A   |   ✅   |  9/10   | PLACEMENTS const, loading spinner for async, 43 tests |
| Icon                   |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | Lucide integration, resolution pipeline            |
| ImageField             |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | SIZES const, class_names, Button for clear, i18n, 31 tests |
| ImageGrid              |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | COLUMNS/GAPS/ASPECT_RATIOS, class_names, 34 tests  |
| InfoLevel              |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | BASE_CLASSES, ALIGNMENTS.fetch, private attr, 22 tests |
| LabelValue             |  ✅   |    ✅     |   ✅    |   ✅   |  9/10   | LABEL/VALUE_CLASSES, class_names, private options, 7 tests |
| Level                  |  ✅   |    ❌     |   ✅    |   ❌   |  9/10   | BASE_CLASSES, private attr, ALIGNMENTS.fetch, 14 tests |
| Link                   |  ✅   |    ❌     |   ❌    |   ❌   |   🔄    | Review in progress                                 |
| List                   |  ✅   |    ❌     |   ✅    |   ❌   |  9/10   | DaisyUI list/list-row, BASE_CLASSES, 19 tests      |
| Loader                 |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| LocationsMap           |  ✅   |    ❌     |   N/A   |   ❌   |    -    | Custom component                                   |
| Message                |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| Modal                  |  ✅   |    ✅     |   ✅    |   ❌   |  9/10  | Slots for header/body/actions, WCAG accessibility  |
| Navbar                 |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| Notification           |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| PageHeader             |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| Progress               |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| PropertiesTable        |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| Rate                   |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| RecurrentEventRuleForm |  ✅   |    ❌     |   N/A   |   ❌   |    -    | Custom component                                   |
| Reveal                 |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| RichTextEditor         |  ✅   |    ❌     |   N/A   |   ❌   |    -    | Custom (TipTap)                                    |
| SearchInput            |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| SideMenu               |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| SortableList           |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| Stepper                |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| Table                  |  ✅   |    ✅     |   ✅    |   ❌   |    -    | Needs manual review                                |
| Tabs                   |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Cypress tests fixed                                |
| Tag                    |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| Tags                   |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| Timeago                |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| Timeline               |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| Tooltip                |  ✅   |    ❌     |   ❌    |   ❌   |    -    | Needs verification                                 |
| TreeView               |  ✅   |    ✅     |   ✅    |   ❌   |    -    | Needs manual review                                |
| TurboNativeApp         |  ✅   |    ❌     |   N/A   |   ❌   |    -    | Custom component                                   |

---

## Summary

> **Branch**: All work is on `tailwind-migration` branch.

| Status         | Tests  | AI Visual | DaisyUI | Manual | Quality |
| -------------- | :----: | :-------: | :-----: | :----: | :-----: |
| ✅ Complete    |   76   |    17     |   36    |   14   |   22    |
| ⚠️ Partial     |   0    |     0     |    0    |    0   |    1    |
| ❌ Not Started |   5    |    64     |   34    |   67   |   58    |
| N/A            |   0    |     0     |   11    |    0   |    0    |
| **Total**      | **81** |  **81**   | **81**  | **81** | **81**  |

> **Note**: 81 = 56 original components - 1 (Form) + 26 form field modules

### Quality Score Summary

| Score Range | Count | Components |
|-------------|-------|------------|
| 9-10 (✅)   | 26    | ActionsDropdown (9.5), AdvancedFilters (9), Avatar (9.5), BooleanIcon (9), Breadcrumb (9), BulkActions (9), Calendar (9), Card (9), Carousel (9), Chart (9), Clipboard (9), Columns (9), DataTable (9), DeleteLink (9), Drawer (9), Dropdown (9), FieldGroupWrapper (9), FlashNotifications (9), Heatmap (9), Hero (9), HoverCard (9), Icon (9), InfoLevel (9), LabelValue (9), Level (9), Modal (9) |
| 7-8 (⚠️)    | 1     | GanttChart (8) |
| < 7 (❌)    | 0     | - |
| Not scored  | 54    | Form fields (26), remaining components (28) |

---

## Fully Verified Components (14)

Components with ✅ in all applicable columns:

1. **ActionsDropdown** - Full DaisyUI dropdown with align/direction
2. **AdvancedFilters** - NEW, Ransack integration
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
13. **DataTable** - Migrated to AdvancedFilters, column selector, sorting, pagination
14. **DeleteLink** - HoverCard confirmation with DaisyUI styling

---

## DaisyUI Component Mapping

### High Priority

| Bali         | DaisyUI                                                    | Status     |
| ------------ | ---------------------------------------------------------- | ---------- |
| Avatar       | [avatar](https://daisyui.com/components/avatar/)           | ✅ Done    |
| Card         | [card](https://daisyui.com/components/card/)               | ✅ Done    |
| Table        | [table](https://daisyui.com/components/table/)             | ✅ Done    |
| Breadcrumb   | [breadcrumbs](https://daisyui.com/components/breadcrumbs/) | ✅ Done    |
| Modal        | [modal](https://daisyui.com/components/modal/)             | ❌ Pending |
| Dropdown     | [dropdown](https://daisyui.com/components/dropdown/)       | ✅ Done    |
| Tabs         | [tabs](https://daisyui.com/components/tab/)                | ❌ Pending |
| Navbar       | [navbar](https://daisyui.com/components/navbar/)           | ❌ Pending |
| Drawer       | [drawer](https://daisyui.com/components/drawer/)           | ❌ Pending |
| Notification | [alert](https://daisyui.com/components/alert/)             | ❌ Pending |

### Medium Priority

| Bali     | DaisyUI                                              | Status     |
| -------- | ---------------------------------------------------- | ---------- |
| Loader   | [loading](https://daisyui.com/components/loading/)   | ❌ Pending |
| Progress | [progress](https://daisyui.com/components/progress/) | ❌ Pending |
| Rate     | [rating](https://daisyui.com/components/rating/)     | ❌ Pending |
| Stepper  | [steps](https://daisyui.com/components/steps/)       | ❌ Pending |
| Tag      | [badge](https://daisyui.com/components/badge/)       | ❌ Pending |
| Timeline | [timeline](https://daisyui.com/components/timeline/) | ❌ Pending |
| Tooltip  | [tooltip](https://daisyui.com/components/tooltip/)   | ❌ Pending |

### Custom (No DaisyUI equivalent)

Chart, GanttChart, Heatmap, LocationsMap, RichTextEditor, RecurrentEventRuleForm

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

| Date       | Component                    | Change                                                                       | By         |
| ---------- | ---------------------------- | ---------------------------------------------------------------------------- | ---------- |
| 2026-01-15 | DataTable                    | Migrated to AdvancedFilters, added column selector, sorting/pagination demos | AI + Human |
| 2026-01-15 | AdvancedFilters              | NEW: Complex filter UI with Ransack                                          | AI         |
| 2026-01-15 | Tabs                         | Fixed Cypress selectors for DaisyUI                                          | AI         |
| 2026-01-15 | CI                           | Fixed Cypress workflow                                                       | AI         |
| 2026-01-14 | Columns                      | Flexbox layout fix                                                           | AI + Human |
| 2026-01-14 | Carousel                     | CSS nesting, arrows, swipe/drag                                              | AI + Human |
| 2026-01-13 | Multiple (11)                | Manual verification                                                          | Human      |
| 2026-01-13 | Table, TreeView, BulkActions | Fixed is-hidden→hidden                                                       | AI         |
| 2026-01-17 | Infrastructure               | Add parallel review tooling + quality score tracking                         | AI         |
| 2026-01-17 | Card                         | Score 8→9: Fixed header badge positioning, removed redundant border classes  | AI         |
| 2026-01-17 | Modal                        | Score 7→9: Added header/body/actions slots, WCAG aria-describedby            | AI         |
| 2026-01-17 | ActionsDropdown              | Score 9.5: Semantic button, ARIA attrs, consistent preview API               | AI         |
| 2026-01-17 | AdvancedFilters              | Score 9: Removed unused @options, added class_names helpers, fixed trailing spaces | AI         |
| 2026-01-17 | Avatar                       | Score 9.5: Group tag.div+options, alt text support, fixed preview path       | AI         |
| 2026-01-17 | BooleanIcon                  | Score 9: Added nil value handling, improved tests, all_states preview        | AI         |
| 2026-01-17 | Breadcrumb                   | Score 9: Added aria-label, BASE_CLASSES constant, private attr_readers       | AI         |
| 2026-01-17 | BulkActions                  | Score 9: CLASSES hash, tag.div template, ITEM_CLASSES constant               | AI         |
| 2026-01-17 | Calendar                     | Score 9: class_names helpers, Bali::Link components, aria-labels             | AI         |
| 2026-01-17 | Carousel                     | Score 9: class_names refactor, i18n aria-labels, documented slots            | AI         |
| 2026-01-17 | Columns                      | Score 9: Flexbox→CSS Grid, gap param, col-span-* classes, narrow→auto        | AI         |
| 2026-01-17 | Chart                        | Score 9: Explicit params, frozen constants, Dataset refactor, Tailwind title | AI         |
| 2026-01-17 | Clipboard                    | Score 9: DaisyUI join pattern, BASE_CLASSES, aria-label, 18 tests            | AI         |
| 2026-01-17 | DeleteLink                   | Score 9: SIZES const, class_names, explicit authorized param, 20 tests       | AI         |
| 2026-01-17 | Dropdown                     | Score 9: i18n aria-label, Trigger VARIANTS const, 21 tests                   | AI         |
| 2026-01-17 | Drawer                       | Score 9: Unique IDs, POSITIONS const, header/footer slots, WCAG, 32 tests    | AI         |
| 2026-01-17 | FieldGroupWrapper            | Score 9: DaisyUI form-control, class_names, no options mutation, 18 tests    | AI         |
| 2026-01-17 | FlashNotifications           | Score 9: Private attr_readers, Lookbook params, 6 tests                      | AI         |
| 2026-01-17 | Filters                      | **DEPRECATED**: Emits warning, recommend AdvancedFilters                     | AI         |
| 2026-01-17 | AdvancedFilters              | Date range: Flatpickr range mode, locale-aware formats, fix "between" reload               | AI         |
| 2026-01-17 | Form (FormBuilder)           | Score 9: Full Bulma→DaisyUI migration across 12 modules, 117 tests           | AI         |
| 2026-01-17 | GanttChart                   | Score 8: Bulma→DaisyUI (join, weekend), explicit action methods, 21 tests    | AI         |
| 2026-01-17 | Hero                         | Score 9: Private attr_reader, Hash#fetch, preview uses Bali::Button          | AI         |
| 2026-01-17 | Heatmap                      | Score 9: Frozen constants, required data:, validated dimensions, 26 tests    | AI         |
| 2026-01-17 | Icon                         | Score 9: Lucide integration, SIZE_SVG_CLASSES const, normalize_constant_name helper, 41 tests | AI         |
| 2026-01-17 | DeleteLink                   | Manually verified: HoverCard confirmation renders correctly                  | Human      |
| 2026-01-17 | Drawer                       | Manually verified: Fixed Tailwind JIT for open class, render_with_template for slots preview | Human      |
| 2026-01-17 | HoverCard                    | Score 9: PLACEMENTS/TRIGGERS constants, class_names, data merge, 43 tests    | AI         |
| 2026-01-17 | ImageField                   | Score 9: SIZES const, src: keyword, Button for clear action, i18n, memory cleanup, 31 tests | AI         |
| 2026-01-17 | InfoLevel                    | Score 9: BASE_CLASSES, ALIGNMENTS.fetch, nav→div semantics, private attr, 22 tests | AI         |
| 2026-01-17 | LabelValue                   | Score 9: LABEL/VALUE_CLASSES, class_names, private options, 7 tests          | AI         |
| 2026-01-17 | HoverCard                    | Manually verified: Loading spinner for async content, all placements work    | Human      |
| 2026-01-17 | InfoLevel                    | Manually verified: Alignment options, heading/title slots render correctly   | Human      |
| 2026-01-17 | List                         | Score 9: DaisyUI list/list-row, ul/li semantics, BASE_CLASSES, 19 tests      | AI         |
| 2026-01-17 | Level                        | Score 9: BASE_CLASSES, private attr, ALIGNMENTS.fetch, preview params fixed, 14 tests | AI         |