# Release Command

Cuts a release of Bali (one git tag, two packages: the gem and the npm package) through a
**release PR**, the way v3.3.1, v3.4.0 and v3.5.0 were cut — or tags one whose bump rode in a
feature PR, like v3.6.0. Nothing is pushed to `main` directly, and no hook is skipped. The procedure and its reasons live in
`docs/guides/release-channels.md` (§ Cutting a release, § Host steps); this command is the
checklist.

## Usage

```
/release patch|minor|major|X.Y.Z [--dry-run]
```

`--dry-run` prints the version, the six files and the commits it would ship, and changes
nothing.

## 0. Check the real state first

A feature PR sometimes brings the bump and its CHANGELOG section with it. Before bumping
anything:

```bash
git fetch origin && git checkout main && git pull --ff-only
cat lib/bali/version.rb && grep '"version"' package.json
git tag -l "v*" --sort=-v:refname | head -3
sed -n '1,15p' CHANGELOG.md
```

If the version is already bumped in all six files and its tag does not exist, the release
is step 5 alone, on the merge commit of the PR that brought the bump. Whatever sits under
`[Unreleased]` after that merge belongs to the next release.

## 1. Choose the version

`git log $(git describe --tags --abbrev=0)..origin/main --oneline` and the `[Unreleased]`
section decide it:

- **patch** — fixes, docs, dependency bumps.
- **minor** — new components, new options, deprecations (not removals).
- **major** — a removed or renamed public API, a raised Ruby/Rails/daisyUI floor.

## 2. Bump the six files on `release/vX.Y.Z`

```bash
git checkout -b release/vX.Y.Z
```

| File | Change |
|---|---|
| `lib/bali/version.rb` | `VERSION = "X.Y.Z"` |
| `package.json` | `"version": "X.Y.Z"` (npm spelling for pre-releases: `X.Y.0-beta.N`) |
| `Gemfile.lock` | `bundle install` — never by hand |
| `README.md` | install snippet `tag: "vX.Y.Z"` |
| `docs/guides/installation.md` | `tag: "vX.Y.Z"`, the npm pin `#vX.Y.Z` and the transcript `=> "X.Y.Z"` |
| `CHANGELOG.md` | `## [Unreleased]` → `## [vX.Y.Z] - YYYY-MM-DD`; merge repeated `###` headings; leave an empty `## [Unreleased]` on top |

Before touching the CHANGELOG, check that every entry since the last tag landed under
`[Unreleased]` and not inside an already-published version: the hunks of
`git diff -U0 $(git describe --tags --abbrev=0) origin/main -- CHANGELOG.md | grep '^@@'`
should all sit above the first `grep -n '^## \[v' CHANGELOG.md` (dated notes added on
purpose to a released entry are the exception).

## 3. Verify

```bash
bin/rails test          # includes the install-pin contract test
bundle exec rubocop
```

Commit as `release: vX.Y.Z` (Spanish body, the files and why), push, and open the PR. Its
body opens with no `Closes` unless an issue asked for the release.

## 4. The PR body

In Spanish, with these sections:

1. **Qué incluye** — commits and PRs since the last tag, entries per type.
2. **Qué tiene que hacer un anfitrión al subir**, opening with the coverage block:

   > Estos pasos cubren una app en **vA.B.C**. Si vienes de más atrás, aplica también, de la
   > más vieja a la más nueva: [vA.B.C](…), […].

   List every release since the oldest version an app of the group is still on, oldest
   first, with absolute links. Each step cites its CHANGELOG line and carries the exact
   `git grep … origin/main -- <glob>` that measures it (see § Host steps in the guide).
3. **Cambios del release** — the six files.
4. **Verificación** — the commands above, with their numbers.

## 5. After the merge: tag and publish

```bash
sha=$(gh api repos/Grupo-AFAL/bali-view-components/pulls/<N> --jq .merge_commit_sha)
git fetch origin && git tag -a vX.Y.Z "$sha" -m "Release vX.Y.Z" && git push origin vX.Y.Z
gh release create vX.Y.Z --title "vX.Y.Z" --notes-file <notes> --verify-tag
```

The notes are the CHANGELOG section plus the install pins:

```ruby
gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "vX.Y.Z"
```

```json
"bali-view-components": "github:Grupo-AFAL/bali-view-components#vX.Y.Z"
```

Tag the merge commit of the PR that brought the bump, not `main`'s HEAD, which may carry
later work. Tag right after the merge: until then the install pins in `main` name a ref that
does not exist. `gh release list` goes through GraphQL and can hit its rate limit; `gh release create`
and `gh api repos/Grupo-AFAL/bali-view-components/releases` are REST.

## Errors worth knowing

- **Exit 16 at `setup-ruby` in every Ruby workflow** — the bump went without the regenerated
  `Gemfile.lock`.
- **`test_the_install_instructions_pin_this_version` fails** — one of the three install pins
  in `README.md` / `installation.md` still names the previous version.
- **The merge is blocked with all checks green** — `main` requires one approving review, and
  GitHub does not let the author approve their own PR.
