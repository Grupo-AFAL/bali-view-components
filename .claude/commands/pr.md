# Create Pull Request

Create a PR for component changes or new component work.

## Usage

```
/pr $ARGUMENTS
```

Where `$ARGUMENTS` is:
- `--component [name]` - PR for component changes/creation
- `--base [branch]` - Base branch (default: `main`)
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
git diff main...HEAD --stat
git log main...HEAD --oneline
```

### Step 3: Push and Create PR

```bash
# Push current branch
git push -u origin [branch-name]

# Create PR
gh pr create \
  --base main \
  --title "[ComponentName] Brief description of changes" \
  --body "$(cat <<'EOF'
## Summary

Brief description of changes to **ComponentName**.

## Changes

- [List specific changes made]

## Testing

- [ ] All tests pass
- [ ] Lookbook preview renders correctly
- [ ] Visual regression check complete

## Screenshots

[Add before/after if significant visual changes]
EOF
)"
```

## PR Template

```markdown
## Summary

Brief description of changes to **[ComponentName]**.

## Changes

### Ruby Component (`component.rb`)
- [ ] Updated constants or class mappings
- [ ] Used `class_names` helper
- [ ] Added new variants/features (if applicable)

### Template (`component.html.erb`)
- [ ] Applied DaisyUI semantic classes
- [ ] Minimal template logic

### Preview (`preview.rb`)
- [ ] Updated variant options
- [ ] Added new examples for new features

### Tests (`component_spec.rb`)
- [ ] Updated class expectations
- [ ] Added tests for new features
- [ ] All tests passing

## Verification

- [x] `bundle exec rspec spec/components/bali/[name]/` passes
- [x] `bundle exec rubocop app/components/bali/[name]/` passes
- [x] Lookbook preview renders correctly

## Screenshots

[Screenshots if significant visual changes, otherwise "N/A"]
```

## Example Execution

```
User: /pr --component Button

AI: Creating PR for Button changes...

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
git diff main...HEAD --stat

 app/components/bali/button/component.rb       | 45 ++++++++--------
 app/components/bali/button/component.html.erb |  8 ++-
 app/components/bali/button/preview.rb         | 32 ++++++-----
 spec/components/bali/button/component_spec.rb | 28 +++++-----
 4 files changed, 65 insertions(+), 48 deletions(-)
```

## Creating PR

```bash
git push -u origin feature/button-improvements
gh pr create --base main ...
```

✓ PR created: https://github.com/Grupo-AFAL/bali/pull/XXX

## Next Steps

1. Request review from team
2. Address any feedback
3. Merge to `main`
```

## Merge Strategy

PRs merge directly into `main`. For larger changes:
- Include README updates
- Add CHANGELOG entry
- Consider version bump if API changes
