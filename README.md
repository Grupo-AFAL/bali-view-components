# Bali ViewComponents

A collection of 48+ UI components built with [ViewComponent](https://viewcomponent.org/) for Rails applications. Styled with [Tailwind CSS](https://tailwindcss.com/) and [DaisyUI](https://daisyui.com/), powered by [Stimulus](https://stimulus.hotwired.dev/) controllers.

## Features

- **48+ Production-Ready Components** - Buttons, cards, modals, forms, tables, navigation, and more
- **DaisyUI Styling** - Beautiful, consistent styling with theme support (light/dark)
- **Stimulus Controllers** - Interactive behaviors without writing JavaScript
- **FormBuilder Extensions** - Enhanced form helpers with validation and addons
- **Accessible by Default** - WCAG 2.1 AA compliant components
- **Lookbook Integration** - Interactive component documentation and previews

## Quick Start

### 1. Install the Gem

Add to your `Gemfile`:

```ruby
gem "bali_view_components"
```

Then run:

```bash
bundle install
```

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

/* Import Bali CSS */
@import "bali-view-components/css/bali.css";
@import "bali-view-components/css/components.css";

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
| [FormBuilder](docs/guides/form-builder.md) | Enhanced form helpers |
| [Accessibility](docs/guides/accessibility.md) | WCAG 2.1 compliance |
| [Troubleshooting](docs/guides/troubleshooting.md) | Common issues and solutions |

## Component Categories

### Layout
`Card`, `Columns`, `Drawer`, `Hero`, `Level`, `Modal`, `PageHeader`

### Navigation
`Breadcrumb`, `Dropdown`, `NavBar`, `SideMenu`, `Tabs`, `Stepper`

### Data Display
`Avatar`, `DataTable`, `Icon`, `List`, `Progress`, `Table`, `Tag`, `Timeline`, `TreeView`

### Interactive
`ActionsDropdown`, `AdvancedFilters`, `Button`, `Carousel`, `Clipboard`, `DeleteLink`, `HoverCard`, `Link`, `Reveal`, `SearchInput`, `SortableList`, `Tooltip`

### Feedback
`FlashNotifications`, `Loader`, `Message`, `Notification`

### Forms
`Calendar`, `ImageField`, `RichTextEditor`, plus 25+ FormBuilder extensions

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

Some Stimulus controllers emit events for inter-controller communication. Enable debug logging:

```javascript
baliDispatchDebugEnabled = true
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

## Component Status

| Component | Preview | Docs | Tests |
|-----------|:-------:|:----:|:-----:|
| ActionsDropdown | ✓ | ✓ | ✓ |
| AdvancedFilters | ✓ | ✓ | ✓ |
| Avatar | ✓ | ✓ | ✓ |
| Breadcrumb | ✓ | ✓ | ✓ |
| BooleanIcon | ✓ | ✓ | ✓ |
| Button | ✓ | ✓ | ✓ |
| Calendar | ✓ | ✓ | ✓ |
| Card | ✓ | ✓ | ✓ |
| Carousel | ✓ | ✓ | ✓ |
| Chart | ✓ | ~ | ✓ |
| Clipboard | ✓ | ✓ | ✓ |
| Columns | ✓ | ✓ | ✓ |
| DataTable | ✓ | ✓ | ✓ |
| DeleteLink | ✓ | ✓ | ✓ |
| Drawer | ✓ | ✓ | ✓ |
| Dropdown | ✓ | ✓ | ✓ |
| Filters | ✓ | ✓ | ✓ |
| GanttChart | ✓ | ✓ | - |
| Heatmap | ✓ | ✓ | ✓ |
| Hero | ✓ | ✓ | ✓ |
| HoverCard | ✓ | ✓ | ✓ |
| Icon | ✓ | ✓ | ✓ |
| ImageGrid | ✓ | ✓ | ✓ |
| InfoLevel | ✓ | ✓ | ✓ |
| LabelValue | ✓ | ✓ | ✓ |
| Level | ✓ | ✓ | ✓ |
| Link | ✓ | ✓ | ✓ |
| List | ✓ | ✓ | ✓ |
| Loader | ✓ | ✓ | ✓ |
| Modal | ✓ | ✓ | ✓ |
| NavBar | ✓ | ✓ | ✓ |
| Notification | ✓ | ✓ | ✓ |
| PageHeader | ✓ | ~ | ✓ |
| Progress | ✓ | ✓ | ✓ |
| PropertiesTable | ✓ | ✓ | ✓ |
| Rate | ✓ | ✓ | ✓ |
| Reveal | ✓ | ✓ | ✓ |
| RichTextEditor | ✓ | - | - |
| SearchInput | ✓ | ✓ | ✓ |
| SideMenu | ✓ | ✓ | ✓ |
| SortableList | ✓ | ✓ | ✓ |
| Stepper | ✓ | ✓ | ✓ |
| Table | ✓ | ✓ | ✓ |
| Tabs | ✓ | ✓ | ✓ |
| Timeago | ✓ | ✓ | ✓ |
| Timeline | ✓ | ✓ | ✓ |
| Tooltip | ✓ | ✓ | ✓ |
| TreeView | ✓ | ✓ | ✓ |

**Legend:** ✓ Complete | ~ Partial | - Missing

## Stimulus Controllers

| Controller | Description |
|------------|-------------|
| AdvancedFilters | Advanced filtering UI with Ransack integration |
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
