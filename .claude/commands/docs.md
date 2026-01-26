# Documentation Generator Command

Generate documentation for Bali ViewComponents for gem consumers.

## Usage

```
/docs $ARGUMENTS
```

Where `$ARGUMENTS` is:
- Component name (e.g., `Button`, `Modal`) - Generate docs for specific component
- `--all` - Generate docs for all components
- `--api` - API reference only (YARD-style)
- `--examples` - Usage examples only
- `--output:PATH` - Output directory (default: `docs/api/`)
- `--format:md` or `--format:html` - Output format (default: md)

## Workflow

### Step 1: Read Component Source

For each component, extract:

1. **Class Information** from `component.rb`:
   - Module/class name
   - Parent class
   - Constants (VARIANTS, SIZES, etc.)
   - Initialize parameters with defaults
   - Public methods
   - Slots defined

2. **Template Structure** from `component.html.erb`:
   - Root element type
   - Data attributes
   - Slot placeholders

3. **Preview Examples** from `preview.rb`:
   - Preview methods
   - Parameter annotations
   - Example variations

### Step 2: Generate API Documentation

```markdown
# Bali::[Component]::Component

[Brief description extracted from class comment or inferred]

## Installation

Ensure you have the Bali gem installed:

```ruby
gem "bali_view_components"
```

## Basic Usage

```erb
<%= render Bali::[Component]::Component.new %>
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `variant` | Symbol | `:primary` | Visual style variant |
| `size` | Symbol | `:md` | Size of the component |
| `**options` | Hash | `{}` | Additional HTML attributes |

## Variants

| Variant | Class | Description |
|---------|-------|-------------|
| `:primary` | `btn-primary` | Primary action style |
| `:secondary` | `btn-secondary` | Secondary action style |
| ... | ... | ... |

## Sizes

| Size | Class | Description |
|------|-------|-------------|
| `:xs` | `btn-xs` | Extra small |
| `:sm` | `btn-sm` | Small |
| `:md` | `btn-md` | Medium (default) |
| `:lg` | `btn-lg` | Large |

## Slots

| Slot | Type | Description |
|------|------|-------------|
| `header` | Single | Card header content |
| `items` | Multiple | Menu items |

## Examples

### Basic

```erb
<%= render Bali::Button::Component.new(variant: :primary) do %>
  Click me
<% end %>
```

### With Options

```erb
<%= render Bali::Button::Component.new(
  variant: :success,
  size: :lg,
  data: { turbo: false }
) do %>
  Submit
<% end %>
```

### With Slots

```erb
<%= render Bali::Card::Component.new do |card| %>
  <% card.with_header do %>
    Card Title
  <% end %>
  
  <% card.with_body do %>
    Card content goes here.
  <% end %>
  
  <% card.with_actions do %>
    <%= render Bali::Button::Component.new(variant: :primary) { "Save" } %>
  <% end %>
<% end %>
```

## Stimulus Controller

This component uses the `[name]` Stimulus controller.

### Actions

| Action | Description |
|--------|-------------|
| `toggle` | Toggles the component state |
| `open` | Opens the component |
| `close` | Closes the component |

### Events

| Event | Detail | Description |
|-------|--------|-------------|
| `[name]:open` | `{}` | Fired when component opens |
| `[name]:close` | `{}` | Fired when component closes |

## Accessibility

- [x] Keyboard accessible
- [x] Screen reader compatible
- [x] Focus management

See individual accessibility requirements in the component source.

## See Also

- [DaisyUI Button](https://daisyui.com/components/button/)
- [Lookbook Preview](/lookbook/inspect/bali/button)
```

### Step 3: Generate Index

```markdown
# Bali ViewComponents API Reference

## Components

### Layout
- [Card](./card.md) - Content container with header, body, footer
- [Columns](./columns.md) - Responsive grid layout
- [Modal](./modal.md) - Dialog/modal overlay
- [Drawer](./drawer.md) - Slide-out panel

### Navigation
- [Breadcrumb](./breadcrumb.md) - Navigation breadcrumbs
- [Navbar](./navbar.md) - Top navigation bar
- [SideMenu](./sidemenu.md) - Side navigation
- [Tabs](./tabs.md) - Tabbed interface

### Forms
- [Form](./form.md) - Form components
- [SearchInput](./searchinput.md) - Search input field
- [Filters](./filters.md) - Filter interface

### Feedback
- [Alert](./alert.md) - Alert/notification messages
- [Loader](./loader.md) - Loading indicators
- [Progress](./progress.md) - Progress bars
- [Tooltip](./tooltip.md) - Hover tooltips

### Data Display
- [Table](./table.md) - Data tables
- [DataTable](./datatable.md) - Advanced data table
- [List](./list.md) - List display
- [Badge](./badge.md) - Status badges

### Actions
- [Button](./button.md) - Action buttons
- [Link](./link.md) - Navigation links
- [Dropdown](./dropdown.md) - Dropdown menus
```

## Example Output

### For Single Component

```
User: /docs Button

AI: Generating documentation for Bali::Button::Component...

Reading component files...
- app/components/bali/button/component.rb
- app/components/bali/button/component.html.erb
- app/components/bali/button/preview.rb

Extracting:
- 10 variants
- 5 sizes
- 4 boolean options
- 0 slots
- 1 Stimulus controller

Generating docs/api/button.md...

# Bali::Button::Component

A versatile button component with multiple variants and sizes.

## Basic Usage

\`\`\`erb
<%= render Bali::Button::Component.new do %>
  Click me
<% end %>
\`\`\`

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `variant` | Symbol | `:primary` | Visual variant (see Variants) |
| `size` | Symbol | `:md` | Button size (see Sizes) |
| `loading` | Boolean | `false` | Show loading spinner |
| `disabled` | Boolean | `false` | Disable the button |
| `type` | String | `"button"` | HTML button type |
| `**options` | Hash | `{}` | Additional HTML attributes |

## Variants

| Variant | Preview | Usage |
|---------|---------|-------|
| `:primary` | Primary | Main actions |
| `:secondary` | Secondary | Secondary actions |
| `:accent` | Accent | Highlighted actions |
| `:success` | Success | Positive actions |
| `:warning` | Warning | Cautionary actions |
| `:error` | Error | Destructive actions |
| `:info` | Info | Informational actions |
| `:ghost` | Ghost | Minimal styling |
| `:link` | Link | Link-like appearance |
| `:outline` | Outline | Outlined style |

## Sizes

| Size | Class |
|------|-------|
| `:xs` | Extra small |
| `:sm` | Small |
| `:md` | Medium (default) |
| `:lg` | Large |
| `:xl` | Extra large |

## Examples

### Variants

\`\`\`erb
<%= render Bali::Button::Component.new(variant: :primary) { "Primary" } %>
<%= render Bali::Button::Component.new(variant: :success) { "Success" } %>
<%= render Bali::Button::Component.new(variant: :error) { "Delete" } %>
\`\`\`

### Sizes

\`\`\`erb
<%= render Bali::Button::Component.new(size: :sm) { "Small" } %>
<%= render Bali::Button::Component.new(size: :lg) { "Large" } %>
\`\`\`

### Loading State

\`\`\`erb
<%= render Bali::Button::Component.new(loading: true) { "Saving..." } %>
\`\`\`

### With Data Attributes

\`\`\`erb
<%= render Bali::Button::Component.new(
  data: { 
    turbo_method: :delete,
    turbo_confirm: "Are you sure?"
  }
) { "Delete" } %>
\`\`\`

### As Link

\`\`\`erb
<%= render Bali::Button::Component.new(
  tag: :a,
  href: "/dashboard"
) { "Go to Dashboard" } %>
\`\`\`

## Accessibility

- Buttons have accessible names from content
- Disabled state communicated via `disabled` attribute and `aria-disabled`
- Loading state communicated via `aria-busy`
- Focus is visible with ring indicator

## Migration Notes

If migrating from Bulma version:
- `variant: :danger` → `variant: :error`
- `size: :small` → `size: :sm`
- `size: :large` → `size: :lg`

---

Documentation generated. View at docs/api/button.md
```

### For All Components

```
User: /docs --all

AI: Generating documentation for all Bali components...

Found 60 components.

Generating documentation:
[========================================] 60/60

Generated files:
- docs/api/index.md
- docs/api/actions_dropdown.md
- docs/api/avatar.md
- docs/api/badge.md
- docs/api/boolean_icon.md
- docs/api/breadcrumb.md
- docs/api/button.md
- docs/api/calendar.md
- docs/api/card.md
- docs/api/carousel.md
... (50 more)

Summary:
- Total components documented: 60
- Components with examples: 48
- Components with Stimulus controllers: 25
- Components with slots: 18

Documentation index available at: docs/api/index.md
```

## Template Variables

When generating docs, these variables are extracted:

```ruby
{
  component_name: "Button",
  full_class_name: "Bali::Button::Component",
  parent_class: "ApplicationComponent",
  
  parameters: [
    { name: "variant", type: "Symbol", default: ":primary", description: "..." },
    { name: "size", type: "Symbol", default: ":md", description: "..." }
  ],
  
  variants: {
    primary: { class: "btn-primary", description: "Primary action" },
    secondary: { class: "btn-secondary", description: "Secondary action" }
  },
  
  sizes: {
    xs: "btn-xs",
    sm: "btn-sm",
    md: "btn-md",
    lg: "btn-lg"
  },
  
  slots: [
    { name: "header", type: "single", description: "..." }
  ],
  
  stimulus_controller: "button",
  
  examples: [
    { name: "basic", code: "..." },
    { name: "with_variants", code: "..." }
  ]
}
```

## Integration

### With Lookbook

Generated docs can link to Lookbook previews:

```markdown
## Live Preview

View interactive examples in [Lookbook](/lookbook/inspect/bali/button)
```

### With YARD

For Ruby documentation:

```bash
# Generate YARD docs
yard doc app/components/bali/

# Serve locally
yard server
```

### With Jekyll/Docusaurus

Export as Jekyll-compatible markdown:

```
/docs --all --format:jekyll --output:_docs/
```
