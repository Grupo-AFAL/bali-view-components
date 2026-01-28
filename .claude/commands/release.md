# Release Command

Automate the release process for the Bali ViewComponents library (Ruby gem + npm package).

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
- Must be on `main` branch
- All tests must pass

## Version Files

This library has **two version files** that must stay in sync:

| File | Purpose |
|------|---------|
| `lib/bali/version.rb` | Ruby gem version |
| `package.json` | npm package version |

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

Verify `package.json` has the same version. If they differ, abort with error.

Calculate new version based on argument:
- `patch`: 1.2.3 → 1.2.4
- `minor`: 1.2.3 → 1.3.0
- `major`: 1.2.3 → 2.0.0

### Step 3: Update Version Files

Update **both** version files:

```ruby
# lib/bali/version.rb
module Bali
  VERSION = "[NEW_VERSION]"
end
```

```json
// package.json
{
  "version": "[NEW_VERSION]",
  ...
}
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

### Dependencies
- [Dependency updates]
```

**Commit Message Parsing:**
- `feat:` or `add:` → Added
- `fix:` → Fixed
- `change:` or `update:` → Changed
- `deps:` or dependency updates → Dependencies
- `docs:` → Documentation (include if significant)
- `test:` → (skip, internal)
- `chore:` → (skip, internal)

### Step 5: Update Lock Files

Update **both** lock files:

```bash
# Ruby dependencies
bundle install

# JavaScript dependencies
yarn install
# or: npm install
```

### Step 6: Commit Version Bump

```bash
git add lib/bali/version.rb package.json CHANGELOG.md Gemfile.lock yarn.lock
git commit -m "Release v[NEW_VERSION]

Changes:
- [Brief summary of changes]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

### Step 7: Create Git Tag

```bash
git tag -a v[NEW_VERSION] -m "Release v[NEW_VERSION]"
```

### Step 8: Push to Remote

```bash
git push origin main --no-verify
git push origin v[NEW_VERSION]
```

Note: Use `--no-verify` to skip pre-push hooks since tests already passed.

### Step 9: Create GitHub Release

Create a GitHub release with the changelog entry as release notes:

```bash
gh release create v[NEW_VERSION] --title "v[NEW_VERSION]" --notes "[CHANGELOG_ENTRY]"
```

The release notes should include:
- Changes section (from CHANGELOG)
- Installation instructions for both Ruby and JavaScript

Example:
```bash
gh release create v2.0.1 --title "v2.0.1" --notes "$(cat <<'EOF'
## Changes

### Changed
- [Changes from CHANGELOG]

### Fixed
- [Fixes from CHANGELOG]

## Installation

### Ruby (Gemfile)

\`\`\`ruby
gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v2.0.1"
\`\`\`

### JavaScript (package.json)

\`\`\`json
"bali-view-components": "github:Grupo-AFAL/bali-view-components#v2.0.1"
\`\`\`
EOF
)"
```

### Step 10: Generate Release Summary

```markdown
# Release v[NEW_VERSION] Complete!

## Changes

[CHANGELOG entry]

## Installation

### Ruby (Gemfile)

```ruby
gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v[NEW_VERSION]"
```

```bash
bundle update bali_view_components
```

### JavaScript (package.json)

```json
"bali-view-components": "github:Grupo-AFAL/bali-view-components#v[NEW_VERSION]"
```

```bash
yarn upgrade bali-view-components
```

## Next Steps

1. Create GitHub release with notes (optional)
2. Notify team of new release
3. Update dependent applications
```

## Version Bump Rules

### Patch (X.X.PATCH)

Use for:
- Bug fixes
- Performance improvements
- Documentation updates
- Internal refactoring (no API changes)
- Dependency updates (non-breaking)

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
User: /release patch --dry-run

AI: Checking release prerequisites...

✓ Git working directory is clean
✓ On branch: main
✓ Running tests... (2171 examples, 0 failures)
✓ Version files in sync: 2.0.0

Current version: 2.0.0
New version: 2.0.1

## Changes since v2.0.0

### Changed
- Consolidate AdvancedFilters into Filters component

### Fixed
- Fix search persistence when clearing search text

### Dependencies
- Add lucide-rails as runtime dependency

## Files that would be modified

- lib/bali/version.rb (2.0.0 → 2.0.1)
- package.json (2.0.0 → 2.0.1)
- CHANGELOG.md (new section added)
- Gemfile.lock (version updated)
- yarn.lock (no changes expected)

## Operations that would run

1. Update version files
2. Update CHANGELOG.md
3. Run `bundle install`
4. Run `yarn install`
5. Commit: "Release v2.0.1"
6. Tag: v2.0.1
7. Push to origin/main
8. Push tag v2.0.1
9. Create GitHub release with notes

This is a dry run. No changes were made.
To proceed with release, run: /release patch
```

### Actual Release

```
User: /release patch

AI: Starting release process...

## Pre-Release Checks

✓ Git working directory is clean
✓ On branch: main
✓ Running tests... (2171 examples, 0 failures)
✓ Version files in sync: 2.0.0

## Version Update

Current: 2.0.0
New: 2.0.1

Updating lib/bali/version.rb... ✓
Updating package.json... ✓

## Changelog Update

Analyzing commits since v2.0.0...
Found 5 commits

Updating CHANGELOG.md... ✓

## Lock File Updates

Running bundle install... ✓
Running yarn install... ✓

## Git Commit

✓ Committed: Release v2.0.1

## Git Tag

✓ Tagged: v2.0.1

## Push to Remote

✓ Pushed main branch
✓ Pushed tag v2.0.1

## GitHub Release

✓ Created release: https://github.com/Grupo-AFAL/bali-view-components/releases/tag/v2.0.1

---

# Release v2.0.1 Complete!

## Installation

### Ruby (Gemfile)

```ruby
gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v2.0.1"
```

### JavaScript (package.json)

```json
"bali-view-components": "github:Grupo-AFAL/bali-view-components#v2.0.1"
```
```

## Error Handling

### Version Mismatch

```
ERROR: Version files are out of sync!

- lib/bali/version.rb: 2.0.0
- package.json: 1.9.0

Please sync versions before releasing:
1. Decide which version is correct
2. Update both files to match
3. Commit the fix
4. Run /release again
```

### Uncommitted Changes

```
ERROR: Working directory has uncommitted changes.

Modified files:
- app/components/bali/button/component.rb

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

### Protected Branch

```
WARNING: Cannot push directly to main (protected branch).

The release commit and tag have been created locally.
To complete the release:

1. Push via PR or with admin bypass
2. Then push the tag: git push origin v2.0.1
```

## Manual Release Steps

If you need to release manually (e.g., automation failed partway):

```bash
# 1. Update versions
# Edit lib/bali/version.rb
# Edit package.json

# 2. Update lock files
bundle install
yarn install

# 3. Update CHANGELOG.md manually

# 4. Commit
git add lib/bali/version.rb package.json CHANGELOG.md Gemfile.lock yarn.lock
git commit -m "Release v[VERSION]"

# 5. Tag
git tag -a v[VERSION] -m "Release v[VERSION]"

# 6. Push
git push origin main --no-verify
git push origin v[VERSION]
```

## CI/CD Integration

For automated tag creation via GitHub Actions:

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - run: bundle exec rspec

  create-release:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          generate_release_notes: true
```
