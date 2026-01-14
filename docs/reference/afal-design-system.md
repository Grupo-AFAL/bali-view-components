# AFAL Design System Reference

This document provides guidance for aligning Bali ViewComponents with the AFAL design system, based on the DaisyUI templates (Nexus and Scalo) documented in the AFAL handbook.

## Design System Location

The complete design system reference is maintained in the AFAL handbook repository:

```
afal/handbook/design-system/
├── DESIGN-SYSTEM.md              # Complete component catalog
├── .claude/CLAUDE.md             # Quick AI reference
├── nexus-html@3.2.0/             # Admin dashboard template
│   ├── .clinerules/daisyui.md    # Complete daisyUI 5 reference
│   ├── .clinerules/nexus.md      # Nexus-specific patterns
│   └── src/partials/             # Component implementations
└── scalo-html@3.1.0/             # Marketing/landing template
    └── src/partials/             # Marketing components
```

## When to Reference

| Building This... | Reference This |
|------------------|----------------|
| Admin UI components | Nexus (`nexus-html@3.2.0/src/partials/`) |
| Dashboard stats, charts | Nexus `partials/blocks/stats/` |
| Data tables | Nexus `partials/interactions/datatables/` |
| Form interactions | Nexus `partials/interactions/` |
| Landing pages | Scalo (`scalo-html@3.1.0/src/partials/`) |
| Pricing sections | Scalo `partials/*/pricing.html` |
| Marketing heroes | Scalo `partials/*/hero.html` |
| Testimonials | Scalo `partials/*/testimonials.html` |

## Bali Component ↔ DaisyUI Alignment

### Core Components (Already Migrated Pattern)

| Bali Component | DaisyUI Classes | Handbook Reference |
|----------------|-----------------|-------------------|
| `Bali::Card` | `card bg-base-100 card-border` | Nexus stats blocks |
| `Bali::Modal` | `modal modal-box` | DaisyUI modal pattern |
| `Bali::Tabs` | `tabs tabs-box tab` | Nexus/Scalo tabs |
| `Bali::Dropdown` | `dropdown dropdown-content menu` | DaisyUI dropdown |
| `Bali::Table` | `table table-zebra` | Nexus datatables |
| `Bali::Progress` | `progress progress-*` | DaisyUI progress |
| `Bali::Avatar` | `avatar` | DaisyUI avatar |
| `Bali::Tooltip` | `tooltip tooltip-*` | DaisyUI tooltip |
| `Bali::Stepper` | `steps step step-*` | DaisyUI steps |
| `Bali::Timeline` | `timeline timeline-*` | DaisyUI timeline |
| `Bali::Drawer` | `drawer drawer-content drawer-side` | Nexus sidebar |
| `Bali::Notification` | `alert alert-*` | DaisyUI alert |

### Recommended New Components (From Templates)

These patterns exist in Nexus/Scalo but not yet in Bali:

| Pattern | Source | Priority |
|---------|--------|----------|
| Stats Card with Trend | `nexus/partials/blocks/stats/minimal.html` | High |
| AI Prompt Bar | `nexus/partials/blocks/prompt-bar/` | Medium |
| Pricing Card | `scalo/partials/*/pricing.html` | Medium |
| Feature Check List | Scalo pricing sections | Low |
| Section Header | Scalo section patterns | Low |
| Testimonial Card | `scalo/partials/*/testimonials.html` | Low |

## Component Implementation Checklist

When creating or migrating a Bali component:

### 1. Check Design System First

```bash
# Search for similar patterns in the handbook
grep -r "component-name" /path/to/handbook/design-system/
```

### 2. Use DaisyUI Semantic Classes

```ruby
# GOOD: DaisyUI classes
def card_classes
  class_names('card', 'bg-base-100', 'card-border', SIZES[@size])
end

# BAD: Raw Tailwind only
def card_classes
  'rounded-lg border border-gray-200 bg-white p-4'
end
```

### 3. Use Semantic Colors

```ruby
# GOOD: Theme-aware
VARIANTS = {
  primary: 'btn-primary',
  success: 'btn-success',
  error: 'btn-error'  # NOT "danger"
}.freeze

# BAD: Fixed colors
VARIANTS = {
  primary: 'bg-blue-500 text-white',
  danger: 'bg-red-500 text-white'
}.freeze
```

### 4. Match Template Patterns

Before implementing, check if Nexus/Scalo has a similar component:

```erb
<%# Check: handbook/design-system/nexus-html@3.2.0/src/partials/ %>
<%# Match the HTML structure and classes %>
```

## Stat Card Pattern (Example)

From Nexus `partials/blocks/stats/minimal.html`:

```erb
<%# Bali implementation should match this pattern %>
<div class="card bg-base-100 card-border">
  <div class="card-body">
    <p class="text-base-content/60 text-xs font-medium tracking-wide uppercase">
      <%= label %>
    </p>
    <div class="mt-4 flex items-end justify-end gap-2 text-sm">
      <p class="text-2xl/none font-semibold"><%= value %></p>
      <% if trend.present? %>
        <div class="<%= trend_positive? ? 'text-success' : 'text-error' %> flex items-center gap-0.5 px-1 font-medium">
          <span class="iconify lucide--arrow-<%= trend_positive? ? 'up' : 'down' %> size-3.5"></span>
          <%= trend %>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

## Icons

Bali uses Lucide icons (via Iconify), matching the templates:

```erb
<%# Bali Icon component %>
<%= render Bali::Icon::Component.new(name: 'home') %>

<%# Raw Iconify (template style) %>
<span class="iconify lucide--home size-4"></span>
```

Common sizes: `size-3.5`, `size-4`, `size-4.5`, `size-5`, `size-6`

## Color Reference

| Semantic Color | Usage |
|----------------|-------|
| `primary` | Main actions, key UI elements |
| `secondary` | Secondary actions |
| `accent` | Highlights, special features |
| `neutral` | Neutral backgrounds, borders |
| `base-100/200/300` | Surface colors (lightest to darkest) |
| `success` | Positive states, confirmations |
| `warning` | Caution, pending states |
| `error` | Errors, destructive actions |
| `info` | Informational messages |

Use `*-content` for text on colored backgrounds:
- `primary-content` on `bg-primary`
- `base-content` on `bg-base-*`

## Typography Patterns

From the templates:

```html
<!-- Section title -->
<p class="text-center text-2xl font-semibold sm:text-3xl">Title</p>

<!-- Section description -->
<p class="text-base-content/80 max-w-lg">Description text</p>

<!-- Small label -->
<p class="text-base-content/60 text-xs font-medium tracking-wide uppercase">LABEL</p>

<!-- Large stat value -->
<p class="text-2xl/none font-semibold">1,234</p>
```

## Responsive Patterns

Match the template breakpoints:

```ruby
# Responsive classes in components
def responsive_grid_classes
  'grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
end

def responsive_padding
  'py-8 md:py-12 lg:py-16 2xl:py-28'
end
```

## Testing Against Design System

1. **Visual comparison**: Open Lookbook alongside the handbook templates
2. **Class verification**: Ensure generated classes match template patterns
3. **Theme testing**: Verify components work in light and dark themes

```ruby
# In RSpec tests
expect(page).to have_css('.card.bg-base-100.card-border')
expect(page).to have_css('.text-success')  # Not .text-green-500
```

## Resources

- **AFAL Handbook Design System**: `handbook/design-system/DESIGN-SYSTEM.md`
- **daisyUI 5 Complete Reference**: `handbook/design-system/nexus-html@3.2.0/.clinerules/daisyui.md`
- **Nexus AI Guide**: `handbook/design-system/nexus-html@3.2.0/.clinerules/nexus.md`
- **daisyUI Official Docs**: https://daisyui.com/components/
- **Tailwind CSS Docs**: https://tailwindcss.com/docs
