# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v2.0.6] - 2026-02-03

### Added

- **Columns Component** - Added Bulma-compatible column system with Tailwind implementation
  - Tailwind display utilities support on Column component
- **Filters Component** - Added preserved query params support for maintaining URL state
- **Filters Component** - Added turbo_stream support and refactored controller submission logic
- **FilterForm** - Made `ransack_params` public for component access
- **SideMenu Component** - Added `target` and `rel` attributes support for menu items

### Changed

- **ImageField Component** - Render input using `raw_file_field` to bypass custom form builder wrappers
- **ImageField Component** - Wrap icon in span and remove `text-base-content` class from icon styling

### Fixed

- **Drawer & Modal Components** - Adjusted z-index values and positioning to improve layering behavior
- **SlimSelect** - Fixed `slim_select_field` to deep merge data attributes instead of overwriting

## [v2.0.5] - 2026-02-03

### Added

- **Form::Errors Component** - New component for displaying form validation error summaries
  - Renders error list using `Bali::Message::Component` with error styling
  - Only renders when model has errors (`render?` returns false otherwise)
  - Supports optional `title` parameter for custom header text
  - FormBuilder integration via `f.error_summary` helper method

- **DirectUpload Component** - Auto-clear files on successful Turbo form submission
  - Listens for `turbo:submit-end` event on parent form
  - Clears file list when `event.detail.success` is true (2xx response)
  - Files remain on failed submissions so users can retry

### Fixed

- **DirectUpload Component** - Fixed field name generation when using `form_with url:` without a model
  - Previously generated `[method][]` instead of `method[]` when `form.object_name` was empty
  - Now correctly handles empty object names for both single and multiple file modes

### Changed

- **Release Skill** - Rewritten with two-phase PR workflow
  - Phase 1: Creates release prep PR with changelog updates for review
  - Phase 2: After merge, bumps version, tags, and publishes GitHub release
  - New `--continue` flag to run Phase 2 after PR is merged
  - State persistence via `.release-pending.json` between phases

## [2.0.4] - 2026-01-30

### Added

- **Link Component** - Dynamic size support for Modal and Drawer
  - New nested options syntax: `modal: { size: :lg }` and `drawer: { size: :lg }`
  - Backward compatible: `modal: true` and `drawer: true` still work with default sizes

### Changed

- **Drawer Component** - Standardized size names to match other Bali components
  - `narrow` → `sm`
  - `medium` → `md` (default)
  - `wide` → `lg`
  - `extra_wide` → `xl`
  - Added `full` size option

## [2.0.3] - 2026-01-30

### Changed

- **JavaScript Imports** - Redesigned import strategy for standard npm package usage
  - Converted all internal `bali/...` imports to relative paths
  - Added `exports` field to package.json for proper module resolution
  - Consuming apps no longer need complex bundler alias configuration
  - Import from `'bali-view-components'` instead of internal paths

## [2.0.2] - 2026-01-28

### Added

- **Link Component** - Added `soft` and `outline` styles to `Bali::Link::Component`
- **Message Component** - Added style variants (`soft`, `outline`, `dash`) to `Bali::Message::Component`
- **Notification Component** - Added `style` options and updated tag's rounded class
- **Tag Component** - Added a new preview page showcasing all variations and combinations
- **SlimSelect** - Added `results_text` support and `resultsText` option for grouping AJAX results
- **Utility** - Added `.box` utility class
- **Translations** - Added "results" translation key for select menu in English and Spanish

### Changed

- **Drawer Component** - Refactored overlay visibility and z-index
- **Tag Component** - Made `text` attribute optional, falling back to content
- **Dropdown Component** - Render dropdown menu items as plain links
- **Internal** - Relocated component-specific CSS variables to `bali-` prefixed variables and updated `build_url` calls


## [2.0.1] - 2026-01-27

### Changed

- **Filters Component** - Consolidated `AdvancedFilters` and `Filters` into a single unified `Filters` component
  - Removed separate `AdvancedFilters` component (functionality merged into `Filters`)
  - Added search input with clear button (x) for easy clearing of persisted search
  - Improved filter persistence handling with `clear_search` parameter

### Fixed

- **FilterForm** - Refactored into focused concerns for better maintainability
  - Extracted `SearchConfiguration` concern for search DSL and methods
  - Extracted `FilterGroupParser` concern for Ransack grouping parsing
  - Fixed search persistence bug where clearing search text didn't clear persisted value

### Dependencies

- Added `lucide-rails` as runtime dependency for icon rendering
- Updated `@source` directive documentation for Tailwind v4 configuration

## [2.0.0] - 2026-01-26 - Tailwind + DaisyUI Migration

**This is a major release migrating all 60+ components from Bulma CSS to Tailwind + DaisyUI 5.**

### Infrastructure

- Added Tailwind CSS build step to CI pipeline for proper asset compilation

### Breaking Changes

- **`Bali::Link::Component`** - `type:` parameter deprecated. Use `variant:` instead.
  - Added backwards compatibility: passing `type:` still works but logs deprecation
  - New `variant:` supports: `:primary`, `:secondary`, `:accent`, `:info`, `:success`, `:warning`, `:error`, `:ghost`, `:link`, `:neutral`
  - New `size:` parameter: `:xs`, `:sm`, `:md`, `:lg`, `:xl`
  - New `plain:` parameter for links without button styling
  - New `authorized:` parameter for permission-based rendering

  ```ruby
  # Before
  render Bali::Link::Component.new(href: '/users', name: 'Users', type: :primary)

  # After
  render Bali::Link::Component.new(href: '/users', name: 'Users', variant: :primary)
  ```

- **`Bali::Card::Component`** - `footer_items` slot removed. Use `actions` slot instead.
  - New slot structure: `header`, `title`, `image`, `actions`
  - Actions render inside `card-actions` container with proper DaisyUI styling

  ```ruby
  # Before
  render Bali::Card::Component.new do |c|
    c.with_footer_item { render Bali::Button::Component.new(name: 'Save') }
  end

  # After
  render Bali::Card::Component.new do |c|
    c.with_action { render Bali::Button::Component.new(name: 'Save') }
  end
  ```

- **`Bali::Filters::Component`** - Consolidated filter component (replaces old Filters and AdvancedFilters)
  - Multiple filter groups with AND/OR combinators between groups
  - Multiple conditions within each group with AND/OR combinators
  - Type-specific operators for text, number, date, select, and boolean fields

- **`Bali::Breadcrumb::Item::Component`** - `href` is now optional (was required).
  - Items without `href` are automatically marked as active
  - Parameter order changed: `name:` is now the primary parameter
  - Links only show underline on hover (not by default)
  - Active items render as non-clickable `<span>` elements with `cursor-default`
  - Removed legacy BEM classes (`breadcrumb-component`, `breadcrumb-item-component`)
  - Added `aria-current="page"` to active items for accessibility

  ```ruby
  # Before
  c.with_item(href: '/page', name: 'Current', active: true)

  # After (simplified - no href means auto-active)
  c.with_item(name: 'Current')
  ```

- **`Bali::Tag::Component`** - `tag_class:` parameter deprecated. Use `color:` instead.

- **`Bali::Calendar::Component`** - `all_week:` parameter deprecated. Use `weekdays_only:` instead.

- **CSS Class Changes** - All Bulma classes replaced with DaisyUI equivalents:
  - `is-primary` → `btn-primary`, `badge-primary`, etc.
  - `is-danger` → `*-error` (DaisyUI uses "error" not "danger")
  - `is-small/medium/large` → `*-sm/md/lg`
  - `columns` → `grid grid-cols-*`
  - `card-content` → `card-body`
  - `notification` → `alert`
  - See `docs/migration/BREAKING_CHANGES.md` for complete mapping

### Added

- **`Bali::FilterForm`** - Enhanced filter form with Ransack groupings support
  - Dynamic add/remove for both conditions and groups
  - Pre-populated filters from URL params
  - Quick search integration and reset functionality
  - Date range "between" operator uses Flatpickr range mode
  - Locale-aware date formats: `M j, Y` for English, `j M Y` for Spanish

- **`Bali::Button::Component`** - Proper ViewComponent (was previously a helper)
  - Full DaisyUI button support with variants, sizes, states
  - Loading state with spinner
  - Icon support (left and right)
  - Disabled state

- **`Bali::Avatar::Group::Component`** - Display grouped avatars with overlap styling
- **`Bali::Avatar::Upload::Component`** - Avatar with upload/edit functionality

- **`Bali::Card::Action::Component`** - Card action button/link for footer actions

- **`Bali::DataTable::ColumnSelector::Component`** - Toggle table column visibility
  - Supports hiding columns by default
  - Works by column index, no coordination needed between selector and table cells

- **`Bali::DataTable::Export::Component`** - Export data table to various formats

- **`Bali::DirectUpload::Component`** - Direct file upload with progress indication

- **`Bali::Modal::Header::Component`** - Modal header slot component
- **`Bali::Modal::Body::Component`** - Modal body slot component
- **`Bali::Modal::Actions::Component`** - Modal actions/footer slot component

- **`Bali::Pagination::Component`** - Standalone pagination component using Pagy

- **Icon System Overhaul** - New Lucide-based icon resolution pipeline
  - 1,600+ Lucide icons available directly
  - Backwards compatible: old Bali icon names still work (mapped to Lucide equivalents)
  - Kept icons: brand logos (Visa, Mastercard, PayPal), social (WhatsApp, Facebook), regional (flags)
  - Custom icons: app-specific via `Bali.custom_icons`
  - New `size:` parameter: `:small`, `:medium`, `:large`

- **Stimulus Controllers**
  - `advanced-filters` - Main filter UI controller
  - `filter-group` - Filter group management
  - `condition` - Individual condition management
  - `column-selector` - Table column visibility toggle

- **Dependencies**
  - Added `pagy` gem (~> 8.0) for pagination
  - Added `lucide-rails` gem for Lucide icon integration

### Changed

- **All 60+ Components** - Migrated from Bulma SCSS to Tailwind + DaisyUI 5
  - Removed all `.scss` files, using `.css` with `@apply` or inline Tailwind classes
  - Components now use DaisyUI semantic classes (`btn`, `card`, `modal`, etc.)
  - Responsive design using Tailwind breakpoints

- **`Bali::Calendar::Component`** - Refactored with improved API (backward compatible)
  - `start_date` now accepts `Date` objects directly (strings still work)
  - New `weekdays_only:` parameter replaces confusing `all_week:` (deprecated but still works)
  - Extracted `EventGrouper` class for cleaner event grouping logic
  - Added helper methods: `month_view?`, `week_view?`, `show_weekends?`, `weekdays_only?`
  - Preview consolidated from 7 methods to 3 with `@param` annotations
  - Added 14 new tests (33 total)

- **`Bali::DataTable::Component`** - Uses consolidated `Filters` component with Ransack groupings support
  - New `filters_panel` slot accepts `available_attributes:` for defining filterable fields
  - New `toolbar_buttons` slot for right-aligned buttons (column selector, export, etc.)
  - Added sorting examples using Ransack's `sort_link` helper
  - Added pagination examples using Pagy

- **`Bali::Modal::Component`** - New slot-based API
  - Uses native `<dialog>` element with DaisyUI modal styling
  - New slots: `header`, `body`, `actions`
  - Backdrop click to close
  - Escape key to close

- **`Bali::Dropdown::Component`** - Migrated to DaisyUI dropdown
  - Uses `dropdown`, `dropdown-content`, `menu` classes
  - Supports positioning: `dropdown-end`, `dropdown-top`, `dropdown-left`, `dropdown-right`

- **`Bali::Table::Component`** - Migrated to DaisyUI table
  - Uses `table`, `table-zebra`, `table-pin-rows`, `table-pin-cols` classes
  - Sticky headers supported via `table-pin-rows`

- **`Bali::Tabs::Component`** - Migrated to DaisyUI tabs
  - Uses `tabs`, `tabs-box`, `tab`, `tab-active` classes

- **`Bali::Tooltip::Component`** - Migrated to DaisyUI tooltip
  - Uses `tooltip`, `tooltip-*` positioning classes
  - Removed Tippy.js dependency for simple tooltips

- **`Bali::Timeline::Component`** - Migrated to DaisyUI timeline
  - Uses `timeline`, `timeline-start`, `timeline-middle`, `timeline-end` classes

- **`Bali::Stepper::Component`** - Migrated to DaisyUI steps
  - Uses `steps`, `step`, `step-primary/secondary/etc` classes

- **`Bali::Progress::Component`** - Migrated to DaisyUI progress
  - Uses `progress`, `progress-primary/secondary/etc` classes

- **`Bali::Notification::Component`** - Migrated to DaisyUI alert
  - Uses `alert`, `alert-info/success/warning/error` classes

- **`Bali::Loader::Component`** - Migrated to DaisyUI loading
  - Uses `loading`, `loading-spinner/dots/ring/ball/bars/infinity` classes

- **`Bali::SideMenu::Component`** - Migrated to DaisyUI menu
  - Uses `menu`, `menu-title`, DaisyUI collapse for nested items
  - Improved collapsed state with tooltips

- **Form Components** - All 27+ form field components migrated
  - Inputs use `input`, `input-bordered`, `input-*` classes
  - Selects use `select`, `select-bordered` classes
  - Checkboxes use `checkbox`, `checkbox-*` classes
  - File inputs use `file-input`, `file-input-bordered` classes

### Removed

- **SCSS Files** - All component `.scss` files removed (replaced with `.css` or inline Tailwind)
- **Bulma Dependencies** - No longer requires Bulma CSS framework
- **`Bali::Card::FooterItem::Component`** - Removed, use `actions` slot instead

### Migration Guide

See `docs/migration/BREAKING_CHANGES.md` for:
- Complete Bulma → DaisyUI class mapping table
- Per-component migration examples
- Step-by-step upgrade instructions

## [1.4.23] - 2025-12-12

### Changed

- `Bali::SideMenu::Item::Component` to display a tooltip when the menu is collapsed.

## [1.4.22] - 2025-12-12

### Changed

- Update filter form submission to prevent default behavior, update URL, and enable custom search input button options.

## [1.4.21] - 2025-11-28

### Added

- `Bali::DataTable::Action::Component` to encapsulate action rendering with optional description tooltips.

### Changed

- `Bali::DataTable::ActionsPanel::Component` now uses `Bali::DataTable::Action::Component` for rendering actions, enabling support for action descriptions via tooltips.

## [1.4.20] - 2025-11-27

### Added

- `Rrule::EnglishHumanizer` service to convert RRule objects to human-readable English text.
- `Rrule::SpanishHumanizer` service to convert RRule objects to human-readable Spanish text.
- `Bali::Concerns::GlobalIdAccessors` concern to define GlobalID getter and setter methods for ActiveRecord associations.
- `rrule` gem dependency for recurrence rule handling.

### Changed

- Updated `Bali::RecurrentEventRuleForm::Component` to display humanized recurrence rules in English and Spanish.
- Added RRule override to support `humanize` method with locale parameter.

## [1.4.19] - 2025-11-25

### Added

- `is-borderless` class support to `Bali::List::Component` to remove the border styling.

## [1.4.18] - 2025-11-18

### Changed

- Add more space between collection filters with multiple options and few options

## [1.4.17] - 2025-10-28

### Changed

- Allow `Bali::DataTable::ActionsPanel::Component` to render custom actions.

### Fixed

- Avoid non query param conversion to array when adding new ones to a url.

## [1.4.16] - 2025-10-28

### Changed

- Allow `Bali::Filters::Component` to receive options such as data.

## [1.4.15] - 2025-10-27

### Added

- `authorized?` method to `Bali::Link::Component` and `Bali::DeleteLinkComponent`
- `items` slot to `Bali::ActionsDropdown` component.

### Changed

- Use `Bali::Link::Component` for `items` slot instead of `Bali::Dropdown::Item::Component` in `Bali::Dropdown::Component`

## [1.4.14] - 2025-10-22

### Added

- `grid`, `list` icons.
- `Bali::DataTable::ActionsPanel::Component` component.

## [1.4.13] - 2025-09-24

### Added

- `checkbox-reveal-controller.js` stimulus controller.
- `Bali::Image::Component` component. This component renders an image and allow to render an input to change and clear the image

## [1.4.12] - 2025-09-24

### Fixed

- maintain collapsed side menu after redirections

## [1.4.11] - 2025-09-23

### Added

- `menu_switches` slot to `Bali::SideMenu::Component`.
- `collapsable` attribute to `Bali::SideMenu::Component`.

## [1.4.10] - 2025-09-12

### Added

- `after-change-fetch-url-value` to `slim-select-controller.js`. When this value is present the controller will peform a fetch request after the value of the select has changed.

## [1.4.9] - 2025-09-09

### Changed

- `Bali::Filters::Component` to render the right input for each `ransack` predicate.

## [1.4.8] - 2025-09-04

### Changed

- `time_period_select_field` and `time_period_select_field_group` to `Bali::FormBuilder`
- `Bali::TimePeriods::SelectOptions` as default time periods for `time_period_select_*` fields.

## [1.4.7] - 2025-08-29

### Changed

- `Bali::RecurrentEventRuleForm` component.
- `recurrent_event_rule_field` and `recurrent_event_rule_field_group` to `Bali::FormBuilder`

## [1.4.6] - 2025-07-28

### Changed

- `submit` function of `ModalController` to check and report inputs validity

## [1.4.5] - 2025-07-29

### Changed

- Upgrade `gems` and `importmap`
- Replace `code climate` with `qlty`

## [1.4.4] - 2025-06-11

### Changed

- `datepicker-controller` and `date fields` to support disabling specific dates.

## [1.4.3] - 2025-05-29

### Changed

- `slim-select` to support rendering custom HTML for remote search results.

## [1.4.2] - 2025-04-23

### Changed

- `Bali::SideMenu::Component` component to preserve scroll position when a link has been clicked

- `Bali::SideMenu::Item::Component` component to add `is-list` class when items are present.

## [1.4.1] - 2025-03-27

### Changed

- `Table` component to allow bulk actions to render a modal and add custom style

## [1.4.0] - 2024-02-20

### Updated

- Upgrade `rails` to version `8.0.1`
- Upgrade `ruby` to version `3.3.7`
- Updated `gems` and importmap

## [1.3.3] - 2024-02-25

### Fixed

- value was displayed as `undefined` when adding a suffix or prefix in a pie or doughnut chart.

## [1.3.2] - 2024-01-30

### Fixed

- Redirection issues when attempting to open a restricted modal.

## [1.3.1] - 2024-12-20

### Changed

- Set `modal` attribute to `false` when link is disabled (`Bali::Link::Component`)

## [1.3.0] - 2024-10-18

### Changed

- Upgrade to `rails` to `7.2`
- Update `gems` and `importmap`

## [1.2.5] - 2024-09-17

### Changed

- Added `submit-actions` class name to `submit_actions` fields helper.

## [1.2.4] - 2024-07-25

### Changed

- Updated `rails` to version `7.1.4`

## [1.2.3] - 2024-07-25

### Changed

- Updated gems and npm packages

## [1.2.2] - 2024-06-06

### Fixed

- Cannot read properties of undefined (reading 'destroy') in `stimulus` controllers.
- Missing target element "menu" for "navbar" controller

## [1.2.1] - 2024-05-20

### Fixed

- Incorrect `for` attribute value in radio buttons of `radio_buttons_field_group` when value is a datetime

## [1.2.0] - 2024-05-06

### Changed

- import `GoogleMapsLoader` dynamically
- import `tippy` dynamically
- import `Sortable` dynamically
- import `Chart` dynamically
- import `MarkerClusterer` dynamically
- import `createPopper` dynamically

## [1.1.1] - 2024-05-09

### Fixed

- imports with relative paths were failing in `js` files.

## [1.1.0] - 2024-03-08

### Added

- Button to clear polygons in coordinates polygon field
- Button to clear holes in coordinates polygon field

## [1.0.0] - 2024-04-17

### Changed

- Migrated from `jsbundling-rails` to `importmaps-rails`

## [0.76.0] - 2024-04-17

### Added

- Updated `gems` and `npm` packages

## [0.75.0] - 2024-02-28

### Added

- `Bali::Commands::XlsxExport` class. This class allows us to use DSL in xlsx export.

## [0.74.1] - 2024-02-19

### Fixed

- Fix InputOnChangeController#change. Updated to use the new Slim Select 2.0 API.

## [0.74.0] - 2024-02-15

### Changed

- Allow `DrawingMapsController` to draw and export multiple polygons classified into shells and holes. As a result, the value from `coordinates_field` and `coordinated_field_group` has changed from `[{ lat: , lng:}]` to `{ shells: [{ lat: , lng:}], holes: [{ lat: , lng:}] }`. This format `[{ lat: , lng:}]` is still working to initilize the polygons within the map, but changes in the map will be store using the new format.

## [0.73.0] - 2024-01-31

### Fixed

- Slim select does not render

## [0.73.0] - 2024-01-30

### Changed

- Updated gems and npm packages

## [0.72.0] - 2024-01-26

### Added

- `Bali::Commands::CsvExport` class. This class allows us to use DSL in csv export.

## [0.71.1] - 2024-01-22

### Fixed

- Use `as` attribute of `form_for` in the `id` of the radio buttons when using `radio_buttons_group`

## [0.71.0] - 2023-11-28

### Added

- `Bali::BulkActions::Component` component. This component enables you to double-click on multiple DOM elements, selecting them, and subsequently applying an action.

## [0.70.0] - 2023-10-06

### Added

- `Cards` to `LocationsMap::Component`. These cards help to display detailed information for each marker. When a marker is clicked on, all cards matching the latitude and longitude of the marker will have the `is-selected` class added to them.

## [0.69.0] - 2023-09-19

### Changed

- Unify the data structure of the `Chart` component and `Chart.js`.

## [0.68.1] - 2023-09-19

### Fixed

- `name` attribute of the html `label` element of `switch_field_group`.

## [0.68.0] - 2023-09-19

### Added

- Add `display_percent` option on `Chart::Component` for automatically calculating and displaying percentages on the tooltip

## [0.67.3] - 2023-08-23

### Added

- `youtube` icon
- `title` to `mexican flag` icon
- `title` to `usa flag` icon
- `title` to `shopping cart` icon

### Changed

- color of the `facebook` and `instagram` icons to `currentColor`

### Changed

- `facebook` and `instagram` icons to fill with the current color.

## [0.67.2] - 2023-08-23

### Added

- `.is-margin-auto` CSS style
- `.is-circle` CSS style
- `.is-unclosable` CSS stlye to notification component. This css style hides the button to close the notification
- `icon_tag` helper method
- `Bali::TenancyTestsHelper`
- `Bali::TestsHelper`
- `Bali::Concerns::Mailers::RecipientsSanitizer`. This concern includes `send_mail` method, which removes inactive emails before sending mail.
- `Bali::Concerns::Mailers::UtmParams`
- `Bali::FlashNotifications::Component`

## [0.67.1] - 2023-08-15

### Changed

- Add CSS classes for different widths for select fields

## [0.67.0] - 2023-08-11

### Added

- Add ability to add custom filters on the Filters::Component
- Create `Bali::Types::DateRangeValue` to support :date_range type in `attribute` method

## [0.66.3] - 2023-08-08

### Added

- Custom class in the `currency_field_group` label when it renders a tooltip.

### Fixed

- Issue when an input field has an add-on and error

## [0.66.2] - 2023-07-18

### Added

- `Bali::Concerns::SoftDelete`
- `Bali::Concerns::Controllers::DeviceConcern`
- `GeocodeAdddressController` (javascript)
- `ios_naitve_app_user_agent` and `android_native_app_user_agent` as `Bali` configuration

## [0.66.1] - 2023-07-12

### Fixed

- Skip rendering for `ActionsDropdown::Component` when no content is present

## [0.66.0] - 2023-06-16

### Added

- Add `allow_input` to datepicker to be able to manually enter a date

## [0.65.1] - 2023-06-13

### Changed

- Relax ruby dependency to allow greater than `3.2`
- Update `library_version.thor` script to autodetect current version and increment it.
- Update Library authors

## [0.65.0] - 2023-06-07

### Changed

- Allow to add attributs to the FilterForm where only 1 value can be selected

### Fixed

- `TableController` check for elements presence before updating.

## [0.64.0] - 2023-06-05

### Added

- Add ability to add bulk actions to a `Table::Component`

## [0.63.0] - 2023-06-01

### Added

- Allow to persist the `FilterForm` filters across requests

## [0.62.0] - 2023-05-25

### Added

- Allow `slim_select_field` to autocomplete options from the server.

## [0.61.8] - 2023-05-23

### Changed

- Allow to add custom data attributes to `add/subtract` buttons in the step number field.

## [0.61.7] - 2023-05-14

### Fixed

- Pass the correct `route_path` argument instead of `route_name` to `Calendar::Header`

## [0.61.6] - 2023-04-18

### Changed

- Allows adding `custom icons` from the host application to the `Bali::Icon::Component`.

## [0.61.5] - 2023-03-31

### Added

- `Bali::Concerns::DateRangeAttribute` concern. This concern allows to define date range attributes, for example, `date_range_attribute :date_range, default: Time.zone.now.all_day`
- `max_date` option to `date_field_group` and `date_field`. you to set a maximum date that can be selected

## [0.61.4] - 2023-03-30

### Changed

- Renamed `route_name` to `route_path` in `Calendar` component. `route_path` expects a string, for example, `/lookbook`.

## [0.61.3] - 2023-03-26

### Fixed

- Fix `ransack` deprecation warning by avoiding passing a nil value to the `sort_link` method.

## [0.61.2] - 2023-03-14

### Added

- Add prefix and suffix to axis labels (`Chart` component)
- Prevent the tooltip title from being truncated (`Chart` component)
- Add prefix and suffix to tooltip label (`Chart` component)

## [0.61.1] - 2023-03-14

### Fixed

- Allow `TimeValue` to receive date string without seconds

## [0.61.0] - 2023-03-13

### Added

- Add `Message::Component`

### Changed

- Upgrade Gems

## [0.60.0] - 2023-03-13

### Changed

- `TimeValue`now returns a `Time` object when retrieved from DB to be able to format it.
- `time_field_group` is updated to handle a `Time` value instead of a `String`

## [0.59.2] - 2023-03-10

### Added

- Added sticky headers for table component.

## [0.59.1] - 2023-03-11

### Fixed

- Correctly scope the previous `ActionsDropddown::Component` css change.

## [0.59.0] - 2023-03-11

### Added

- Added a `readonly` option for the `Rate::Component` for display only purposes.

### Changed

- Add bottom-margin to `ActionsDropddown::Component` when placed inside a `.buttons` element to align with other buttons.

## [0.58.2] - 2023-02-20

### Changed

- Allow to override the `submit-on-change` `method` and `action` values throught the StimulusJS controller

## [0.58.1] - 2023-02-15

### Changed

- Ability to add multiple actions in a `List::Item::Component`
- Ability to add content in the middle of a `List::Item`

## [0.58.0] - 2023-02-11

### Changed

- Add ability to manage multiple files in a File Input

## [0.57.1] - 2023-02-02

### Added

- `@tiptap/pm` to `package.json` as `dependency`

### Fixed

- `Module not found` error when compiling assets in host application.

## [0.57.0] - 2023-01-31

### Fixed

- Added `Bali::Concerns::NumericAttributesWithCommas`. This concern complements the `percentage_field_group` and `currency_field_group` methods by removing the `commas` before saving the value to the DB.

## [0.56.3] - 2023-01-29

### Fixed

- Perform `Filters::Component` request with a `turbo_stream` format

## [0.56.2] - 2022-12-22

### Added

- Add `question-circle` icon

## [0.56.1] - 2022-12-20

### Added

- Add ability to specify a `submitter` on the `SubmitOnChange` controller in order to specify a different formaction and formmethod

## [0.56.0] - 2022-12-16

### Added

- Dispatch the `modal:success` event when the form is successfully submitted.

## [0.52.7] - 2022-12-06

### Added

- Allow to specity vertical alignment as a param for `Level::Component`

## [0.52.6] - 2022-12-02

### Changed

- Align file field ergonomics with other form inputs

## [0.52.5] - 2022-12-02

### Added

- Display all files selected in `file-input`

## [0.52.4] - 2022-12-02

### Fixed

- Fix `radio_field_group` display when it has an error.

## [0.52.3] - 2022-11-30

### Added

- Add `disabled` support for `Link::Component`

## [0.55.2] - 2022-11-30

### Added

- Add ability to display an icon in the trigger of the reveal component.

## [0.55.1] - 2022-11-16

### Added

- Add ability to hide `Table::Component` th

## [0.55.0] - 2022-11-16

### Added

- `Page Hyperlinks` to `Rich Text Editor`.

## [0.54.3] - 2022-11-15

### Added

- Add option to pass a container class to the `Navbar::Component`

## [0.54.2] - 2022-11-14

### Added

- `additional query params` to filters component. This helps to add query parameters not related to the form.

## [0.54.1] - 2022-11-11

### Updated

- Add a parameter to the `datepicker controller` to decide whether or not the alt input should be rendered.

## [0.54.0] - 2022-11-08

### Added

- Create `RichTextEditor::Component`

## [0.53.3] - 2022-10-21

### Added

- `wallet`, `wallet-alt`, `oxxo` icons.

## [0.53.2] - 2022-10-19

### Added

- Add option to specify a tooltip for a form label

## [0.53.1] - 2022-10-18

### Added

- Add `modal.fullwidth` class for full width modals
- Allow multiple CSS classes for the modal wrapper

## [0.53.0] - 2022-10-18

### Added

- Add `sparkles` icon

## [0.52.0] - 2022-10-17

### Changed

- Upgraded ruby and JS dependencies.

## [0.51.0] - 2022-10-15

### Added

- Create `ActionsDropdown::Component`

## [0.50.6] - 2022-10-14

### Added

- Add `chair`, `box-archive` and `file-export` icons
- Add option to add `custom-color` on tags

## [0.50.5] - 2022-10-14

### Added

- Add `url_field_group` form helper

## [0.50.4] - 2022-10-14

### Added

- Allow `SideMenu::Item` to render custom content

## [0.50.3] - 2022-10-13

### Added

- Add option to override when a `SideMenu::Item` should be active.

## [0.50.2] - 2022-10-12

### Added

- Add `align` option for `InfoLevel::Component`

## [0.50.1] - 2022-10-11

### Added

- `filters-alt` icon
- `closeOnClickOutside` as a value in `popup controller`. Default value is `true`.

## [0.50.0] - 2022-10-09

### Added

- Add `mode: range` for the `date_field` helper to allow for a range selection
- Create a preview for the `date_field`

## [0.49.0] - 2022-09-29

### Added

- Create `Hero::Component`

## [0.48.0] - 2022-09-29

### Added

- Create `LabelValue::Component` for displaying general values.

## [0.47.0] - 2022-09-27

### Updated

- `submit_actions` to display the cancel button in native apps when it is not being displayed inside a modal.

## [0.46.2] - 2022-09-27

### Fixed

- Display errors for `boolean_field_group` and fix styles when there are errors.

## [0.46.1] - 2022-09-27

### Fixed

- Add `is-danger` to datepicker input when there are errors.

## [0.46.0] - 2022-09-22

### Added

- `TurboNativeApp::SignOut` component.

## [0.45.1] - 2022-09-21

### Fixed

- Updated `GanttChart::Component` timeline headers calculation to fix current day flag and chart offset.

## [0.45.0] - 2022-09-15

### Updated

- Link component to add support for `native apps` when the `modal` attribute is set to `true`.
- Notification component to add `native-app` class. This class is useful for customizing the notification component when it appears in a native app.

## [0.44.0] - 2022-09-15

### Added

- Added a list footer to `GanttChart::Component`.

## [0.43.1] - 2022-09-13

### Fixed

- `dartsass-rails` requires replacing `image-url` with `url` to display icons/images.

## [0.43.0] - 2022-09-05

### Added

- Create `Progress::Component` for displaying a progress bar with percentage.

## [0.42.0] - 2022-08-30

### Added

- Create `List::Component` for displaying elements in a basic list

### Fixed

- Don't create a tippy instance when the contents are empty

## [0.41.2] - 2022-08-30

- Include third party CSS from the following libraries:
  - Trix
  - SlimSelect
  - Flatpickr

## [0.41.1] - 2022-08-29

- Allow `datepicker-controller` to enable/disabled weekends.

## [0.41.0] - 2022-08-27

- Migrate from `sassc-rails` to `dartsass-rails`
- Create new `PropertiesTable::Component`
- Add `Card::Header::Component` slot.
- Add `icon` option for `DeleteLink::Component` and add customize styles when it's inside a dropdown
- Add back button option for `PageHeader::Component`
- Update `more` icon

## [0.40.8] - 2022-08-27

- Add `month_field_group` method to generate fields with labels for date/year only inputs.

## [0.40.7] - 2022-08-24

- Added `badge-percent` icon.

## [0.40.6] - 2022-08-24

- Updated `GanttChart::Component` css to consider 4th level tasks.

## [0.40.5] - 2022-08-24

- Updated `Bali::Table::Component`. Fixes the `id` assignment for the table when `id` is defined inside `options`.

## [0.40.4] - 2022-08-24

- Updated `Bali::Table::Component`. Added an `id` to the `no records` row when the table is empty.

## [0.40.3] - 2022-08-24

- Add `infinity` icon.

## [0.40.2] - 2022-08-22

Fixes issue where using the back button resulted in the URL changing but the page not being updated. This was caused by manually manipulating the history object (history.pushState), because this interferes with how Turbo manages the restoration visits.

- removed `submitForm` function. Recommended approach is to call `form.requestSubmit()`

## [0.40.1] - 2022-08-18

Add `GanttChart::TaskActions::Component` displaying a menu with options for each task:

- Opening details
- Indent
- Outdent
- Delete

Refactor `HoverCard::Component` to use tippy to simplify and handle more options.

## [0.40.0] - 2022-08-18

Create `GanttChart::Component` for a full fledged Gantt Chart with the following functionality:

- Display a sortable and nestable list of tasks
- Fold/Unfold the nested lists
- Actions for changing the timescale between Day, Week and Month
- Button for focusing today's date and a today marker
- Draggable and Resizable tasks
- Visualize dependencies between tasks
- Display of milestones
- Resizable width of the task list
- Visualize weekends

## [0.39.1] - 2022-08-16

- Fix `Navbar` transparency.

## [0.39.0] - 2022-08-15

- Added `Clipboard` component. Copy text to clipboard.
- Added `copy`, `link-alt` icons.

## [0.38.1] - 2022-08-15

- Clean up event listeners from all StimulusJS controllers
- Override `SlimSelect#destroy` function to check for the presence of slim elements before removing them.

## [0.38.0] - 2022-08-14

- Convert `HelpTip` to a more general `Tooltip`. To create a HelpTip out of a Tooltip simply set a `<span>?</span>` as a trigger and add the class `help-tip` to the root component.

## [0.37.1] - 2022-08-12

- Update `ModalController` to check for targets (Wrapper and Background) existence before attempting action.

## [0.37.0] - 2022-08-5

- `radio-buttons-group-controller` was created.
- Update `ModalController` to look for `data-turbo` attribute in the form if it was not present in the `event.target`.

## [0.36.0] - 2022-08-4

- Update `radio-toggle-controller` to accept multiple values in current value.

## [0.35.1] - 2022-08-3

- Remove `stroke` attribute from `rect` and add `stroke` and `fill` in `svg` icons.

## [0.35.0] - 2022-08-3

- Add `under-modal` class to hide the hover-card when is necessary.

## [0.34.0] - 2022-08-3

- Add `open_on_click` property to `HoverCard::Component` to open the content on click.

## [0.33.0] - 2022-07-29

- Add `show_border` to `Reveal::Component` to show or hide the `border-bottom` just below the trigger.

## [0.32.2] - 2022-07-28

- Add `new` to CRUD actions to display an active tab when current_path is matched.

## [0.32.1] - 2022-07-28

- Remove `stimulus-chartjs` dependency.

## [0.32.0] - 2022-07-25

- Add `Timeago::Component`.

## [0.31.0] - 2022-07-25

- Add `Heatmap::Component`.

## [0.30.6] - 2022-07-18

- Add `crud` match type to `SideMenu::Item`. So it only considers items as active when current_path is one of the CRUD actions (index, show, edit.)

## [0.30.5] - 2022-07-18

- Add `starts_with` match type to `SideMenu::Item`. So it only considers items as active when current_path starts with the item's HREF

## [0.30.4] - 2022-07-18

- Only consider exact URL matches for displaying a `SideMenu::Item` as active. This fixes a problem where 2 items had a similar URL and both were considered active.

## [0.30.3] - 2022-07-14

- `step-number-input` controller was updated to be able to set a custom step.

## [0.30.2] - 2022-07-14

- Updated `PageHeader::Component` CSS to prevent overflow.

## [0.30.1] - 2022-07-12

- Updated `PageHeader::Component`, title and subtitle slots now receive an optional tag param to specify the size of the heading. New default title size is `h3` and subtitle is `h5`.

## [0.30.0] - 2022-07-11

- Create `Tags::Component` to display tags groups.
- Create `Tag::Component` to display individual tags.

## [0.29.0] - 2022-07-08

- Create `Rate::Component` to give feedback on something.

## [0.28.1] - 2022-07-08

- Allowed `InfoLevel::Component` to receive a block on its heading and title.

## [0.28.0] - 2022-07-08

- Create `Timeline::Component` to display contents in a vertical timeline

## [0.27.1] - 2022-07-07

- Update README with component updates
- Add `ImageGrid::Component` tests
- Add `Column::Component` previews
- Standardize on expect(page) syntax instead of using subject + is_expected

## [0.27.0] - 2022-07-07

- Added the `TrixAttachmentsController` for handling attachments in the `Trix` editor.

## [0.26.1] - 2022-07-07

- Fixed an issue when using icons in the content of `Reveal::Component`

## [0.26.0] - 2022-07-07

- Create `Reveal::Component` to display hidden content that can be revealed.

## [0.25.2] - 2022-07-06

- Upgrade dependencies.

## [0.25.1] - 2022-07-06

- Export `domHelpers`.

## [0.25.0] - 2022-07-05

- Add `Avatar::Component`. With this component we'll be able to see a preview of the image we want as an avatar.

## [0.24.4] - 2022-07-05

- Let `DeleteLink::Component` receive form classes for the `buttton_to` tag.

## [0.24.3] - 2022-07-05

- Add `type="button"` to Carousel controls (`arrows`, `bullets`).

## [0.24.2] - 2022-07-05

- Wrap card image slot in `slot` instead of `div`.

## [0.24.1] - 2022-07-05

- Set SideMenu list with optional title

## [0.24.0] - 2022-07-05

- `arrows` and `bullets` slots were added to `Carousel` component.

## [0.23.4] - 2022-07-05

- Fix SideMenu parent item when sub item is selected

## [0.23.3] - 2022-07-04

- Fix SideMenu sub items show only when active

## [0.23.2] - 2022-07-04

- Set `Delete` as default name for `DeleteLink::Component`

## [0.23.1] - 2022-07-04

- Add `Tabs::Trigger::Component`. In addition, a tab will cause the entire page to be reloaded when `href` is present.

## [0.23.0] - 2022-07-01

- Add `toInt` and `toFloat` JS formatters

## [0.22.0] - 2022-07-01

- Create `Carousel::Component`.

## [0.21.0] - 2022-07-01

- Create `SortableList::Component` to sort items in a list.

## [0.20.1] - 2022-07-01

- Display `SideMenu::Component` child items when item is active.

## [0.20.0] - 2022-07-01

- Create `Breadcrumb::Component` to improve the navigation experience

## [0.19.1] - 2022-07-01

- Custom notifications have been added for `no results/no records` in the table component.

## [0.19.0] - 2022-07-01

- Create `Stepper::Component` to display steps completed in a process

## [0.18.0] - 2022-06-30

- Added a `FormHelper` to add the `submit-button-controller` to the `form_for` method.

## [0.17.1] - 2022-06-30

- Update `hyphenize_keys` to return a hash in which the keys are symbols instead of strings.

## [0.17.0] - 2022-06-30

- Create `BooleanIcon::Component` and update Component Generator templates.

## [0.16.0] - 2022-06-30

- Added non-component stylesheets (`box`, `code`, `container`, `flatpickr_customizations`, `forms`, `general`, `panel`, `slim_select_customizations`, `switch`, `typography`, `variables`). In addition missing Hover Card styles (Frontend helpers) have been added to the Hover card.

## [0.15.3] - 2022-06-30

-Reorganize specs to have all tests within a bali/ folder.

## [0.15.2] - 2022-06-30

- Improve `FormBuilder` testing.

## [0.15.1] - 2022-06-29

- Pass the `options` parameter to the `SideMenu::Item::Component`.

## [0.15.0] - 2022-06-28

- Added `FormBuilder` and `FieldGroupWrapperComponent`.

## [0.14.0] - 2022-06-28

- Added `SideMenu::Component`.

## [0.13.0] - 2022-06-28

- Added Stimulus JS Controllers
  [`auto-play-audio`, `autocomplete-address`, `checkbox-toggle`, `elements-overlap`,
  `focus-on-connect`, `input-on-change`, `print`, `radio-toggle`, `submit-button`].

## [0.12.0] - 2022-06-24

- Added utils methods.

## [0.11.0] - 2022-06-23

- Added `wide` css class to `Dropdown::Component`.

## [0.10.0] - 2022-06-23

- Added conditional layout concern.

## [0.9.0] - 2022-06-22

- Added Time Value class and its corresponding tests.

## [0.8.1] - 2022-06-22

- Remove double validation in `Link::Component`.

## [0.8.0] - 2022-06-21

- Fix style in `Link::Component`.

## [0.7.0] - 2022-06-21

- Added FilterForm class and its corresponding tests.

## [0.6.0] - 2022-06-21

- Added Notification Component.

## [0.5.0] - 2022-06-17

- Completed `Loader` component.

## [0.3.0] - 2022-06-16

- Completed `Tabs` component. Added loading tab content on demand.

## [0.2.0] - 2022-06-15

- Completed `Link` and `Calendar` components.

## [0.1.0] - 2022-06-10

- `Navbar` component was added.
