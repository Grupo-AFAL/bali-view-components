# Review Component Code

Review Bali ViewComponent code against quality standards.

## Usage

```
/review $ARGUMENTS
```

Where `$ARGUMENTS` is:
- Component name (e.g., `Button`, `Card`)
- File path (e.g., `app/components/bali/button/component.rb`)
- `--staged` - Review staged git changes
- `--branch` - Review all changes on current branch vs tailwind-migration base

## Workflow

### Step 1: Identify Files to Review

Based on argument:

1. **Component name**: Find all files in `app/components/bali/[name]/`
2. **File path**: Review that specific file
3. **--staged**: Get files from `git diff --staged --name-only`
4. **--branch**: Get files from `git diff tailwind-migration...HEAD --name-only`

### Step 2: Run Automated Checks

```bash
# Run Rubocop on component files
bundle exec rubocop app/components/bali/[name]/

# Run component specs
bundle exec rspec spec/components/bali/[name]/
```

### Step 3: Invoke DHH Reviewer

Use the `dhh-code-reviewer` agent to analyze:
- Component class design
- API quality
- Template cleanliness
- DaisyUI usage
- Test coverage

### Step 4: Generate Report

```markdown
# Code Review: [Component]

## Summary
- Files reviewed: X
- Critical issues: X
- Improvements suggested: X
- Tests: [passing/failing]

## Automated Checks

### Rubocop
[List any offenses]

### RSpec
[Test results]

## DHH Review

### Critical Issues
[Must fix]

### Suggested Improvements
[Should fix]

### What Works Well
[Positive observations]

## Recommended Actions
1. [Priority fix]
2. [Next fix]
```

## Review Checklist

### Component Class
- [ ] Uses `class_names` for conditional classes
- [ ] Constants for variants/sizes (frozen)
- [ ] Sensible defaults for all params
- [ ] `**options` for HTML attributes passthrough
- [ ] Private methods for computed values

### Template
- [ ] Minimal logic (no complex conditionals)
- [ ] DaisyUI semantic classes
- [ ] `tag.attributes` for options passthrough
- [ ] Proper slot usage

### Component Composition
- [ ] Uses existing Bali components (Card, Tag, Button, etc.) instead of raw HTML
- [ ] No raw `<div class="card">`, `<span class="badge">`, `<button class="btn">` when Bali equivalents exist
- [ ] Check Component Catalog in CLAUDE.md for available components

### Icons
- [ ] All icons exist in `app/components/bali/icon/options.rb`
- [ ] No guessed icon names (eye, pencil, building are NOT available)
- [ ] Use correct alternatives: `expand` not `eye`, `edit` not `pencil`, `business` not `building`

### Tests
- [ ] Tests all variants
- [ ] Tests all sizes
- [ ] Tests slot content
- [ ] Tests edge cases (nil, empty)

### Preview
- [ ] Uses `@param` annotations for interactive testing (avoid separate methods for each variant)
- [ ] Only creates separate preview methods when significantly different markup is needed
- [ ] Includes Markdown comments for consumer-relevant info (dependencies, gotchas, code examples)
- [ ] Notes are critical - only what helps consumers, not implementation details

## Example Execution

```
User: /review Button

AI: Reviewing Bali::Button::Component...

## Automated Checks

### Rubocop
✓ No offenses detected

### RSpec
✓ 12 examples, 0 failures

## DHH Review

### What Works Well
- Clean variant/size mappings with frozen constants
- Good use of `class_names` helper
- Sensible defaults (primary, md)

### Suggested Improvements

1. **Add outline variant combination**
   Currently outline is standalone. DaisyUI supports `btn-outline btn-primary`.
   
   ```ruby
   # Current
   outline: "btn-outline"
   
   # Better: Allow outline + color
   def button_classes
     class_names(
       "btn",
       @outline && "btn-outline",
       VARIANTS[@variant],  # Can combine with outline
       SIZES[@size]
     )
   end
   ```

2. **Consider icon support**
   Common pattern - buttons with icons.
   
   ```ruby
   def initialize(icon: nil, icon_position: :left, ...)
   ```

## Summary

Component is well-implemented. Minor enhancement opportunities.
Score: 8/10 - Rails-worthy with small improvements.
```
