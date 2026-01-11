# Create Pull Request

Create a PR for component migration or new component work.

## Usage

```
/pr $ARGUMENTS
```

Where `$ARGUMENTS` is:
- `--component [name]` - PR for component migration/creation
- `--base [branch]` - Base branch (default: `tailwind-migration`)
- `--draft` - Create as draft PR

## Workflow

### Step 1: Pre-flight Checks

```bash
# Ensure all tests pass
bundle exec rspec spec/components/bali/[component]/

# Ensure Rubocop passes
bundle exec rubocop app/components/bali/[component]/

# Check for uncommitted changes
git status
```

### Step 2: Review Changes

```bash
# Show what will be in the PR
git diff tailwind-migration...HEAD --stat
git log tailwind-migration...HEAD --oneline
```

### Step 3: Push and Create PR

```bash
# Push current branch
git push -u origin [branch-name]

# Create PR
gh pr create \
  --base tailwind-migration \
  --title "[Migration] ComponentName: Bulma → DaisyUI" \
  --body "$(cat <<'EOF'
## Summary

Migrates the **ComponentName** component from Bulma to Tailwind + DaisyUI.

## Changes

- Updated variant/size mappings to DaisyUI classes
- Restructured template for DaisyUI patterns
- Updated Lookbook preview
- Updated RSpec tests

## DaisyUI Classes Used

- `btn`, `btn-primary`, `btn-sm`, etc.

## Testing

- [ ] All RSpec tests pass
- [ ] Lookbook preview renders correctly
- [ ] Visual regression check complete

## Screenshots

[Add before/after if significant visual changes]
EOF
)"
```

## PR Template for Migration

```markdown
## Summary

Migrates **[ComponentName]** from Bulma to Tailwind + DaisyUI.

## Changes

### Ruby Component (`component.rb`)
- [ ] Updated VARIANTS constant with DaisyUI classes
- [ ] Updated SIZES constant with DaisyUI classes  
- [ ] Added new variants (if applicable)
- [ ] Used `class_names` helper

### Template (`component.html.erb`)
- [ ] Applied DaisyUI semantic classes
- [ ] Restructured for DaisyUI patterns
- [ ] Removed Bulma-specific markup

### Styles (`component.scss`)
- [ ] Removed Bulma overrides
- [ ] Kept only custom animations/states
- [ ] Or deleted if no longer needed

### Preview (`preview.rb`)
- [ ] Updated variant options
- [ ] Updated size options
- [ ] Added new examples for new features

### Tests (`component_spec.rb`)
- [ ] Updated class expectations
- [ ] Added tests for new variants
- [ ] All tests passing

## Class Mapping Applied

| Before (Bulma) | After (DaisyUI) |
|----------------|-----------------|
| `button is-primary` | `btn btn-primary` |
| ... | ... |

## Verification

- [x] `bundle exec rspec spec/components/bali/[name]/` passes
- [x] `bundle exec rubocop app/components/bali/[name]/` passes
- [x] Lookbook preview renders correctly
- [ ] Visual comparison with production (if applicable)

## Screenshots

### Before
[Screenshot or "N/A if no visual change"]

### After
[Screenshot or "N/A if no visual change"]
```

## Example Execution

```
User: /pr --component Button

AI: Creating PR for Button migration...

## Pre-flight Checks

```bash
bundle exec rspec spec/components/bali/button/
```
✓ 12 examples, 0 failures

```bash
bundle exec rubocop app/components/bali/button/
```
✓ No offenses detected

## Changes Summary

```
git diff tailwind-migration...HEAD --stat

 app/components/bali/button/component.rb       | 45 ++++++++--------
 app/components/bali/button/component.html.erb |  8 ++-
 app/components/bali/button/preview.rb         | 32 ++++++-----
 spec/components/bali/button/component_spec.rb | 28 +++++-----
 4 files changed, 65 insertions(+), 48 deletions(-)
```

## Creating PR

```bash
git push -u origin tailwind-migration/button
gh pr create --base tailwind-migration ...
```

✓ PR created: https://github.com/Grupo-AFAL/bali/pull/XXX

## Next Steps

1. Request review from team
2. Address any feedback
3. Merge to `tailwind-migration` base branch
4. Continue with next component: `/migrate-component Card`
```

## Merge Strategy

When PRs are ready:

1. **Individual component PRs** merge into `tailwind-migration`
2. After several components migrated, create **integration PR** from `tailwind-migration` → `main`
3. Integration PR should include:
   - README updates
   - CHANGELOG entry
   - Version bump
   - Migration guide for consumers
