# Enum badges: painting a domain value as a pill

Every AFAL app renders the same shape over and over: an enum-ish domain value
(a status, a priority, a kind) drawn as a colored pill. Before v3.1 each app
hand-rolled it — helpers that `safe_join` an icon into `text:`, per-view literal
color maps, private constants reaching into the gem. This guide is the one
recipe that replaces all of those, built on two pieces of sugar:

```ruby
Bali::Tag.for(value, map:, i18n_scope:, default:, **tag_options)      # → Bali::Tag::Component
Bali::Status.for(value, map:, i18n_scope:, default:, **status_options) # → Bali::Status::Component
```

Both take a **host-owned map** from domain value to color (and friends), resolve
the label through i18n, and return a component ready for `render`. The map stays
in your app on purpose: Bali knows how to paint a state, not what your domain's
states are.

## Tag or Status?

Pick by what the value *is*, not by how the pill should look:

| | `Bali::Tag` | `Bali::Status` |
|---|---|---|
| The value is | a **category or priority** — a fact about the record | a **workflow state** — where the record is in a process |
| Colors | daisyUI semantic names (`:success`, `:warning`, …) — **follow the theme** | the fixed 12-color palette (`:green`, `:blue`, …) — **theme-independent** |
| Can the user change it in place? | No | Yes — pass `form:` and the pill becomes an editable panel |
| Icon | `icon:` keyword / `with_icon` slot | — |

Rules of thumb: a rebrand should be allowed to change your priority colors
(they are UI), so Tag. A workflow's "validated" green must mean validated on
every theme and every chart, so Status. This is the criterion afal-apps already
practices (`priority_tag` with Tag, `status_pill` with Status).

## The recipe

The map lives in **one** helper per enum family — never inline in a view:

```ruby
# app/helpers/tickets_helper.rb
module TicketsHelper
  PRIORITY_TAGS = {
    urgent: { color: :error, icon: "flame" },
    high:   :warning,
    normal: :info,
    low:    :ghost
  }.freeze

  def priority_tag(ticket, size: :sm)
    render Bali::Tag.for(ticket.priority, map: PRIORITY_TAGS,
                         i18n_scope: "tickets.priorities", size: size)
  end
end
```

```erb
<%= priority_tag(ticket) %>
<%= priority_tag(ticket, size: :xs) %> <%# table cells %>
```

A map entry is either a bare color name or a hash of component options
(`{ color:, icon:, style:, … }` for Tag; `{ color: }` / `{ custom_color: }` for
Status). The label comes from `t("#{i18n_scope}.#{value}")`, or
`value.to_s.humanize` when no scope is given; an entry's `text:` (Tag) or
`label:` (Status) overrides it.

The same shape for a workflow state, where the map also powers the editable
panel:

```ruby
# app/helpers/tasks_helper.rb
module TasksHelper
  TASK_STATUSES = {
    pending:     :slate,
    in_progress: :blue,
    in_review:   :amber,
    done:        :green
  }.freeze

  def task_status_pill(task, editable: false)
    render Bali::Status.for(
      task.status, map: TASK_STATUSES, i18n_scope: "tasks.statuses",
      id: dom_id(task, :status),
      form: editable ? { url: task_status_path(task), param: "task[status]" } : nil
    )
  end
end
```

## Unmapped values raise — on purpose

A new domain state that nobody mapped is a bug, not a gray pill. Both `.for`
methods raise `ArgumentError` when `value` is not a key of the map:

```ruby
Bali::Tag.for(:brand_new, map: PRIORITY_TAGS)
# => ArgumentError: Bali::Tag.for: :brand_new is not in the map (keys: :urgent, …)
```

If your domain genuinely produces open-ended values (user-defined states,
imported data), say so with `default:` — same shapes as a map entry:

```ruby
Bali::Tag.for(value, map: PRIORITY_TAGS, default: { color: :ghost })
```

For `Status.for`, the default entry is appended as one more option, so the
current (unmapped) value stays selectable in the editable panel.

## The same color outside the pill

`Bali::Status::Component::PALETTE` — twelve `name => { bg:, fg: }` hex pairs
with contrast already resolved — is public API as of v3.1. When something that
is *not* a pill must match the state's color (a Gantt bar, a chart slice, a
calendar chip), read the pair through the accessor instead of inventing a
second palette:

```ruby
pair = Bali::Status.palette(TASK_STATUSES.fetch(task.status.to_sym))
# => { bg: "#2563eb", fg: "#fff" }
```

```erb
<div style="background-color: <%= pair[:bg] %>; color: <%= pair[:fg] %>">…</div>
```

If a state's color ever changes, it changes in the pill and in the bar at once.
Public also means frozen: changing one of the twelve hex values is a breaking
change to Bali, so hosts can rely on them.

An unknown name raises, listing the valid ones. The deterministic avatar
colors (`Bali::Utils::ColorCalculator#deterministic_color`) draw from this same
palette — one palette, everywhere.

## What NOT to do

- **Don't put the map in the gem.** Two apps will disagree about what
  "approved" looks like, and they should be able to.
- **Don't build the icon into `text:`** with `safe_join` — that is what the
  `icon:` keyword replaces.
- **Don't hash workflow states to Tag's semantic colors.** `:error` red on a
  state that is not an error reads as one. Workflow states belong in Status's
  fixed palette.
- **Don't copy `PALETTE`'s hex values** into your own constants — reference
  `Bali::Status.palette` so the pill and your copy cannot drift apart.
