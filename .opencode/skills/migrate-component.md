---
description: Migrate a Bali ViewComponent from Bulma CSS to DaisyUI
---

# Migrate Component to DaisyUI

You are migrating a Bali ViewComponent from Bulma CSS to DaisyUI/Tailwind CSS.

## Reference Documents

**IMPORTANT**: Before starting, read these shared reference docs:

1. `docs/guides/migration-v2-to-v3.md` - The Bulma to daisyUI class mappings
2. `docs/reference/component-patterns.md` - Standard component patterns
3. `docs/guides/accessibility.md` - A11y requirements for components

## Quick Start

1. Find the component in `app/components/bali/{component}/`
2. Read all files: `component.rb`, `component.html.erb`, `index.css`, `preview.rb`
3. Use the mapping tables from `docs/guides/migration-v2-to-v3.md`
4. Follow patterns from `docs/reference/component-patterns.md`

## Key Mapping Rules

- `is-{color}` -> `{component}-{color}` (e.g., `is-primary` -> `btn-primary`)
- `is-{size}` -> `{component}-{size}` (e.g., `is-small` -> `btn-sm`)
- `is-danger` -> `{component}-error` (DaisyUI uses "error" not "danger")
- `is-light` -> `{component}-ghost` or `{component}-outline`

## Workflow

1. **Read component files** - Understand current implementation
2. **Map classes** - Use `docs/guides/migration-v2-to-v3.md`
3. **Update component.rb** - Change VARIANTS, SIZES constants
4. **Update preview.rb** - Use DaisyUI param values (xs/sm/md/lg/xl)
5. **Minimize CSS** - Prefer Tailwind utilities; the repo has no SCSS, styles are
   plain `.css` in the component's `index.css`
6. **Update tests** - Expect new class names
7. **Verify** - `bin/rails test test/bali/components/{component}_test.rb`
8. **Visual check** - Lookbook at http://localhost:3001/lookbook

## Component Argument

The component name should be provided as an argument: `/migrate-component {component_name}`

If no component name provided, ask the user which component to migrate.

## Full Documentation

`docs/reference/component-patterns.md` — the patterns, taken from the code that ships.
There is no `.claude/commands/migrate-component.md`; the Claude Code commands that do
exist are listed by `ls .claude/commands/`.
