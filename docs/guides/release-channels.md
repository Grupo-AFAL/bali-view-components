# Release channels

Bali is **not published to RubyGems or npm**. Apps consume it straight from this git
repository, so a "channel" here is nothing more than a git ref — there is no registry to
configure and no publishing step to run.

One line is maintained today:

| Channel | Branch | Tags | For |
|---|---|---|---|
| **Stable (v3.1)** | `main` | `v3.1.0`, `v3.1.1`, … | Every app in production |

When the next line of work opens (its branch named after the version it targets), it gets
a **Next** row here, its branch joins the CI filters, and it ships `beta.N` tags until its
own GA — the same cycle v3.0 and v3.1 followed.

v3.1.0 shipped on 2026-08-13: `3.1` merged into `main` and the `3.1` branch is retired —
its history lives in `main`, its changes in the `v3.1.0.beta.N` changelog entries.
v3.0.0 shipped on 2026-08-05 the same way. There is no v2 branch anymore. If a v2 app
needs a fix before it migrates, branch off the `v2.18.0` tag into a `2-x` maintenance
branch, add that branch to the CI filters, and tag `v2.18.x` from there.

## One tag, two packages

A release is one git tag over one repository that happens to contain two publishable things:
the gem (`lib/`, `app/components/`, the ERB) and the npm package (`app/frontend/`,
`app/assets/`, the Stimulus controllers and the CSS). They are not versioned separately and
they are never released separately. `lib/bali/version.rb` and the `version` field of
`package.json` carry the same number in the two spellings their registries want —
`3.1.0.beta.1` and `3.1.0-beta.1` — and a release bumps both files in the same commit.

A consuming app therefore pins the same ref twice:

```ruby
# Gemfile
gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v3.0.0"
```

```json
// package.json
"bali-view-components": "github:Grupo-AFAL/bali-view-components#v3.0.0"
```

This is not a convention anyone can opt out of, because the two halves of a component are
the Ruby that emits `data-controller="toolbar-overflow"` and the JavaScript that registers
that identifier. A Gemfile on `v3.0.0` next to a `package.json` on `v2.18.0` renders markup
no controller answers: no exception, no console error, a toolbar that simply stops
collapsing. So `bundle update bali_view_components` without the matching `yarn upgrade` is
not a smaller upgrade, it is half of one — and the half that fails silently.

`spec/dummy` is the exception that proves the rule. It consumes the package as
`"bali-view-components": "link:../.."`, so its two halves *are* the working tree and can
never disagree, which is also why a version skew can never be caught by this repo's own
tests. Only a host can hit it.

## How an app picks a channel

**Pin a tag. Never track a branch.**

```ruby
# Stable
gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v3.0.0"

# Early v3.1
gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v3.1.0.beta.1"
```

Tracking `branch: "main"` looks convenient and is the thing that bites: `bundle update`
silently pulls whatever landed since, so two apps bundling on different days run different
code, a rollback has nothing to roll back to, and the day a major merges the app inherits
every breaking change without ever opting in. A tag is immutable — upgrading becomes a
one-line, reviewable diff in the `Gemfile.lock`.

## What lands where

- **A v3 fix or feature** → `main`. Release with the normal flow, tag `v3.0.x`.
- **Anything for v3.1** → `3.1`. Behaviour changes and anything risky live here and only here.
- **`main` → `3.1`, never the reverse.** After each stable release, merge `main` into `3.1` so
  the next line does not drift. Merging `3.1` into `main` before v3.1 is ready would leak
  unfinished changes into the stable channel — which is the whole thing this split exists
  to prevent.

## CI covers both lines

Every workflow triggers on `push` and `pull_request` for **both** `main` and `3.1`. It has to:
a pre-release tag cut from a branch nothing verified is worse than no pre-release at all.

Note the quotes in `branches: [main, "3.1"]` — unquoted, YAML parses `3.1` as the number
`3.1` and the filter silently never matches.

## Cutting a v3.1 pre-release

Whenever `3.1` reaches a state an app could adopt:

1. Bump `lib/bali/version.rb` and `package.json` to the next `3.1.0.beta.N`, then run
   `bundle install` and commit the regenerated **`Gemfile.lock` in the same commit** — the
   lock records the PATH gem's version, and CI bundles with a frozen lock, so a bump
   without the lock fails every Ruby workflow with exit 16 at `setup-ruby` before a single
   test runs (measured on v3.1.0.beta.6/7: the tag itself carried the stale lock, and a
   tag cannot be fixed after the fact). Consuming apps are unaffected either way — a host
   resolves the git-sourced gem from its gemspec, never from this repo's lock — but the
   release commit should be the one CI can verify.
2. Move the `## [Unreleased]` entries under `## [v3.1.0.beta.N] - <date>`.
3. Tag `v3.1.0.beta.N` on `3.1` and publish a GitHub Release marked **pre-release**.

`3.1.0.beta.1` sorts before `3.1.0` under both RubyGems and semver rules, so the numbering
still reads correctly if this ever moves to a registry.

## Shipping a line

When the next line is complete: merge its branch into `main`, tag the final version, and
`main` becomes that line. This is exactly how v3.0.0 shipped on 2026-08-05 — a plain merge
commit, no squash, so every commit and every `v3.0.0.beta.N` tag stayed reachable from
`main`, and then the branch was retired. Point the workflow branch filters at the next
line's branch in the same PR, so CI never has a gap.

**Before that merge, prove nobody is standing under it.** The moment a line lands on
`main`, every Gemfile that still says `branch: "main"` inherits the whole release on its
next `bundle update` — no review, no opt-in, which is the exact failure the section above
exists to prevent. The check is one sweep across the org, and it has to *read* the
Gemfiles:

```bash
gh repo list Grupo-AFAL --limit 200 --no-archived --json name -q '.[].name' | while read -r repo; do
  pushed=$(gh api "repos/Grupo-AFAL/$repo" -q .pushed_at 2>/dev/null)
  for file in Gemfile package.json; do
    gh api "repos/Grupo-AFAL/$repo/contents/$file" -q .content 2>/dev/null |
      base64 -d 2>/dev/null | grep -A1 'bali.view.components' |
      grep -Eq "branch:|github.com/Grupo-AFAL/bali-view-components\"" &&
      echo "$repo  $file  unpinned  (last push $pushed)"
  done
done
```

Silence is the pass. Anything it prints has to be pinned — to a tag, or to a `ref:` SHA when
the app needs something newer than the last tag — and that pin has to be merged before the
line goes to `main`.

**Both files, because a pin on one half is not a pin.** *One tag, two packages* above explains
why they move together; this is where you find out whether they did. A `package.json` entry
written as a bare `"https://github.com/Grupo-AFAL/bali-view-components"` carries no ref at all
and resolves to whatever the default branch's HEAD is that day — the same exposure as
`branch: "main"`, in the half nobody thinks to check. Measured on 2026-08-03: `enjoykitchen`
was floating on both (pinned on 2026-08-05, which is what cleared the v3.0.0 gate).

Five details are load-bearing, all of them learned the expensive way.

- **`-A1` matters.** Several apps wrap the declaration onto a second line, and a single-line
  grep reads those as pinned.
- **A local `grep ~/code/afal/*/Gemfile` is not a substitute**, because it only sees the repos
  you happen to have cloned. On 2026-08-03 every locally cloned app was pinned and four org
  repos were not.
- **`gh search code` is not the same question asked faster.** Run on 2026-08-03,
  `gh search code 'bali_view_components branch org:Grupo-AFAL filename:Gemfile'` returned
  **nothing**, while the sweep found four repos on `branch: "main"`. GitHub's code index does
  not cover every private repo in the org, so a clean search result is not evidence.
- **`--no-archived` is what keeps this a gate instead of noise.** A sweep that prints the same
  dead repos every release stops being read by the third one. Archive a repo that is done and
  it leaves the list honestly; leave it unarchived and it is indistinguishable from a live
  consumer. On 2026-08-03 three of the four hits (`flamingOS`, `blogging`, `documentation`)
  were inactive and none of the four was archived, so the flag did nothing — **archiving them
  is part of the fix, not housekeeping to do later.**
- **`pushed_at` is a hint, never the decision.** It tells you which hits to chase first; it
  does not tell you a repo is dead. `flamingOS` had been pushed three days before it was
  identified as inactive.

## The CHANGELOG will conflict

Both lines write under `## [Unreleased]`, so every `main` → `3.1` merge conflicts there. It is
mechanical: keep both sets of entries, the v3.1 ones under their own `## [Unreleased]` heading
on the `3.1` branch. Nothing else in the file moves.
