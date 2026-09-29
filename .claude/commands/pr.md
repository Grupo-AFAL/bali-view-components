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

## The first line of the body is not optional

**The body opens with `Closes #NNN`, in English.** GitHub only closes the issue on
merge with `Closes` / `Fixes` / `Resolves`; the Spanish verb reads just as well and
closes nothing, and the issue stays open with nobody the wiser.
`.claude/hooks/pr-closes-keyword.sh` is a PreToolUse gate, not a reminder: a command
whose body closes the issue in Spanish does not run at all.

Everything after that line is Spanish — the body, like the CHANGELOG and the commit
message, is prose for the team. The code, the identifiers and the tests are English.
See "Comments, and the language everything is written in" in `.claude/CLAUDE.md`.

## Workflow

### Step 1: Pre-flight Checks

```bash
# Ensure all tests pass
bin/rails test test/bali/components/[component]_test.rb

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
Closes #NNN

## Resumen

Qué cambia en **ComponentName** y por qué.

## Cambios

- [Lista de los cambios]

## Verificación

- [ ] Las pruebas pasan
- [ ] El preview de Lookbook renderiza
- [ ] Revisión visual hecha

## Capturas

[Antes/después si el cambio es visual]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

A PR that closes no issue simply has no first line — do not invent an issue number.

## PR Template

```markdown
Closes #NNN

## Resumen

Qué cambia en **[ComponentName]** y por qué.

## Cambios

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

### Tests (`test/bali/components/[name]_test.rb`)
- [ ] Updated class expectations
- [ ] Added tests for new features
- [ ] All tests passing

## Verificación

- [x] `bin/rails test test/bali/components/[name]_test.rb` pasa
- [x] `bundle exec rubocop app/components/bali/[name]/` pasa
- [x] El preview de Lookbook renderiza

## Capturas

[Capturas si el cambio es visual; si no, "N/A"]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Example Execution

```
User: /pr --component Button

AI: Creating PR for Button changes...

## Pre-flight Checks

```bash
bin/rails test test/bali/components/button_test.rb
```
✓ 46 runs, 69 assertions, 0 failures, 0 errors, 0 skips

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
 test/bali/components/button_test.rb           | 28 +++++-----
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
