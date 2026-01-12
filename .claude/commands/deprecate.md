# Deprecate Component Command

Mark Bali ViewComponents or parameters as deprecated with migration guidance.

## Usage

```
/deprecate $ARGUMENTS
```

Where `$ARGUMENTS` is:
- Component name to deprecate (e.g., `Box`, `Level`)
- `--param:NAME` - Deprecate a specific parameter instead of whole component
- `--replacement:NAME` - Suggest replacement component/parameter
- `--version:X.X.X` - Version when deprecation takes effect
- `--removal:X.X.X` - Version when removal will occur
- `--silent` - Don't show warnings (for internal deprecations)

## Workflow

### Step 1: Determine Deprecation Type

| Type | Example | Action |
|------|---------|--------|
| Full component | `/deprecate Box` | Mark component deprecated |
| Parameter | `/deprecate Button --param:type` | Mark parameter deprecated |
| Variant | `/deprecate Button --param:variant:danger` | Mark variant deprecated |
| Slot | `/deprecate Card --param:slot:footer` | Mark slot deprecated |

### Step 2: Add Deprecation Warning to Component

#### Full Component Deprecation

```ruby
# app/components/bali/box/component.rb
module Bali
  module Box
    class Component < ApplicationComponent
      # @deprecated Use {Card::Component} instead. Will be removed in v3.0.
      
      def initialize(**options)
        ActiveSupport::Deprecation.warn(
          "Bali::Box::Component is deprecated. Use Bali::Card::Component instead. " \
          "Box will be removed in version 3.0.",
          caller
        )
        @options = options
      end
    end
  end
end
```

#### Parameter Deprecation

```ruby
# app/components/bali/button/component.rb
module Bali
  module Button
    class Component < ApplicationComponent
      def initialize(
        variant: :primary,
        type: nil,  # @deprecated Use :variant instead
        **options
      )
        if type.present?
          ActiveSupport::Deprecation.warn(
            "The :type parameter is deprecated. Use :variant instead. " \
            ":type will be removed in version 3.0.",
            caller
          )
          variant = type
        end
        
        @variant = variant
        @options = options
      end
    end
  end
end
```

#### Variant Deprecation

```ruby
# app/components/bali/button/component.rb

VARIANT_DEPRECATIONS = {
  danger: { replacement: :error, message: "Use :error instead of :danger" }
}.freeze

def initialize(variant: :primary, **options)
  if VARIANT_DEPRECATIONS.key?(variant)
    deprecation = VARIANT_DEPRECATIONS[variant]
    ActiveSupport::Deprecation.warn(
      "Button variant :#{variant} is deprecated. #{deprecation[:message]}. " \
      "Will be removed in version 3.0.",
      caller
    )
    variant = deprecation[:replacement]
  end
  
  @variant = variant
  @options = options
end
```

### Step 3: Update Preview with Deprecation Notice

```ruby
# app/components/bali/box/preview.rb
module Bali
  module Box
    class Preview < Lookbook::Preview
      # @deprecated This component is deprecated. Use Card instead.
      # @label [DEPRECATED] Box
      def default
        render Component.new { "Content" }
      end
    end
  end
end
```

### Step 4: Add to Deprecation Log

Create or update `.claude/deprecations.md`:

```markdown
# Deprecated Components and Parameters

## Components

### Box (deprecated in v2.5, removal in v3.0)
- **Replacement**: Card
- **Reason**: Simplified component API
- **Migration**: Replace `Bali::Box` with `Bali::Card`

## Parameters

### Button :type (deprecated in v2.5, removal in v3.0)
- **Replacement**: :variant
- **Reason**: Naming consistency
- **Migration**: Change `type: :primary` to `variant: :primary`

### Button variant :danger (deprecated in v2.5, removal in v3.0)
- **Replacement**: :error
- **Reason**: DaisyUI naming convention
- **Migration**: Change `variant: :danger` to `variant: :error`
```

### Step 5: Create Migration Guide

Generate `docs/migrations/[component].md`:

```markdown
# Migrating from Box to Card

## Overview

The `Box` component is deprecated as of version 2.5 and will be removed in version 3.0.
Use `Card` instead.

## Why the Change?

- Card provides more flexibility with slots
- Better alignment with DaisyUI patterns
- Simpler API for common use cases

## Migration Steps

### Basic Box

```erb
<%# Before (deprecated) %>
<%= render Bali::Box::Component.new(class: "p-4") do %>
  Content here
<% end %>

<%# After %>
<%= render Bali::Card::Component.new do |card| %>
  <% card.with_body do %>
    Content here
  <% end %>
<% end %>
```

### Box with Header

```erb
<%# Before (deprecated) %>
<%= render Bali::Box::Component.new do %>
  <h3>Title</h3>
  <p>Content</p>
<% end %>

<%# After %>
<%= render Bali::Card::Component.new do |card| %>
  <% card.with_header do %>
    Title
  <% end %>
  <% card.with_body do %>
    <p>Content</p>
  <% end %>
<% end %>
```

## Timeline

| Version | Status |
|---------|--------|
| 2.5 | Deprecated (warnings shown) |
| 2.6-2.9 | Deprecated (warnings shown) |
| 3.0 | **Removed** |

## Finding Usage

Search your codebase:

```bash
grep -r "Bali::Box" app/
```

## Need Help?

If you have questions about migration, please open an issue.
```

### Step 6: Update CHANGELOG

Add deprecation notice to CHANGELOG.md:

```markdown
## [2.5.0] - 2026-01-15

### Deprecated
- `Bali::Box::Component` - Use `Bali::Card::Component` instead. Will be removed in v3.0.
- `Button` `:type` parameter - Use `:variant` instead. Will be removed in v3.0.
- `Button` `:danger` variant - Use `:error` instead. Will be removed in v3.0.
```

## Example Execution

### Deprecate Component

```
User: /deprecate Box --replacement:Card --version:2.5.0 --removal:3.0.0

AI: Deprecating Bali::Box::Component...

## Changes Made

### 1. Updated component.rb
Added deprecation warning to initialize method.

```ruby
def initialize(**options)
  ActiveSupport::Deprecation.warn(
    "Bali::Box::Component is deprecated. Use Bali::Card::Component instead. " \
    "Box will be removed in version 3.0.0.",
    caller
  )
  @options = options
end
```

### 2. Updated preview.rb
Added deprecation label to preview.

### 3. Created migration guide
docs/migrations/box-to-card.md

### 4. Updated deprecations log
.claude/deprecations.md

### 5. Prepared CHANGELOG entry
Add this to CHANGELOG.md under next release:

```markdown
### Deprecated
- `Bali::Box::Component` - Use `Bali::Card::Component` instead. Will be removed in v3.0.0.
```

## Consumer Impact

When consumers use Box, they will see:

```
DEPRECATION WARNING: Bali::Box::Component is deprecated. Use Bali::Card::Component instead. Box will be removed in version 3.0.0.
```

## Next Steps

1. Add CHANGELOG entry before next release
2. Notify team/consumers of deprecation
3. Update any internal usage
4. Set reminder for removal in v3.0.0
```

### Deprecate Parameter

```
User: /deprecate Button --param:type --replacement:variant --version:2.5.0

AI: Deprecating :type parameter on Bali::Button::Component...

## Changes Made

### 1. Updated component.rb

```ruby
def initialize(
  variant: :primary,
  type: nil,  # @deprecated Use :variant instead. Removal: v3.0.0
  **options
)
  if type.present?
    ActiveSupport::Deprecation.warn(
      "Bali::Button::Component :type parameter is deprecated. " \
      "Use :variant instead. :type will be removed in version 3.0.0.",
      caller
    )
    variant = type
  end
  
  @variant = variant
  @options = options
end
```

### 2. Updated deprecations log

### 3. Prepared CHANGELOG entry

```markdown
### Deprecated
- `Button` `:type` parameter - Use `:variant` instead. Will be removed in v3.0.0.
```

## Backward Compatibility

The parameter still works but shows a warning. Consumers should update:

```erb
<%# Before %>
<%= render Bali::Button::Component.new(type: :primary) { "Click" } %>

<%# After %>
<%= render Bali::Button::Component.new(variant: :primary) { "Click" } %>
```
```

## Deprecation Checklist

When deprecating:

- [ ] Add deprecation warning in code
- [ ] Update preview with deprecation label
- [ ] Create migration guide
- [ ] Update deprecations log
- [ ] Prepare CHANGELOG entry
- [ ] Update docs/api if generated
- [ ] Notify consumers (if major component)
- [ ] Set reminder for removal

## Finding Deprecated Usage

```bash
# Find deprecated component usage
grep -r "Bali::Box" --include="*.rb" --include="*.erb" app/

# Find deprecated parameter usage
grep -r "type:" --include="*.erb" app/ | grep "Button"
```
