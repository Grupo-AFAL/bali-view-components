# Release channels

Bali is **not published to RubyGems or npm**. Apps consume it straight from this git
repository, so a "channel" here is nothing more than a git ref — there is no registry to
configure and no publishing step to run.

Two lines are maintained at the same time:

| Channel | Branch | Tags | For |
|---|---|---|---|
| **Stable (v2)** | `main` | `v2.18.0`, `v2.18.1`, … | Every app in production today |
| **Next (v3 pre-release)** | `3.0` | `v3.0.0.beta.1`, `.beta.2`, … | Apps adopting v3 early, one at a time |

## How an app picks a channel

**Pin a tag. Never track a branch.**

```ruby
# Stable
gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v2.18.0"

# Early v3
gem "bali_view_components", github: "Grupo-AFAL/bali-view-components", tag: "v3.0.0.beta.1"
```

Tracking `branch: "main"` looks convenient and is the thing that bites: `bundle update`
silently pulls whatever landed since, so two apps bundling on different days run different
code, a rollback has nothing to roll back to, and the day a major merges the app inherits
every breaking change without ever opting in. A tag is immutable — upgrading becomes a
one-line, reviewable diff in the `Gemfile.lock`.

## What lands where

- **A v2 fix or feature** → `main`. Release with the normal flow, tag `v2.x.y`.
- **Anything for v3** → `3.0`. Breaking changes live here and only here.
- **`main` → `3.0`, never the reverse.** After each v2 release, merge `main` into `3.0` so the
  next line does not drift. Merging `3.0` into `main` before v3 is ready would leak breaking
  changes into the stable channel — which is the whole thing this split exists to prevent.

## CI covers both lines

Every workflow triggers on `push` and `pull_request` for **both** `main` and `3.0`. It has to:
a pre-release tag cut from a branch nothing verified is worse than no pre-release at all.

Note the quotes in `branches: [main, "3.0"]` — unquoted, YAML parses `3.0` as the number
`3.0` and the filter silently never matches.

## Cutting a v3 pre-release

Whenever `3.0` reaches a state an app could adopt:

1. Bump `lib/bali/version.rb` and `package.json` to the next `3.0.0.beta.N`.
2. Move the `## [Unreleased]` entries under `## [v3.0.0.beta.N] - <date>`.
3. Tag `v3.0.0.beta.N` on `3.0` and publish a GitHub Release marked **pre-release**.

`3.0.0.beta.1` sorts before `3.0.0` under both RubyGems and semver rules, so the numbering
still reads correctly if this ever moves to a registry.

## Shipping v3

When `3.0` is complete: merge `3.0` into `main`, tag `v3.0.0`, and `main` becomes the v3 line.
From then on, v2 fixes (if any are still needed) branch off the `v2.18.x` tag into a `2-x`
maintenance branch.

## The CHANGELOG will conflict

Both lines write under `## [Unreleased]`, so every `main` → `3.0` merge conflicts there. It is
mechanical: keep both sets of entries, the v3 ones under their own `## [Unreleased]` heading on
the `3.0` branch. Nothing else in the file moves.
