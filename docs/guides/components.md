# Component Usage Guide

This guide covers how to use Bali ViewComponents in your Rails views.

## Basic Rendering

All Bali components use Rails' ViewComponent library. Render them using the standard `render` helper:

```erb
<%= render Bali::Button::Component.new(name: 'Click Me') %>
```

## Component Naming Convention

Components follow this naming pattern:

```ruby
Bali::[Name]::Component
```

Examples:
- `Bali::Button::Component`
- `Bali::Card::Component`
- `Bali::Modal::Component`

---

## Common Parameters

Most components share these standard parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `variant` | Symbol | Style variant (`:primary`, `:secondary`, etc.) |
| `size` | Symbol | Size modifier (`:xs`, `:sm`, `:md`, `:lg`, `:xl`) |
| `class` | String | Additional CSS classes |
| `data` | Hash | Data attributes for Stimulus |
| `**options` | Hash | Any additional HTML attributes |

---

## Variants and Sizes

### Standard Variants

DaisyUI semantic colors available on most components:

| Variant | Use Case |
|---------|----------|
| `:primary` | Main actions, emphasis |
| `:secondary` | Secondary actions |
| `:accent` | Highlights, special elements |
| `:success` | Positive feedback, confirmations |
| `:warning` | Cautions, attention needed |
| `:error` | Errors, destructive actions |
| `:info` | Informational |
| `:neutral` | Subdued, neutral |
| `:ghost` | Minimal styling |

### Standard Sizes

| Size | Description |
|------|-------------|
| `:xs` | Extra small |
| `:sm` | Small |
| `:md` | Medium (usually default) |
| `:lg` | Large |
| `:xl` | Extra large |

---

## Components with Slots

Many components use ViewComponent slots for flexible content composition.

### Understanding Slots

Slots allow you to inject content into specific areas of a component:

```erb
<%= render Bali::Card::Component.new do |card| %>
  <% card.with_header { "Card Title" } %>
  <% card.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Save') %>
  <% end %>

  <%# Default content goes in the body %>
  <p>This is the card content.</p>
<% end %>
```

### Slot Types

| Syntax | Description |
|--------|-------------|
| `renders_one :name` | Single slot (0 or 1 instance) |
| `renders_many :name` | Multiple slots (0 or more instances) |

### Common Slot Patterns

**Single content slot:**
```erb
<%= render Bali::Card::Component.new do |c| %>
  <% c.with_title("My Title") %>
  Card body content here
<% end %>
```

**Multiple slots:**
```erb
<%= render Bali::Tabs::Component.new do |tabs| %>
  <% tabs.with_tab(label: "Tab 1") { "Content 1" } %>
  <% tabs.with_tab(label: "Tab 2") { "Content 2" } %>
  <% tabs.with_tab(label: "Tab 3") { "Content 3" } %>
<% end %>
```

**Slots with parameters:**
```erb
<%= render Bali::Card::Component.new do |c| %>
  <% c.with_image(src: "/image.jpg", alt: "Description") %>
  <% c.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Action', variant: :primary) %>
  <% end %>
<% end %>
```

---

## Component Categories

### Layout Components

#### Card

Content container with optional header, image, and actions.

```erb
<%= render Bali::Card::Component.new(style: :bordered, shadow: true) do |c| %>
  <% c.with_image(src: "/photo.jpg") %>
  <% c.with_title("Card Title") %>
  <p>Card description text.</p>
  <% c.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Details', variant: :primary) %>
  <% end %>
<% end %>
```

**Options:**
- `style` - `:default`, `:bordered`, `:dash`
- `size` - `:xs`, `:sm`, `:md`, `:lg`, `:xl`
- `side` - Horizontal layout (image on side)
- `image_full` - Image overlays entire card
- `shadow` - Enable shadow (default: true)

#### Modal

Dialog overlay for focused interactions.

```erb
<%= render Bali::Modal::Component.new(title: "Confirm Action") do |modal| %>
  <% modal.with_trigger do %>
    <%= render Bali::Button::Component.new(name: 'Open Modal') %>
  <% end %>

  <p>Are you sure you want to proceed?</p>

  <% modal.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Cancel', variant: :ghost, data: { action: 'modal#close' }) %>
    <%= render Bali::Button::Component.new(name: 'Confirm', variant: :primary) %>
  <% end %>
<% end %>
```

#### Drawer

Slide-in panel from edge of screen.

```erb
<%= render Bali::Drawer::Component.new(title: "Settings", position: :right) do |drawer| %>
  <% drawer.with_trigger { "Open Settings" } %>
  <%# Drawer content %>
  <p>Drawer panel content here.</p>
<% end %>
```

---

### Navigation Components

#### Breadcrumb

Navigation path indicator.

```erb
<%= render Bali::Breadcrumb::Component.new do |bc| %>
  <% bc.with_item(href: "/") { "Home" } %>
  <% bc.with_item(href: "/products") { "Products" } %>
  <% bc.with_item { "Current Page" } %>  <%# No href = current %>
<% end %>
```

#### Tabs

Tabbed content navigation.

```erb
<%= render Bali::Tabs::Component.new(variant: :boxed) do |tabs| %>
  <% tabs.with_tab(label: "Overview", active: true) do %>
    Overview content...
  <% end %>
  <% tabs.with_tab(label: "Details") do %>
    Details content...
  <% end %>
<% end %>
```

#### Dropdown

Action menu that opens on click/hover.

```erb
<%= render Bali::Dropdown::Component.new do |dd| %>
  <% dd.with_trigger { "Options" } %>
  <% dd.with_item(href: "/edit") { "Edit" } %>
  <% dd.with_item(href: "/delete", class: "text-error") { "Delete" } %>
<% end %>
```

---

### Data Display Components

#### Table

Data table with optional sorting and pagination.

```erb
<%= render Bali::Table::Component.new(zebra: true) do |table| %>
  <% table.with_header(name: "Name", sort: :name) %>
  <% table.with_header(name: "Email") %>
  <% table.with_header(name: "Status") %>

  <% @users.each do |user| %>
    <% table.with_row do |row| %>
      <% row.with_cell { user.name } %>
      <% row.with_cell { user.email } %>
      <% row.with_cell { render Bali::Tag::Component.new(text: user.status, color: status_color(user)) } %>
    <% end %>
  <% end %>
<% end %>
```

#### Avatar

User avatar display.

```erb
<%= render Bali::Avatar::Component.new(
  src: user.avatar_url,
  alt: user.name,
  size: :md,
  shape: :circle
) %>
```

#### Tag (Badge)

Labels and status indicators.

```erb
<%= render Bali::Tag::Component.new(text: "New", color: :primary) %>
<%= render Bali::Tag::Component.new(text: "Pending", color: :warning, outline: true) %>
```

#### Progress

Progress bar indicator.

```erb
<%= render Bali::Progress::Component.new(value: 75, max: 100, color: :primary) %>
```

---

### Interactive Components

#### Button

Primary interactive element for actions.

```erb
<%# Basic %>
<%= render Bali::Button::Component.new(name: 'Save', variant: :primary) %>

<%# With icon %>
<%= render Bali::Button::Component.new(name: 'Add', variant: :success, icon_name: 'plus') %>

<%# Loading state %>
<%= render Bali::Button::Component.new(name: 'Processing...', loading: true, disabled: true) %>

<%# Icon slots %>
<%= render Bali::Button::Component.new(name: 'Next', variant: :primary) do |btn| %>
  <% btn.with_icon_right('arrow-right') %>
<% end %>
```

**Options:**
- `name` - Button text
- `variant` - Style variant
- `size` - Size modifier
- `icon_name` - Left icon name
- `type` - `:button`, `:submit`, `:reset`
- `disabled` - Disable button
- `loading` - Show loading spinner

#### Link

Navigation links, optionally styled as buttons.

```erb
<%# Plain link %>
<%= render Bali::Link::Component.new(name: 'View Details', href: item_path(@item)) %>

<%# Link styled as button %>
<%= render Bali::Link::Component.new(
  name: 'Create New',
  href: new_item_path,
  type: :primary  # Button styling
) %>
```

**When to use Button vs Link:**
- Use `Button` for **actions** (submit, click handlers)
- Use `Link` for **navigation** (goes to a URL)

#### Tooltip

Contextual information on hover.

```erb
<%= render Bali::Tooltip::Component.new(content: "More information", position: :top) do %>
  Hover over me
<% end %>
```

---

### Form Components

#### Filters

Advanced filter controls for data tables with Ransack integration.

```erb
<%= render Bali::Filters::Component.new(
  url: products_path,
  filter_form: @filter_form,
  available_attributes: [
    { key: :name, label: 'Name', type: :text },
    { key: :status, label: 'Status', type: :select, options: Status.options }
  ]
) %>
```

**Features:**
- Multiple filter groups with AND/OR combinators
- Type-specific operators (text, number, date, select, boolean)
- Quick search with clear button (x) for easy clearing
- Filter persistence with bookmark toggle
- Date range "between" operator with Flatpickr

**Modes:**
- `popover: true` (default) - Compact dropdown with search input
- `popover: false` - Inline card layout

**Search Clear Button:**

The search input includes a clear button (x) that appears when text is entered. Clicking it:
- Clears the search input
- Submits `clear_search=1` to clear persisted search
- Preserves other filters

**Options:**

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `url` | String | Required | Form action URL |
| `filter_form` | FilterForm | Required | FilterForm instance |
| `available_attributes` | Array | `[]` | Filterable attributes |
| `popover` | Boolean | `true` | Use popover mode |
| `storage_id` | String | `nil` | Enable persistence |

#### SearchInput

Search field with icon.

```erb
<%= render Bali::SearchInput::Component.new(
  name: 'q',
  placeholder: 'Search...',
  value: params[:q]
) %>
```

---

### Feedback Components

#### Notification

Alert messages and feedback.

```erb
<%= render Bali::Notification::Component.new(
  type: :success,
  message: "Changes saved successfully!"
) %>

<%= render Bali::Notification::Component.new(type: :error, dismissible: true) do %>
  <strong>Error:</strong> Please fix the following issues.
<% end %>
```

**Types:** `:info`, `:success`, `:warning`, `:error`

#### Loader

Loading indicator.

```erb
<%= render Bali::Loader::Component.new(size: :lg, color: :primary) %>
```

---

## Custom CSS Classes

Add custom classes with the `class` option:

```erb
<%= render Bali::Card::Component.new(class: 'my-custom-class hover:shadow-lg') %>
```

Classes are merged with component's default classes.

---

## Data Attributes for Stimulus

Pass data attributes for Stimulus controllers:

```erb
<%= render Bali::Button::Component.new(
  name: 'Toggle',
  data: {
    controller: 'toggle',
    action: 'click->toggle#switch',
    toggle_target: 'button'
  }
) %>
```

---

## Component Composition

Build complex UIs by composing multiple components:

```erb
<%= render Bali::Card::Component.new(style: :bordered) do |card| %>
  <% card.with_header { "User Profile" } %>

  <div class="flex items-center gap-4">
    <%= render Bali::Avatar::Component.new(src: @user.avatar, size: :lg) %>
    <div>
      <h3 class="font-bold"><%= @user.name %></h3>
      <%= render Bali::Tag::Component.new(text: @user.role, color: :info) %>
    </div>
  </div>

  <% card.with_actions do %>
    <%= render Bali::Button::Component.new(name: 'Edit', variant: :ghost) %>
    <%= render Bali::Button::Component.new(name: 'Message', variant: :primary) %>
  <% end %>
<% end %>
```

---

## Lookbook Previews

Browse all components and their variations in Lookbook:

```bash
cd spec/dummy && bin/dev
```

Open [http://localhost:3001/lookbook](http://localhost:3001/lookbook)

Each component has interactive previews showing:
- All variants and sizes
- Slot usage examples
- State variations (loading, disabled, etc.)
- Real-world use cases

---

## Best Practices

### DO

- Use semantic variants (`:success` for confirmations, `:error` for destructive actions)
- Compose components rather than duplicating HTML
- Use slots for complex content
- Pass data attributes for Stimulus integration

### DON'T

- Mix raw HTML with DaisyUI classes when a component exists
- Override component styles with inline styles
- Use `Button` for navigation (use `Link` instead)
- Skip accessibility attributes (components handle most, but add `aria-label` when needed)

---

## Next Steps

- [FormBuilder Guide](form-builder.md) - Enhanced form helpers
- [Component Patterns](../reference/component-patterns.md) - Internal patterns for contributors
- [Accessibility Guide](accessibility.md) - WCAG compliance details
