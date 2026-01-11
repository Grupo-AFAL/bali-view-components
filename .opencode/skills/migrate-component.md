---
description: Migrate a Bali ViewComponent from Bulma CSS to DaisyUI
---

# Migrate Component to DaisyUI

You are migrating a Bali ViewComponent from Bulma CSS to DaisyUI/Tailwind CSS.

## Instructions

1. First, read the DaisyUI expert skill at `.opencode/skills/daisyui-expert.md`
2. Find the component to migrate in `app/components/bali/{component}/`
3. Read all files: `component.rb`, `component.html.erb`, `index.scss`, `preview.rb`
4. **Check DaisyUI documentation for ALL available variations** of the target component:
   - Sizes (xs, sm, md, lg, xl)
   - Colors (neutral, primary, secondary, accent, info, success, warning, error)
   - Styles (outline, soft, dash, ghost, glass, etc.)
   - States (active, disabled, loading, etc.)
5. Use the Bulma → DaisyUI mapping tables from the skill
6. Update the component.rb:
   - Create SIZE_MAP, COLOR_MAP, STYLE_MAP constants as needed
   - Add new parameters for DaisyUI-specific variations (e.g., `style:`)
   - Keep backward compatibility aliases for old Bulma values
7. Update preview.rb:
   - Update `@param` annotations to show ALL DaisyUI options
   - Use DaisyUI naming (xs/sm/md/lg/xl, not small/medium/large)
8. Minimize or remove custom SCSS (prefer Tailwind utilities)
9. Update the spec file to expect new class names
10. Run tests to verify: `bundle exec rspec spec/bali/components/{component}_spec.rb`
11. Verify visually in Lookbook at http://localhost:3001/lookbook

## Key Mapping Rules

- `is-{color}` → `{component}-{color}` (e.g., `is-primary` → `btn-primary`)
- `is-{size}` → `{component}-{size}` (e.g., `is-small` → `btn-sm`)
- `is-danger` → `{component}-error` (DaisyUI uses "error" not "danger")
- `is-light` → `{component}-ghost` or `{component}-outline`
- `is-active` → context-specific (e.g., `tab-active`, `modal-open`)

## DaisyUI Style Modifiers (MUST CHECK FOR EACH COMPONENT)

Many DaisyUI components support these style modifiers. Check the official docs for each:

| Modifier | Class Pattern | Description |
|----------|---------------|-------------|
| outline | `{component}-outline` | Border only, transparent background |
| soft | `{component}-soft` | Lighter/muted color variant |
| dash | `{component}-dash` | Dashed border style |
| ghost | `{component}-ghost` | Minimal styling, no background |
| glass | `{component}-glass` | Glassmorphism effect |
| wide | `{component}-wide` | Wider horizontal padding |
| block | `{component}-block` | Full width |
| circle | `{component}-circle` | Circular shape |
| square | `{component}-square` | Square shape |

**Always check the DaisyUI docs** for the specific component to see which modifiers apply.

## Component Argument

The component name should be provided as an argument: `/migrate-component {component_name}`

If no component name provided, ask the user which component to migrate.
