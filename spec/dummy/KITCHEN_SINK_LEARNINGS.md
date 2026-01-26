# Kitchen Sink Demo: Learnings & Issues Log

This document tracks issues, friction points, and learnings discovered while building the kitchen sink demo. Use this to identify improvements needed in Bali components.

---

## Format

Each entry should include:
- **Component(s)**: Which component(s) were involved
- **Issue/Learning**: What happened
- **Impact**: How it affected development (blocker, friction, confusion)
- **Suggestion**: Potential improvement to the component or docs

---

## Issues & Learnings

### Phase 1: Infrastructure

_No issues encountered - component APIs worked as expected._

---

### Phase 2: Dashboard

#### Learning 1: Timeago Component Signature
- **Component(s)**: `Bali::Timeago::Component`
- **Issue/Learning**: Timeago takes a positional argument for datetime, not a keyword argument. Used `Bali::Timeago::Component.new(datetime: movie.created_at)` but should be `Bali::Timeago::Component.new(movie.created_at, add_suffix: true)`.
- **Impact**: Minor friction - had to check component source to understand API
- **Suggestion**: Consider documenting the positional argument clearly, or consider making it a keyword argument for consistency with other components

#### Learning 2: No Groupdate Gem
- **Component(s)**: Chart (indirectly)
- **Issue/Learning**: Assumed `group_by_month` would be available for time-series charts, but Groupdate gem is not included in the dummy app.
- **Impact**: Had to change dashboard design to use simpler groupings
- **Suggestion**: Consider adding Groupdate to dummy app for more realistic chart demos, or document time-series chart examples without Groupdate

---

### Phase 3: Movie Detail Page

_No major issues - Tabs, PropertiesTable, Timeline, and Rate components worked well._

---

### Phase 4: Movie Form

#### Learning 3: FormBuilder API Variety
- **Component(s)**: `Bali::FormBuilder`
- **Issue/Learning**: The FormBuilder has a rich set of field helpers (`text_field_group`, `select_group`, `switch_field_group`, `radio_field_group`, `text_area_group`, `date_field_group`, `currency_field_group`, `email_field_group`, `url_field_group`, `time_zone_select_group`, `number_field_group`).
- **Impact**: Positive - comprehensive coverage
- **Suggestion**: A quick reference guide listing all available field helpers with examples would be valuable

#### Learning 4: Radio Field Orientation
- **Component(s)**: `radio_field_group`
- **Issue/Learning**: Radio fields support `orientation: :horizontal` or `:vertical` via html_options (4th argument), not via the options hash.
- **Impact**: Minor confusion about which argument hash to use
- **Suggestion**: Consider documenting the parameter order clearly: `method, values, options, html_options`

---

### Phase 5: Settings Page

#### Learning 5: SideMenu In-Page Navigation
- **Component(s)**: `Bali::SideMenu`
- **Issue/Learning**: SideMenu works well for in-page anchor navigation (e.g., `#general`, `#notifications`), not just full page navigation.
- **Impact**: Positive - component is flexible
- **Suggestion**: Add a Lookbook preview showing in-page anchor usage

---

### Phase 6: Marketing Landing

#### Learning 6: Hero Color Contrast
- **Component(s)**: `Bali::Hero`
- **Issue/Learning**: When using `color: :primary`, the Link/Button variants need to use `:secondary` or `:ghost` for proper contrast since the hero background is already primary.
- **Impact**: Minor - had to think about color combinations
- **Suggestion**: Document recommended button variants for each hero color

#### Learning 7: Carousel Bullet/Arrow Slots
- **Component(s)**: `Bali::Carousel`
- **Issue/Learning**: `with_bullets` and `with_arrows` are available but render arrows/bullets outside the main content area. Carousel requires items to render.
- **Impact**: Positive - clean API
- **Suggestion**: None - works as expected

---

### Phase 7: Polish & Movies List

#### Learning 8: DataTable Slot Composition
- **Component(s)**: `Bali::DataTable`
- **Issue/Learning**: DataTable has rich slot composition: `with_filters_panel`, `with_table`, `with_actions_panel`, `with_toolbar_buttons`, etc.
- **Impact**: Positive - highly customizable
- **Suggestion**: The DataTable is powerful but complex - a dedicated usage guide would help

#### Learning 9: Consistent Component Composition
- **Component(s)**: All
- **Issue/Learning**: Using Bali components consistently (Link, Tag, BooleanIcon, ActionsDropdown) inside table cells provides better consistency than raw HTML badges.
- **Impact**: Positive - demonstrates proper composition patterns
- **Suggestion**: The CLAUDE.md already emphasizes this - it's working well

---

### Phase 8: Testing & Verification (Post-Implementation)

#### Learning 10: Rate Component Scale Expects Range
- **Component(s)**: `Bali::Rate::Component`
- **Issue/Learning**: The `scale` parameter expects a `Range` (e.g., `1..5`), not an `Integer` (e.g., `5`). Using `scale: 5` causes `undefined method 'each' for an instance of Integer`.
- **Impact**: Blocker - caused 500 error on movie detail page
- **Suggestion**: Add type validation with a clear error message, or accept both Integer and Range

#### Learning 11: Table Component bulk_actions Removed
- **Component(s)**: `Bali::Table::Component`
- **Issue/Learning**: Passed `bulk_actions: true` expecting to enable bulk action checkboxes, but the Table component doesn't have this parameter anymore. The DataTable handles bulk actions separately via `with_actions_panel` slot.
- **Impact**: Blocker - caused 500 error (`undefined method 'any?' for true`)
- **Suggestion**: Document that bulk actions are now handled at the DataTable level, not Table

#### Learning 12: FormBuilder Requires ActiveModel-Compatible Object
- **Component(s)**: `Bali::FormBuilder`
- **Issue/Learning**: FormBuilder requires a model object bound via `form_with model:`. For settings pages without database models, create a form object class with `ActiveModel::Model`:
  ```ruby
  # app/models/settings_form.rb
  class SettingsForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :dark_mode, :boolean, default: false
    attribute :language, :string, default: 'en'
    # ... more attributes

    def model_name
      ActiveModel::Name.new(self.class, nil, 'Settings')
    end
  end
  ```
- **Impact**: Blocker - caused 500 error (`undefined method 'model_name' for nil`)
- **Suggestion**: Document this pattern for non-ActiveRecord forms. The `ActiveModel::Model` + `ActiveModel::Attributes` pattern is cleaner than OpenStruct hacks

### Phase 9: Additional Component Coverage

#### Learning 13: InfoLevel Slot Pattern
- **Component(s)**: `Bali::InfoLevel::Component`
- **Issue/Learning**: InfoLevel uses a nested slot pattern: `with_item` yields an item object, then you call `with_heading('label')` and `with_title('value')` on it. Not `with_item(label:, value:)`.
- **Impact**: Minor - requires understanding the nested slot pattern
- **Suggestion**: Document the block-with-yielded-object pattern clearly

#### Learning 14: SortableList Requires Handle for Complex Items
- **Component(s)**: `Bali::SortableList::Component`
- **Issue/Learning**: When items have interactive elements (buttons, dropdowns), use a `handle` option to restrict drag-and-drop to a specific element (e.g., `.handle` class). Without this, clicking any part of the item initiates drag.
- **Impact**: Medium - required understanding handle pattern
- **Suggestion**: Default preview should show handle usage

#### Learning 15: HoverCard Trigger Pattern
- **Component(s)**: `Bali::HoverCard::Component`
- **Issue/Learning**: HoverCard content goes in the main block, trigger goes in `with_trigger` slot. The trigger should be interactive (button, link, or styled span).
- **Impact**: Minor - straightforward once understood
- **Suggestion**: Document the trigger/content split clearly

#### Learning 16: DirectUpload Requires Active Storage
- **Component(s)**: `Bali::DirectUpload::Component`
- **Issue/Learning**: DirectUpload requires Active Storage to be set up with `has_one_attached` or `has_many_attached` on the model. The component handles the upload UI and progress.
- **Impact**: Medium - requires model changes
- **Suggestion**: Document the prerequisites clearly

---

## Summary: Components Used in Kitchen Sink

| Page | Components Used |
|------|----------------|
| **Dashboard** | Navbar, PageHeader, Card, Icon, Chart, Timeline, Notification, Tag, Button, Level, Link, Avatar, Dropdown, Timeago, InfoLevel, GanttChart, Heatmap, BulkActions |
| **Movies List** | Breadcrumb, PageHeader, DataTable, AdvancedFilters, Table, Tag, BooleanIcon, ActionsDropdown, Link, Message, Timeago |
| **Movie Detail** | Breadcrumb, PageHeader, Tabs, Card, PropertiesTable, Avatar, Progress, Rate, SortableList, Timeline, Tag, BooleanIcon, Timeago, DeleteLink, ActionsDropdown, Message, Link, HoverCard, ImageGrid, LabelValue |
| **Movie Form** | Breadcrumb, PageHeader, Stepper, Card, FormBuilder (10+ field types), Button, Link, Message, Icon, DirectUpload |
| **Settings** | Breadcrumb, PageHeader, SideMenu, Card, FormBuilder, Message, Button, Icon, Reveal |
| **Landing** | Navbar, Hero, Card, Icon, Carousel, Avatar, Button, Link, Tag |

**Total unique components demonstrated: 45+**

