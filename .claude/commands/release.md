# Release Command

Two-phase PR-based release workflow for the Bali ViewComponents library (Ruby gem + npm package).

## Usage

```
/release $ARGUMENTS
```

Where `$ARGUMENTS` is:

| Argument | Description |
|----------|-------------|
| `patch` | Start Phase 1, bump patch version after merge (1.0.0 → 1.0.1) |
| `minor` | Start Phase 1, bump minor version after merge (1.0.0 → 1.1.0) |
| `major` | Start Phase 1, bump major version after merge (1.0.0 → 2.0.0) |
| `--continue` | Run Phase 2 after PR is merged |
| `--dry-run` | Preview what would happen without making changes |
| `--skip-tests` | Skip local test run in Phase 1 |

## Workflow Overview

```
/release [patch|minor|major]
         ↓
┌─────────────────────────────────────┐
│  PHASE 1: Prepare Release PR        │
│  - Pre-checks (clean, main, tests)  │
│  - Create release/prep-* branch     │
│  - Generate CHANGELOG under         │
│    [Unreleased] header              │
│  - Commit & create PR               │
│  - Monitor CI                       │
│  - Prompt user to review & merge    │
└─────────────────────────────────────┘
         ↓ (user merges PR)
         ↓
/release --continue
         ↓
┌─────────────────────────────────────┐
│  PHASE 2: Finalize Release          │
│  - Verify PR merged                 │
│  - Calculate new version            │
│  - Bump version files               │
│  - Update lock files                │
│  - Replace [Unreleased] with        │
│    [vX.X.X] - YYYY-MM-DD            │
│  - Commit & push to main            │
│  - Create git tag                   │
│  - Create GitHub Release            │
│  - Cleanup release branch           │
└─────────────────────────────────────┘
```

## Version Files

This library has **two version files** that must stay in sync:

| File | Purpose |
|------|---------|
| `lib/bali/version.rb` | Ruby gem version |
| `package.json` | npm package version |

## State Persistence

Between Phase 1 and Phase 2, state is stored in `.release-pending.json`:

```json
{
  "bump_type": "patch",
  "pr_number": 466,
  "branch": "release/prep-20260130",
  "started_at": "2026-01-30T12:00:00Z"
}
```

This file is deleted after successful Phase 2 completion.

---

## Phase 1: Prepare Release PR

### Step 1.1: Pre-Release Checks

```bash
# Check git status is clean
git status --porcelain

# Check current branch is main
git branch --show-current

# Run full test suite (unless --skip-tests)
bundle exec rspec

# Read and verify version files are in sync
# - lib/bali/version.rb
# - package.json
```

If any check fails, abort with clear explanation.

### Step 1.2: Create Release Branch

```bash
# Generate timestamp-based branch name
BRANCH="release/prep-$(date +%Y%m%d%H%M%S)"

# Create and checkout branch
git checkout -b $BRANCH
```

### Step 1.3: Prepare CHANGELOG.md

Get commits since last tag:

```bash
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

**Commit Message Parsing:**

| Prefix | Category |
|--------|----------|
| `feat:` or `add:` | Added |
| `fix:` | Fixed |
| `change:` or `update:` | Changed |
| `deps:` or dependency updates | Dependencies |
| `docs:` | Documentation (include if significant) |
| `test:` | (skip, internal) |
| `chore:` | (skip, internal) |

Add changes under `[Unreleased]` header in CHANGELOG.md:

```markdown
## [Unreleased]

### Added
- [Feature from commit messages]

### Changed
- [Change from commit messages]

### Fixed
- [Fix from commit messages]

### Dependencies
- [Dependency updates]
```

If `[Unreleased]` header doesn't exist, create it at the top of the changelog.

### Step 1.4: Commit Changes

```bash
git add CHANGELOG.md
git commit -m "$(cat <<'EOF'
Prepare release: update CHANGELOG

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

### Step 1.5: Push Branch and Create PR

```bash
# Push branch
git push -u origin $BRANCH

# Create PR
gh pr create --title "Prepare release" --body "$(cat <<'EOF'
## Release Preparation

This PR prepares the changelog for the upcoming release.

### Changes
- Updated CHANGELOG.md with recent changes

### Next Steps
1. Review the changelog entries
2. Merge this PR
3. Run `/release --continue` to finalize the release

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

### Step 1.6: Save State

Create `.release-pending.json`:

```json
{
  "bump_type": "patch|minor|major",
  "pr_number": <PR_NUMBER>,
  "branch": "release/prep-YYYYMMDDHHMMSS",
  "started_at": "<ISO_TIMESTAMP>"
}
```

Add to `.gitignore` if not already present.

### Step 1.7: Monitor CI

```bash
# Poll PR checks status
gh pr checks <PR_NUMBER> --watch
```

Show status updates as checks run.

### Step 1.8: Prompt User

```
✓ CI passed!

Please review the PR and merge when ready:
  https://github.com/Grupo-AFAL/bali-view-components/pull/<PR_NUMBER>

After merging, run: /release --continue
```

---

## Phase 2: Finalize Release (`--continue`)

### Step 2.1: Load State

Read `.release-pending.json`. If file doesn't exist:

```
ERROR: No pending release found.

Start a release first with: /release patch|minor|major
```

### Step 2.2: Verify PR Merged

```bash
# Switch to main and pull latest
git checkout main
git pull origin main

# Verify PR is merged
gh pr view <PR_NUMBER> --json state
```

If PR is not merged:

```
ERROR: PR #<PR_NUMBER> has not been merged yet.

Please merge the PR first, then run: /release --continue
```

### Step 2.3: Calculate New Version

Read current version from `lib/bali/version.rb`:

```ruby
module Bali
  VERSION = "1.2.3"
end
```

Apply bump type:
- `patch`: 1.2.3 → 1.2.4
- `minor`: 1.2.3 → 1.3.0
- `major`: 1.2.3 → 2.0.0

### Step 2.4: Bump Version Files

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

### Step 2.5: Update Lock Files

```bash
# Ruby dependencies
bundle install

# JavaScript dependencies
yarn install
```

### Step 2.6: Finalize CHANGELOG

Replace `[Unreleased]` with version and date:

```markdown
## [v1.2.4] - 2026-01-30

### Added
...
```

### Step 2.7: Commit and Push

```bash
git add lib/bali/version.rb package.json CHANGELOG.md Gemfile.lock yarn.lock
git commit -m "$(cat <<'EOF'
Release v[NEW_VERSION]

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"

# Push directly to main
git push origin main --no-verify
```

Note: Use `--no-verify` to skip pre-push hooks since tests already passed in CI.

### Step 2.8: Create Git Tag

```bash
git tag -a v[NEW_VERSION] -m "Release v[NEW_VERSION]"
git push origin v[NEW_VERSION]
```

### Step 2.9: Create GitHub Release

```bash
gh release create v[NEW_VERSION] --title "v[NEW_VERSION]" --notes "$(cat <<'EOF'
## Changes

[CHANGELOG_ENTRY]

## Installation

### Ruby (Gemfile)

```ruby
gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v[NEW_VERSION]"
```

### JavaScript (package.json)

```json
"bali-view-components": "github:Grupo-AFAL/bali-view-components#v[NEW_VERSION]"
```
EOF
)"
```

### Step 2.10: Cleanup

```bash
# Delete remote release branch
git push origin --delete <BRANCH>

# Delete local release branch
git branch -d <BRANCH>

# Delete state file
rm .release-pending.json
```

### Step 2.11: Generate Release Summary

```markdown
# Release v[NEW_VERSION] Complete! 🎉

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

## Links

- GitHub Release: https://github.com/Grupo-AFAL/bali-view-components/releases/tag/v[NEW_VERSION]
```

---

## Dry Run Mode

When `--dry-run` is specified:

### Phase 1 Dry Run

```
Dry run: Phase 1 - Prepare Release PR

Current version: 2.0.0
Bump type: patch
New version (after merge): 2.0.1

## Pre-checks
✓ Git working directory is clean
✓ On branch: main
✓ Version files in sync: 2.0.0
⊘ Tests skipped (dry run)

## Changes since v2.0.0

### Changed
- Consolidate AdvancedFilters into Filters component

### Fixed
- Fix search persistence when clearing search text

## Operations that would run

1. Create branch: release/prep-20260130120000
2. Update CHANGELOG.md with [Unreleased] section
3. Commit: "Prepare release: update CHANGELOG"
4. Push branch
5. Create PR
6. Save state to .release-pending.json
7. Monitor CI checks

This is a dry run. No changes were made.
To proceed: /release patch
```

### Phase 2 Dry Run (--continue --dry-run)

```
Dry run: Phase 2 - Finalize Release

Pending release found:
- Bump type: patch
- PR: #466
- Branch: release/prep-20260130

## Operations that would run

1. Verify PR #466 is merged
2. Bump version: 2.0.0 → 2.0.1
3. Update lib/bali/version.rb
4. Update package.json
5. Run bundle install
6. Run yarn install
7. Replace [Unreleased] with [v2.0.1] - 2026-01-30
8. Commit: "Release v2.0.1"
9. Push to main
10. Create tag: v2.0.1
11. Create GitHub Release
12. Delete branch: release/prep-20260130

This is a dry run. No changes were made.
To proceed: /release --continue
```

---

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

### Not on Main Branch

```
ERROR: Must be on main branch to start a release.

Current branch: feature/something

Run: git checkout main
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

### PR Not Merged

```
ERROR: PR #466 has not been merged yet.

PR Status: open
URL: https://github.com/Grupo-AFAL/bali-view-components/pull/466

Please merge the PR first, then run: /release --continue
```

### No Pending Release

```
ERROR: No pending release found.

The .release-pending.json file does not exist.
This means either:
1. Phase 1 was not completed
2. The release was already finalized

To start a new release: /release patch|minor|major
```

### Stale Release State

```
WARNING: Pending release is stale.

Release started: 2026-01-15T10:00:00Z (15 days ago)
Branch: release/prep-20260115

The release branch may be outdated. Options:
1. Continue anyway: /release --continue
2. Abort and start fresh:
   - Delete .release-pending.json
   - Delete branch: git push origin --delete release/prep-20260115
   - Start over: /release patch
```

---

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

---

## Manual Recovery

If the process fails partway through:

### Phase 1 Recovery

```bash
# If branch was created but PR failed:
git push -u origin release/prep-*
gh pr create --title "Prepare release" --body "..."

# If state file wasn't saved:
echo '{"bump_type":"patch","pr_number":123,"branch":"release/prep-20260130","started_at":"2026-01-30T12:00:00Z"}' > .release-pending.json
```

### Phase 2 Recovery

```bash
# If version bump completed but tag failed:
git tag -a v2.0.1 -m "Release v2.0.1"
git push origin v2.0.1

# If tag pushed but release failed:
gh release create v2.0.1 --title "v2.0.1" --generate-notes

# If release created but cleanup failed:
git push origin --delete release/prep-20260130
git branch -d release/prep-20260130
rm .release-pending.json
```

---

## CI/CD Integration

For automated notifications when releases are tagged:

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

  notify:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Notify team
        run: echo "Release ${{ github.ref_name }} is ready!"
```
