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

gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v3.4.0"
```

Then run:

```bash
bundle install
```

Nothing else goes in the `Gemfile`: `csv`, `simple_command` and the rest are the gemspec's
problem, so lines you wrote by hand under "Required by Bali" can go (`rrule` too, unless your
own code builds recurrence rules, and `pagy` unless you paginate — Bali renders a Pagy you
pass in, it never builds one).

**Pin a tag, don't track a branch.** With `branch: "main"` a `bundle update` silently pulls
whatever landed since — including, eventually, the next major and all of its breaking changes.
See [Release channels](docs/guides/release-channels.md) for the v2 / v3 lines and how to adopt
a v3 pre-release.

### 2. Run the installer

```bash
bin/rails g bali:install
```

It writes the wiring the whole fleet shares and then prints what it deliberately left to you
(daisyUI themes, dark mode, the AFAL theme, localised confirm buttons):

| It writes | Where |
|---|---|
| `@plugin "daisyui"` and Bali's two `@import`s, in the order Tailwind needs | your Tailwind entry point — `app/assets/tailwind/application.css` under tailwindcss-rails, `app/assets/stylesheets/application.tailwind.css` under cssbundling-rails |
| `default_form_builder = "Bali::FormBuilder"`, with the reason it goes through `config.action_view` | `config/initializers/bali.rb` |
| `registerAll(application)` + `registerCharts(application)` and their imports | `app/javascript/controllers/index.js` |
| every required peer dependency | `package.json` |

Then `yarn install` and the Tailwind build it names. Running it again writes nothing twice —
on an app it wired, and on one wired by hand — so it is also what to run after an upgrade; the
one thing it never touches is your `bali-view-components` pin, which it reports instead when it
has fallen behind the gem. `--block-editor` turns the Block Editor on (it ships off) and adds
the `@blocknote/*` packages.

**It writes only what this app can resolve, and says the rest.** An importmap app keeps its
Stimulus index untouched — a bare specifier there does not degrade, it fails the module and
takes the app's own controllers with it — and an app with no `package.json` gets only the one
CSS line that needs no npm. An app where nothing compiles Tailwind (no tailwindcss-rails, no
`build:css` script) gets no entry point written at all: the file would be the input to a build
that does not exist. Full detail:
[Installation § Step 0](docs/guides/installation.md).

### 3. What the installer writes into your CSS

In your CSS entry point (e.g., `app/assets/tailwind/application.css`):

```css
@import "tailwindcss";
@plugin "daisyui";

/* Bali's Tailwind sources. tailwindcss-rails (>= 4.3) writes this file from
   the gem's own engine.css before every build, pointing at wherever Bundler
   installed the gem on this machine. */
@import "../builds/tailwind/bali";

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

> **Important**: Bali defines Tailwind classes in Ruby, ERB and JS files under `app/`, and the FormBuilder defines its own — `input-error`, `select-error`, `fieldset-label`, the whole `range-*` family — under `lib/bali/`. The gem's `app/assets/tailwind/bali/engine.css` carries the `@source` globs for both, and the import above is all a host writes. Never point a `@source` at the gem directory yourself: the path differs per machine, and a glob that matches nothing fails silently. Without tailwindcss-rails, import the same file from the npm package — `@import "bali-view-components/tailwind/engine.css";`. Details in [Installation § Step 3](docs/guides/installation.md#step-3-configure-tailwind-css-v4--daisyui).

### 4. Use Components

```erb
<%# Basic button %>
<%= render Bali::Button::Component.new(name: 'Save', variant: :primary) %>

<%# Card with slots %>
<%= render Bali::Card::Component.new do |c| %>
  <% c.with_header(title: 'Card Title') %>
  <%= tag.p 'Card content goes here' %>
  <% c.with_action(class: 'btn-ghost') { 'Action' } %>
<% end %>

<%# Link styled as button %>
<%= render Bali::Link::Component.new(name: 'View Details', href: '/items/1', variant: :primary) %>
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
| [Engine models](docs/guides/engine-models.md) | The tables Bali ships and how a model opts in (saved views, acknowledgments) |
| [Migrating v2 → v3](docs/guides/migration-v2-to-v3.md) | Breaking changes to the index page (DataTable) |
| [Troubleshooting](docs/guides/troubleshooting.md) | Common issues and solutions |

## Component Categories

### Layout
`AppLayout`, `Card`, `Columns`, `Drawer`, `Footer`, `Hero`, `Level`, `Modal`, `PageHeader`, `Topbar`

### Navigation
`Breadcrumb`, `Command`, `Dropdown`, `Navbar`, `Pagination`, `PaginationFooter`, `SideMenu`, `Stepper`, `Tabs`, `ViewSwitch`

### Data Display
`Avatar`, `BooleanIcon`, `Chart`, `DataTable`, `Heatmap`, `Icon`, `ImageGrid`, `InfoLevel`, `LabelValue`, `List`, `LocationsMap`, `Progress`, `PropertiesTable`, `QrCode`, `Rate`, `Skeleton`, `StatCard`, `Table`, `Tag`, `Tags`, `Timeago`, `Timeline`, `TreeView`

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
  <%= f.submit_group 'Save', variant: :primary %>
<% end %>
```

## Development

### Running the Preview Server

```bash
cd test/dummy && bin/dev
```

Open [http://localhost:3001/lookbook](http://localhost:3001/lookbook) to browse component previews.

### Running Tests

```bash
# Minitest suite
bin/rails test

# Cypress tests (requires server running on port 3001)
yarn run cy:run   # Headless
yarn run cy:open  # Interactive
```

### Creating New Components

There is no generator — components are written by hand. Each one lives in its own directory
under `app/components/bali/`:

```
app/components/bali/my_component/
├── component.rb         # the class, inherits ApplicationViewComponent (required)
├── component.html.erb   # template, or a `call` method on the class
├── preview.rb           # Lookbook preview, inherits ApplicationViewComponentPreview (required)
├── previews/            # ERB templates for preview scenarios that need markup
├── index.css            # optional
└── index.js             # optional, a co-located Stimulus controller

test/bali/components/my_component_test.rb   # Minitest (required)
cypress/e2e/my-component.cy.js              # only when the component has JS behaviour
```

`index.css` ships only once it is imported from `app/assets/stylesheets/bali/components.css`,
and `index.js` only once its controller is added to the `CONTROLLERS` map in
`app/frontend/bali/components/index.js` — `yarn check:manifest` fails on a controller that is
reachable from neither.

Run the new test on its own with:

```bash
bin/rails test test/bali/components/my_component_test.rb
```

[Component Patterns](docs/reference/component-patterns.md) has the class, template, preview and
CSS conventions; the [components guide](docs/guides/components.md) has the catalog and the
composition rules.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`bin/rails test`)
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
| Alert | ✓ | ✓ | ✓ |
| AppLayout | ✓ | ✓ | ✓ |
| Avatar | ✓ | ✓ | ✓ |
| BlockEditor | ✓ | ✓ | ✓ |
| BooleanIcon | ✓ | ✓ | ✓ |
| Breadcrumb | ✓ | ✓ | ✓ |
| BulkActions | ✓ | ✓ | ✓ |
| Button | ✓ | ✓ | ✓ |
| Calendar | ✓ | ✓ | ✓ |
| Card | ✓ | ✓ | ✓ |
| Carousel | ✓ | ✓ | ✓ |
| Chart | ✓ | ✓ | ✓ |
| Chat | ✓ | ✓ | ✓ |
| Clipboard | ✓ | ✓ | ✓ |
| Columns | ✓ | ✓ | ✓ |
| Command | ✓ | ✓ | ✓ |
| DashboardPage | ✓ | ✓ | ✓ |
| DataTable | ✓ | ✓ | ✓ |
| DeleteLink | ✓ | ✓ | ✓ |
| DescriptionList | ✓ | ✓ | ✓ |
| DirectUpload | ✓ | ✓ | ✓ |
| DocumentEditor | ✓ | ✓ | ✓ |
| DocumentPage | ✓ | ✓ | ✓ |
| Drawer | ✓ | ✓ | ✓ |
| Dropdown | ✓ | ✓ | ✓ |
| EmptyState | ✓ | ✓ | ✓ |
| FeedbackWidget | ✓ | ✓ | ✓ |
| FieldGroupWrapper | ✓ | - | ✓ |
| Filters | ✓ | ✓ | ✓ |
| FlashNotifications | - | - | ✓ |
| Footer | ✓ | ✓ | ✓ |
| FormPage | ✓ | ✓ | ✓ |
| Gantt | ✓ | ✓ | ✓ |
| Heatmap | ✓ | ✓ | ✓ |
| HelpTip | ✓ | ✓ | ✓ |
| Hero | ✓ | ✓ | ✓ |
| HoverCard | ✓ | ✓ | ✓ |
| Icon | ✓ | ✓ | ✓ |
| ImageField | ✓ | ✓ | ✓ |
| ImageGrid | ✓ | ✓ | ✓ |
| IndexPage | ✓ | ✓ | ✓ |
| InfoLevel | ✓ | ✓ | ✓ |
| Kanban | ✓ | ✓ | ✓ |
| LabelValue | ✓ | ✓ | ✓ |
| Level | ✓ | ✓ | ✓ |
| Link | ✓ | ✓ | ✓ |
| List | ✓ | ✓ | ✓ |
| Loader | ✓ | ✓ | ✓ |
| LocationsMap | ✓ | ✓ | ✓ |
| Message | - | - | ✓ |
| Modal | ✓ | ✓ | ✓ |
| Navbar | ✓ | - | ✓ |
| Notification | - | - | ✓ |
| PageHeader | ✓ | ✓ | ✓ |
| Pagination | ✓ | ✓ | ✓ |
| PaginationFooter | ✓ | ✓ | ✓ |
| Progress | ✓ | ✓ | ✓ |
| PropertiesTable | ✓ | ✓ | ✓ |
| QrCode | ✓ | ✓ | ✓ |
| QrScanner | ✓ | ✓ | ✓ |
| Rate | ✓ | ✓ | ✓ |
| RecurrentEventRuleForm | ✓ | ✓ | ✓ |
| Reveal | ✓ | ✓ | ✓ |
| RichTextEditor | ✓ | ✓ | ✓ |
| ShowPage | ✓ | ✓ | ✓ |
| SideMenu | ✓ | ✓ | ✓ |
| Skeleton | ✓ | ✓ | ✓ |
| SortableList | ✓ | ✓ | ✓ |
| SplitView | ✓ | ✓ | ✓ |
| StatCard | ✓ | ✓ | ✓ |
| Status | ✓ | ✓ | ✓ |
| Stepper | ✓ | ✓ | ✓ |
| Table | ✓ | ✓ | ✓ |
| Tabs | ✓ | ✓ | ✓ |
| Tag | ✓ | ✓ | ✓ |
| Tags | ✓ | ✓ | ✓ |
| Timeago | ✓ | ✓ | ✓ |
| Timeline | ✓ | ✓ | ✓ |
| Toast | ✓ | ✓ | ✓ |
| ToastContainer | ✓ | ✓ | ✓ |
| Tooltip | ✓ | ✓ | ✓ |
| Topbar | ✓ | ✓ | ✓ |
| TreeView | ✓ | ✓ | ✓ |
| ViewSwitch | ✓ | ✓ | ✓ |
| WorkflowSteps | ✓ | ✓ | ✓ |

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
