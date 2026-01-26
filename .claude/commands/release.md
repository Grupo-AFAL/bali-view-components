# Release Command

Automate the release process for the Bali ViewComponents gem.

## Usage

```
/release $ARGUMENTS
```

Where `$ARGUMENTS` is:
- `patch` - Bump patch version (1.0.0 → 1.0.1)
- `minor` - Bump minor version (1.0.0 → 1.1.0)
- `major` - Bump major version (1.0.0 → 2.0.0)
- `--dry-run` - Show what would happen without making changes
- `--skip-tests` - Skip test suite (not recommended)
- `--skip-changelog` - Skip changelog generation
- `--no-tag` - Don't create git tag
- `--no-push` - Don't push to remote

## Prerequisites

Before running release:
- Working directory must be clean (no uncommitted changes)
- Must be on `main` or `tailwind-migration` branch
- All tests must pass

## Workflow

### Step 1: Pre-Release Checks

```bash
# Check git status
git status --porcelain

# Check current branch
git branch --show-current

# Run full test suite
bundle exec rspec
```

If any check fails, abort with explanation.

### Step 2: Determine New Version

Read current version from `lib/bali/version.rb`:

```ruby
module Bali
  VERSION = "1.2.3"
end
```

Calculate new version based on argument:
- `patch`: 1.2.3 → 1.2.4
- `minor`: 1.2.3 → 1.3.0
- `major`: 1.2.3 → 2.0.0

### Step 3: Update Version File

```ruby
# lib/bali/version.rb
module Bali
  VERSION = "[NEW_VERSION]"
end
```

### Step 4: Update CHANGELOG

Append new version section based on commits since last tag:

```bash
# Get commits since last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

Generate changelog entry:

```markdown
## [NEW_VERSION] - YYYY-MM-DD

### Added
- [Feature from commit messages]

### Changed
- [Change from commit messages]

### Fixed
- [Fix from commit messages]

### Migration
- [Migration-related changes]
```

**Commit Message Parsing:**
- `feat:` or `add:` → Added
- `fix:` → Fixed
- `change:` or `update:` → Changed
- `migrate:` → Migration
- `docs:` → Documentation
- `test:` → (skip, internal)
- `chore:` → (skip, internal)

### Step 5: Update Gemfile.lock

```bash
bundle install
```

### Step 6: Commit Version Bump

```bash
git add lib/bali/version.rb CHANGELOG.md Gemfile.lock
git commit -m "Release v[NEW_VERSION]"
```

### Step 7: Create Git Tag

```bash
git tag -a v[NEW_VERSION] -m "Release v[NEW_VERSION]"
```

### Step 8: Push to Remote

```bash
git push origin [BRANCH]
git push origin v[NEW_VERSION]
```

### Step 9: Build Gem (Optional)

```bash
gem build bali_view_components.gemspec
```

### Step 10: Generate Release Summary

```markdown
# Release v[NEW_VERSION]

## Changes

[CHANGELOG entry]

## Installation

Update your Gemfile:

```ruby
gem "bali_view_components", "~> [NEW_VERSION]"
```

Then run:

```bash
bundle update bali_view_components
```

## Migration Notes

[Any breaking changes or migration steps]

## Full Changelog

[Link to CHANGELOG.md]
```

## Version Bump Rules

### Patch (X.X.PATCH)

Use for:
- Bug fixes
- Performance improvements
- Documentation updates
- Internal refactoring (no API changes)

### Minor (X.MINOR.0)

Use for:
- New components
- New features on existing components
- New optional parameters
- Deprecation notices (not removals)

### Major (MAJOR.0.0)

Use for:
- Breaking API changes
- Removed components
- Removed parameters
- Ruby/Rails version requirement changes
- CSS framework migration (Bulma → DaisyUI)

## Example Execution

### Dry Run

```
User: /release minor --dry-run

AI: Checking release prerequisites...

✓ Git working directory is clean
✓ On branch: main
✓ Running tests...
✓ All 342 examples passed

Current version: 1.2.3
New version: 1.3.0

## Changes since v1.2.3

### Added
- Migrate Button component to DaisyUI (a89f03a)
- Add Tooltip component (b12c45d)

### Changed
- Update Card component slots API (c23d56e)

### Fixed
- Fix Dropdown keyboard navigation (d34e67f)
- Fix Modal focus trap (e45f78g)

## Files that would be modified

- lib/bali/version.rb (1.2.3 → 1.3.0)
- CHANGELOG.md (new section added)
- Gemfile.lock (version updated)

## Git operations that would run

```bash
git add lib/bali/version.rb CHANGELOG.md Gemfile.lock
git commit -m "Release v1.3.0"
git tag -a v1.3.0 -m "Release v1.3.0"
git push origin main
git push origin v1.3.0
```

This is a dry run. No changes were made.
To proceed with release, run: /release minor
```

### Actual Release

```
User: /release minor

AI: Starting release process...

## Pre-Release Checks

✓ Git working directory is clean
✓ On branch: main
✓ Running tests... (342 examples, 0 failures)

## Version Update

Current: 1.2.3
New: 1.3.0

Updating lib/bali/version.rb...
✓ Version updated

## Changelog Update

Analyzing commits since v1.2.3...
Found 12 commits

Updating CHANGELOG.md...
✓ Changelog updated

## Bundle Update

Running bundle install...
✓ Gemfile.lock updated

## Git Commit

```bash
git add lib/bali/version.rb CHANGELOG.md Gemfile.lock
git commit -m "Release v1.3.0"
```
✓ Committed

## Git Tag

```bash
git tag -a v1.3.0 -m "Release v1.3.0"
```
✓ Tagged

## Push to Remote

```bash
git push origin main
git push origin v1.3.0
```
✓ Pushed

---

# Release v1.3.0 Complete!

## Summary

- Version: 1.2.3 → 1.3.0
- Commits included: 12
- New features: 2
- Bug fixes: 2

## Next Steps

1. Create GitHub release with notes (optional)
2. Notify team of new release
3. Update dependent applications

## Installation

```ruby
gem "bali_view_components", "~> 1.3.0"
```
```

## Error Handling

### Uncommitted Changes

```
ERROR: Working directory has uncommitted changes.

Please commit or stash your changes before releasing:

Modified files:
- app/components/bali/button/component.rb
- spec/bali/components/button_spec.rb

Options:
1. Commit changes: git add . && git commit -m "..."
2. Stash changes: git stash
3. Discard changes: git checkout .

Then run /release again.
```

### Test Failures

```
ERROR: Test suite failed. Cannot release with failing tests.

Failures:
  1) Bali::Button::Component renders primary variant
     Expected: have_css(".btn-primary")
     Got: have_css(".is-primary")

Fix the failing tests before releasing.
Run: bundle exec rspec --only-failures
```

### Wrong Branch

```
WARNING: You are on branch 'feature/new-button'.

Releases should typically be made from 'main' or 'tailwind-migration'.

Options:
1. Switch to main: git checkout main
2. Proceed anyway: /release minor --force

Proceeding on a feature branch is not recommended.
```

## Integration with CI/CD

For automated releases via GitHub Actions:

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bundle exec rspec
      - run: gem build bali_view_components.gemspec
      # Add publishing steps if needed
```
