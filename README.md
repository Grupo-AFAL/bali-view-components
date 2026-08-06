# Bali ViewComponents

A collection of 75+ UI components built with [ViewComponent](https://viewcomponent.org/) for Rails applications. Styled with [Tailwind CSS](https://tailwindcss.com/) and [DaisyUI](https://daisyui.com/), powered by [Stimulus](https://stimulus.hotwired.dev/) controllers.

## Features

- **75+ Production-Ready Components** - Buttons, cards, modals, forms, tables, navigation, and more
- **DaisyUI Styling** - Beautiful, consistent styling with theme support (light/dark)
- **Stimulus Controllers** - Interactive behaviors without writing JavaScript
- **FormBuilder Extensions** - Enhanced form helpers with validation and addons
- **Accessible by Default** - WCAG 2.1 AA compliant components
- **Lookbook Integration** - Interactive component documentation and previews

## Quick Start

### 1. Install the Gem

Bali is not published to RubyGems — it is consumed straight from this repository. Add to your
`Gemfile`, pinning a tag:

```ruby
# Bundler resolves git sources before rubygems ones, so these two must be declared FIRST
gem "lucide-rails"
gem "view_component-contrib"

gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v2.18.0"
```

Then run:

```bash
bundle install
```

**Pin a tag, don't track a branch.** With `branch: "main"` a `bundle update` silently pulls
whatever landed since — including, eventually, the next major and all of its breaking changes.
See [Release channels](docs/guides/release-channels.md) for the v2 / v3 lines and how to adopt
a v3 pre-release.

### 2. Install JavaScript Dependencies

Add to your `package.json`:

```bash
npm install bali-view-components
# or
yarn add bali-view-components
```

### 3. Configure Tailwind CSS v4 + DaisyUI

In your CSS entry point (e.g., `app/assets/tailwind/application.css`):

```css
@import "tailwindcss";
@plugin "daisyui";

/* Scan Bali ViewComponents for Tailwind classes */
@source "../../../node_modules/bali-view-components/app/**/*.{rb,erb}";

/* Import Bali CSS — one line, component sheets included */
@import "bali-view-components/css/bali.css";

/* Dark mode support */
@custom-variant dark (&:where([data-theme=dark], [data-theme=dark] *));

:root {
  color-scheme: light;
}

[data-theme="dark"] {
  color-scheme: dark;
}
```

> **Important**: The `@source` directive is required because Bali components define Tailwind classes in Ruby files. Without it, Tailwind won't detect these classes and they won't be included in your CSS build.

### 4. Use Components

```erb
<%# Basic button %>
<%= render Bali::Button::Component.new(name: 'Save', variant: :primary) %>

<%# Card with slots %>
<%= render Bali::Card::Component.new do |c| %>
  <% c.with_header { "Card Title" } %>
  <% c.with_body { "Card content goes here" } %>
  <% c.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Action', variant: :ghost) %>
  <% end %>
<% end %>

<%# Link styled as button %>
<%= render Bali::Link::Component.new(name: 'View Details', href: '/items/1', type: :primary) %>
```

## Documentation

| Guide | Description |
|-------|-------------|
| [Installation](docs/guides/installation.md) | Complete setup including Tailwind v4 |
| [Components](docs/guides/components.md) | Component usage patterns and slots |
| [Enum badges](docs/guides/enum-badges.md) | `Bali::Tag.for` / `Bali::Status.for` — one map per enum, and the Tag vs Status criterion |
| [FormBuilder](docs/guides/form-builder.md) | Enhanced form helpers |
| [Accessibility](docs/guides/accessibility.md) | WCAG 2.1 compliance |
| [Overlays and the top layer](docs/guides/overlays-and-the-top-layer.md) | What the z-index scale orders, and what it cannot |
| [Engines](docs/guides/engines.md) | Host integration for Bali's controllers (`Bali.engine_controller_concerns`) |
| [Migrating v2 → v3](docs/guides/migration-v2-to-v3.md) | Breaking changes to the index page (DataTable) |
| [Troubleshooting](docs/guides/troubleshooting.md) | Common issues and solutions |

## Component Categories

### Layout
`AppLayout`, `Card`, `Columns`, `Drawer`, `Footer`, `Hero`, `Level`, `Modal`, `PageHeader`, `Topbar`

### Navigation
`Breadcrumb`, `Command`, `Dropdown`, `Navbar`, `Pagination`, `PaginationFooter`, `SideMenu`, `Stepper`, `Tabs`, `ViewSwitch`

### Data Display
`Avatar`, `BooleanIcon`, `Chart`, `DataTable`, `Heatmap`, `Icon`, `ImageGrid`, `InfoLevel`, `LabelValue`, `List`, `LocationsMap`, `Progress`, `PropertiesTable`, `Rate`, `Skeleton`, `StatCard`, `Table`, `Tag`, `Tags`, `Timeago`, `Timeline`, `TreeView`

### Interactive
`ActionsDropdown`, `BulkActions`, `Button`, `Carousel`, `Clipboard`, `ConfirmDialog`, `DeleteLink`, `Filters`, `HoverCard`, `Kanban`, `Link`, `Reveal`, `SortableList`, `Tooltip`

### Feedback
`FeedbackWidget`, `FlashNotifications`, `Loader`, `Message`, `Notification`

### Forms
`Calendar`, `DirectUpload`, `ImageField`, `RecurrentEventRuleForm`, `RichTextEditor`, plus 25+ FormBuilder extensions

### Documents & Editors
`BlockEditor`, `DocumentEditor`, `DocumentPage`

### Page Templates
`DashboardPage`, `IndexPage`, `ShowPage`, `FormPage`

## FormBuilder Extensions

Bali extends Rails' `FormBuilder` with DaisyUI-styled inputs:

```erb
<%= form_with model: @user, builder: Bali::FormBuilder do |f| %>
  <%= f.text_field_group :name %>
  <%= f.email_field_group :email %>
  <%= f.slim_select_group :role, User.roles.keys.map { |r| [r.humanize, r] } %>
  <%= f.switch_field :active, color: :primary %>
  <%= f.date_field_group :birth_date %>
  <%= f.rich_text_area_group :bio %>
  <%= f.submit_button 'Save', variant: :primary %>
<% end %>
```

## Development

### Running the Preview Server

```bash
cd spec/dummy && bin/dev
```

Open [http://localhost:3001/lookbook](http://localhost:3001/lookbook) to browse component previews.

### Running Tests

```bash
# RSpec tests
bundle exec rspec

# Cypress tests (requires server running on port 3001)
yarn run cy:run   # Headless
yarn run cy:open  # Interactive
```

### Creating New Components

```bash
rails g view_component bali/my_component name
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`bundle exec rspec`)
5. Create Lookbook preview for new components
6. Submit a pull request

### Code Style

- Run `bundle exec rubocop -a` before committing
- Follow patterns in [Component Patterns](docs/reference/component-patterns.md)
- Use DaisyUI classes (not Bulma)

## JavaScript Debugging

Some Stimulus controllers emit events for inter-controller communication. Every one of them is
named `bali:<component>:<event>`, so a single console snippet logs the lot:

```javascript
// Paste in the browser console, then drive the UI
const dispatchEvent = EventTarget.prototype.dispatchEvent
EventTarget.prototype.dispatchEvent = function (event) {
  if (event.type.startsWith('bali:')) console.log(event.type, event.detail)
  return dispatchEvent.call(this, event)
}
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

## Component Status

| Component | Preview | Docs | Tests |
|-----------|:-------:|:----:|:-----:|
| ActionsDropdown | ✓ | ✓ | ✓ |
| AppLayout | ✓ | ✓ | ✓ |
| Avatar | ✓ | ✓ | ✓ |
| BlockEditor | ✓ | ✓ | ✓ |
| BooleanIcon | ✓ | ✓ | ✓ |
| Breadcrumb | ✓ | ✓ | ✓ |
| BulkActions | ✓ | - | ✓ |
| Button | ✓ | ✓ | ✓ |
| Calendar | ✓ | ✓ | ✓ |
| Card | ✓ | ✓ | ✓ |
| Carousel | ✓ | ✓ | ✓ |
| Chart | ✓ | ~ | ✓ |
| Clipboard | ✓ | ✓ | ✓ |
| Columns | ✓ | ✓ | ✓ |
| Command | ✓ | ✓ | ✓ |
| ConfirmDialog | ✓ | - | - |
| DashboardPage | ✓ | - | ✓ |
| DataTable | ✓ | ✓ | ✓ |
| DeleteLink | ✓ | ✓ | ✓ |
| DirectUpload | ✓ | ✓ | - |
| DocumentEditor | ✓ | - | ✓ |
| DocumentPage | ✓ | - | ✓ |
| Drawer | ✓ | ✓ | ✓ |
| Dropdown | ✓ | ✓ | ✓ |
| FeedbackWidget | ✓ | - | ✓ |
| Filters | ✓ | ✓ | ✓ |
| FlashNotifications | ✓ | - | ✓ |
| Footer | ✓ | - | ✓ |
| FormPage | ✓ | - | ✓ |
| Heatmap | ✓ | ✓ | ✓ |
| Hero | ✓ | ✓ | ✓ |
| HoverCard | ✓ | ✓ | ✓ |
| Icon | ✓ | ✓ | ✓ |
| ImageField | ✓ | - | ✓ |
| ImageGrid | ✓ | ✓ | ✓ |
| IndexPage | ✓ | - | ✓ |
| InfoLevel | ✓ | ✓ | ✓ |
| Kanban | ✓ | - | ✓ |
| LabelValue | ✓ | ✓ | ✓ |
| Level | ✓ | ✓ | ✓ |
| Link | ✓ | ✓ | ✓ |
| List | ✓ | ✓ | ✓ |
| Loader | ✓ | ✓ | ✓ |
| LocationsMap | ✓ | ✓ | ✓ |
| Message | ✓ | - | ✓ |
| Modal | ✓ | ✓ | ✓ |
| NavBar | ✓ | ✓ | ✓ |
| Notification | ✓ | ✓ | ✓ |
| PageHeader | ✓ | ~ | ✓ |
| Pagination | ✓ | - | ✓ |
| PaginationFooter | ✓ | - | ✓ |
| Progress | ✓ | ✓ | ✓ |
| PropertiesTable | ✓ | ✓ | ✓ |
| Rate | ✓ | ✓ | ✓ |
| RecurrentEventRuleForm | ✓ | - | ✓ |
| Reveal | ✓ | ✓ | ✓ |
| RichTextEditor | ✓ | - | - |
| ShowPage | ✓ | - | ✓ |
| SideMenu | ✓ | ✓ | ✓ |
| Skeleton | ✓ | - | ✓ |
| SortableList | ✓ | ✓ | ✓ |
| StatCard | ✓ | - | - |
| Stepper | ✓ | ✓ | ✓ |
| Table | ✓ | ✓ | ✓ |
| Tabs | ✓ | ✓ | ✓ |
| Tag | ✓ | - | ✓ |
| Tags | ✓ | - | ✓ |
| ThemeSampler | ✓ | - | - |
| Timeago | ✓ | ✓ | ✓ |
| Timeline | ✓ | ✓ | ✓ |
| Tooltip | ✓ | ✓ | ✓ |
| Topbar | ✓ | ✓ | ✓ |
| TreeView | ✓ | ✓ | ✓ |
| ViewSwitch | ✓ | ✓ | ✓ |

**Legend:** ✓ Complete | ~ Partial | - Missing

## Stimulus Controllers

| Controller | Description |
|------------|-------------|
| Filters | Filtering UI with Ransack integration |
| AutoPlay | Auto-play audio on page load |
| AutocompleteAddress | Google Places API autocomplete |
| CheckboxToggle | Toggle element visibility with checkbox |
| Datepicker | Flatpickr date picker integration |
| DynamicFields | Dynamic form field rendering |
| FileInput | File input display handling |
| FocusOnConnect | Auto-focus/scroll on connect |
| InputOnChange | Server notification on input change |
| Modal | Modal dialog control |
| Print | Print current page |
| RadioToggle | Toggle visibility based on radio selection |
| SlimSelect | Slim Select dropdown integration |
| StepNumberInput | Increment/decrement number input |
| SubmitButton | Loading state on form submission |
| SubmitOnChange | Auto-submit form on value change |
| TrixAttachments | Trix editor file attachments |
