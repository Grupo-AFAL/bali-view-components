# Bali::Gantt::Component

A Gantt chart with **two renderers over one data contract**. Both draw the same
schedule with the same geometry and the same colours; what differs is who does
the drawing.

| Mode | What renders | Needs JavaScript | Use it for |
|---|---|---|---|
| `:static` (default) | Server-rendered HTML board: sticky two-tier header, collapsible groups, today marker | No | Portfolio and read-only views, printing, e-mail-adjacent pages, anything that must work everywhere |
| `:interactive` | A React Flow island: drag to move, resize to change duration, draw dependencies, live critical path | Yes (plus the island bundle) | The editable schedule of a single project |

`:interactive` is `:static` plus an island: the component renders the static
board **inside the island's mount element** and React replaces it when the
bundle arrives. That is why an interactive Gantt still shows a schedule with
JavaScript disabled, and why the moment React takes over is not a flash of
empty space.

- Data contract, renames and validation rules: `Bali::Gantt::Data` (start there).
- Island mechanics (`ReactIslandController`, entries, loaders): [react-island.md](react-island.md).
- Executable reference for every endpoint below: `spec/dummy/app/controllers/admin/projects/`
  and `spec/dummy/app/models/project_gantt.rb`.

---

## Installation

**`mode: :static` needs nothing.** It is plain server-rendered HTML — skip this
whole section. The four steps below are only for `mode: :interactive`.

### Step 1 — npm packages

```bash
yarn add react react-dom @xyflow/react date-fns @rails/request.js
```

All five are **optional peers** of `bali-view-components`: an app that never
mounts the island does not install them. `@xyflow/react` must be `>=12` (it
supports React 18 and 19); `react`/`react-dom` `>=18`.

### Step 2 — a dedicated bundler entry

```js
// app/javascript/gantt-island.js
import 'bali-view-components/gantt-entry'
```

That single line is the whole file. It registers `GanttController` on the
Stimulus application your app exposes as `window.Stimulus`, with a guard so
loading it twice registers once.

The entry has to be **its own** for two reasons. React plus React Flow is far
too heavy for the bundle that travels on every page; and `GanttFlow` imports
CSS from JavaScript (`@xyflow/react`'s stylesheet plus the island's `flow.css`),
which esbuild emits as that entry's `.css` file — inside the main entry it
would be appended to your application stylesheet instead.

```js
// esbuild.config.mjs
entryPoints: ['app/javascript/application.js', 'app/javascript/gantt-island.js']
```

> **Never start a second Stimulus `Application` for the island.** Two
> applications scanning the same DOM mount every controller twice. afal-apps
> shipped exactly that bug in its old `gantt.js`; `registerIsland` exists so
> nobody writes it again. See [react-island.md](react-island.md).

### Step 3 — lazy-load it from the main bundle

```js
// app/javascript/application.js
import 'bali-view-components/gantt-loader'
```

This weighs nothing: it watches the DOM and injects the real bundle the first
time an element with `data-controller="gantt"` appears — including content Bali
drawers and modals inject with `innerHTML`, where `<script>` tags never execute.

### Step 4 — publish the asset paths in the layout

The digested paths are only known server-side, so the layout hands them to the
loader through meta tags:

```erb
<%# app/views/layouts/application.html.erb, in <head> %>
<%= react_island_meta_tags('gantt', js: 'gantt-island.js', css: 'gantt-island.css') %>
```

Miss this step and the loader logs a precise error naming the tag it wanted;
the fallback stays on screen and nothing else breaks.

---

## Basic usage

### Static

```erb
<% gantt = ProjectGantt.new(@project) %>
<%= render Bali::Gantt::Component.new(
      data: gantt.to_h,
      color_by: :status,
      zoom: params[:gantt_zoom],
      statuses: gantt.statuses,
      group_label: 'Phase',
      limit: 300) %>
```

`ProjectGantt` here is **your** serializer — the object that turns your models
into the contract. `spec/dummy/app/models/project_gantt.rb` is a complete one to
copy from.

### Interactive

```erb
<% gantt = ProjectGantt.new(@project) %>
<%= render Bali::Gantt::Component.new(
      data: gantt.to_h,
      mode: :interactive,
      statuses: gantt.statuses,
      catalogs: gantt.catalogs,
      editable: policy(@project).reschedule?,
      manageable: policy(@project).manage?,
      urls: {
        patch: project_schedule_path(@project),
        schedule: project_schedule_path(@project),
        dependencies: project_dependencies_path(@project)
      },
      id: dom_id(@project, :gantt)) %>
```

`editable` and `manageable` are yours to decide — the island only hides the
controls. **Authorize every endpoint server-side anyway**; a value in a data
attribute is a suggestion, not a permission.

---

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `data:` | required | The Gantt document (`Hash` or a prebuilt `Bali::Gantt::Data`) |
| `mode:` | `:static` | `:static` or `:interactive` |
| `fallback:` | `:static` | What renders inside the island's mount: `:static` or `:skeleton`. Ignored by `mode: :static` |
| `color_by:` | `:status` | `:status` paints bars from the status catalog; `:none` is all-neutral |
| `zoom:` | `:auto` | `:auto`, `:day`, `:week` or `:month` — usually `params[:gantt_zoom]` |
| `zoom_param:` | `"gantt_zoom"` | Namespaced query param the zoom writes. Never a bare `zoom`, which collides with any other control on the page |
| `zoom_links:` | `true` | Render the static zoom switcher (plain GET links) |
| `group_label:` | `t('.name_column')` | Header of the sticky name column |
| `statuses:` | humanized defaults | Status catalog `[{ value:, label:, color: }]`; `color` is a daisyUI variable name (`"--color-info"`) or `nil` for neutral |
| `limit:` | `300` | Announced cap on rendered items. **Caps the static board only** — the island receives the whole document |
| `id:` | `nil` | DOM id. Give it one if you broadcast (see below) |
| **Interactive only** | | |
| `catalogs:` | `{ statuses: statuses }` | Island catalogs: `{ statuses: [{value, label, color}], priorities: [{value, label, hue}] }` |
| `i18n:` | `Bali::Gantt::Translations.island` | Flat string table for the island |
| `editable:` | `false` | May move and resize items |
| `manageable:` | `false` | May add/remove dependencies and create records |
| `urls:` | `{}` | `patch:`, `dependencies:`, `schedule:`, `item_template:`, `new_group:`, `new_item:`. An unknown key raises |
| `date_locale:` | `I18n.locale` | date-fns locale for axis labels (`"en"` / `"es"`) |

Any other option (`class:`, `data:`, …) lands on the wrapper element.

---

## The data contract

Documented in full, with validation rules, in `Bali::Gantt::Data`. The shape:

```ruby
{
  window: { starts_on: "2026-01-01", ends_on: "2026-12-31" },   # optional; derived when absent
  groups: [
    { id: 1, name: "Discovery",
      parent_id: nil,               # one level of nesting
      status: "in_progress",
      starts_on: "...", ends_on: "...",   # the group's own rollup bar
      href: "/phases/1" }
  ],
  items: [
    { id: 10, group_id: 1, name: "Wireframes",
      starts_on: "2026-01-02", ends_on: "2026-01-15",
      parent_id: nil,               # sub-item (subtask); one level
      status: "in_progress", priority: "high",
      milestone: false,             # renders a diamond on the date
      percent_complete: 40,
      assignee: { id: 7, name: "Ana Luz", initials: "AL" },
      slack_days: 3, href: "/tasks/10" }
  ],
  dependencies: [
    { id: 1, predecessor_id: 10, successor_id: 11,
      dependency_type: "finish_to_start", lag_days: 0 }
  ],
  critical_ids: [10, 11]
}
```

Structural problems — missing ids, unknown references, malformed ISO dates,
nesting deeper than one level — raise `Bali::Gantt::Data::InvalidError` instead
of quietly dropping bars. A typo that silently loses rows would lie about the
plan.

Items with no dates are not dropped either: they render in a "No dates" section
under the board.

---

## Fallbacks and the swap

`mode: :interactive` renders the mount element and puts the fallback inside it:

```html
<div id="gantt_project_1" class="bali-gantt" data-controller="gantt"
     data-gantt-data-value='{"groups":[…],"items":[…]}'
     data-gantt-initial-zoom-value="day" …>
  <!-- the fallback: the whole static board, or the skeleton -->
</div>
```

The island mounts into a container prepended to that element and removes the
fallback from inside React's first commit — after the DOM carries the island,
before the browser paints. One frame shows the board, the next shows the
island, and no frame shows an empty box. (It used to clear the mount up front
and let React fill it later; on the 300-item board with the CPU throttled 6x
that was a white screen for about two seconds.)

So the fallback is three things at once: what a visitor sees while the bundle
is in flight, what a visitor without JavaScript keeps forever, and what search
engines and reader modes index. If the bundle never arrives at all, it simply
stays — the error notice is prepended to it rather than replacing it.

**`fallback: :static` (default)** renders the real board. The swap is meant to
be unremarkable, and that rests on both renderers agreeing about geometry:

- `Bali::Gantt::TimeScale` and the island's `timeScale.js` share the pixel
  densities (day 24 px/day, week 8, month 2), so a 12-day bar is 288 px wide on
  both sides — measured, not asserted: `cypress/e2e/gantt-interactive.cy.js`
  compares the fallback bar and the React node and requires them equal.
- The component hands the island the zoom its fallback resolved, in
  `data-gantt-initial-zoom-value`. Without it the island would open at its own
  default (`week`) while the fallback had resolved `:auto` to something else,
  and mounting would rescale the whole board in front of the visitor. Once
  mounted the island owns the zoom and writes it to the URL.

**`fallback: :skeleton`** renders a neutral placeholder instead — the island's
frame with grey blocks in it, no schedule data. It is the right choice when the
static board is expensive enough that rendering it twice is not worth it: at
300 items it is about 390 KB of extra HTML per response.

> **The skeleton is not a no-JavaScript story.** It says `aria-busy="true"` and
> means "loading"; without the bundle it means that *forever*, and a visitor
> with JavaScript off gets grey blocks and no way to read the schedule. Choose
> it when your audience reliably runs the bundle and the cost of rendering the
> board twice is the thing you are buying out of. If some of your visitors
> never get JavaScript, `:static` is the only fallback that serves them — or
> pair the skeleton with your own `<noscript>` block linking to a page that
> lists the schedule as text.

afal-apps originally shipped a component fallback, saw it flicker, and replaced
it with a skeleton. That fallback did **not** share geometry with the island —
which is the thing this design changed. If a swap ever reads as a flicker in
your app, move to `:skeleton`: nothing else in the call site changes.

---

## The mutation contract

Bali ships no controllers. The island posts these four requests and expects
these four answers; implementing them is the host's job. The rule underneath
all of them:

> **The server is authoritative.** The island never computes dates or the
> critical path. It posts an edit and redraws from whatever comes back.

The reference implementation is executable:
`spec/dummy/app/controllers/admin/projects/schedules_controller.rb` and
`dependencies_controller.rb`.

### Move or resize an item

```http
PATCH <urls[:patch]>
{ "item": { "id": 10, "starts_on": "2026-02-03", "duration_days": 12 } }
```

`duration_days` counts inclusive days, so a one-day item sends `1`.

### Create a dependency

```http
POST <urls[:dependencies]>
{ "dependency": { "predecessor_id": 10, "successor_id": 11, "lag_days": 0 } }
```

### Delete a dependency

```http
DELETE <urls[:dependencies]>/:id
```

### Re-sync

```http
GET <urls[:schedule]>
```

### The four answers

| Status | Body | What the island does |
|---|---|---|
| `200` | **The complete document** — same shape as `data:` | Replaces its whole schedule with it (reconcile) |
| `422` | `{ "errors": ["…"] }` | Rolls the optimistic edit back and shows the messages in a toast |
| `404` | — | Assumes its copy is stale and re-`GET`s `urls[:schedule]` — **only if you passed one**; without it the recovery degrades to a rollback and an error toast, and the board stays stale until the visitor reloads |
| anything else | — | Rolls back and reports `Error <status>` |

**Always answer with the whole document, never a patch.** A move cascades:
successors shift, group rollups move, the critical path is recomputed. The
island has no scheduler to work that out — returning only the edited item
leaves the board wrong until the next reload.

Two behaviours worth knowing about the client (`scheduleClient.js`):

- **In-flight requests are aborted.** A new edit aborts the previous one, and a
  response whose request id is no longer the latest is discarded. A slow
  recalculation can never overwrite a newer optimistic state.
- **Validation is shared, and the split matters.** The island refuses three
  things client-side, so they never reach you: a dependency from an item to
  itself, a dependency that duplicates one already on screen, and a resize
  below one day (durations are clamped to `>= 1`). Everything else is yours,
  and the one you cannot skip is **cycles** — the island has no topology check,
  so a dependency that closes a loop *will* be posted and your `422` is the
  only thing standing between it and a schedule that cannot be computed.
  Validate the other three on the server too: the client checks are a courtesy
  to the user, not a guarantee to you, and a host that trusts them is one
  crafted request away from bad data.

CSRF stays on: the island posts through `@rails/request.js`, which reads the
token from `csrf_meta_tags`. (The dummy's controllers skip forgery protection
only because Lookbook's preview layout emits no token.)

---

## The broadcast contract

When a background job reschedules a project, or another user edits it, every
open board should catch up. Bali does not subscribe to anything for you — it
gives you the one thing a broadcast needs, a stable target:

```erb
<%# the view %>
<%= turbo_stream_from [@project, :gantt] %>
<%= render Bali::Gantt::Component.new(
      data: ProjectGantt.new(@project).to_h,
      mode: :interactive,
      id: dom_id(@project, :gantt), …) %>
```

```ruby
# after the scheduler runs
broadcast_replace_to [project, :gantt],
                     target: ActionView::RecordIdentifier.dom_id(project, :gantt),
                     partial: "projects/gantt",
                     locals: { project: project }
```

`broadcast_replace_to` swaps the whole element, which is exactly right: the
replacement carries a fresh `data-gantt-data-value`, Stimulus tears the old
controller down and connects a new one, and React remounts against the new
document. The island reads `data` **once, at mount** — changing the attribute
in place would do nothing.

### Echo suppression is the host's job

A remount is not free: it costs a React mount and it resets view state (scroll
position, selection, collapsed groups, search). That is a fine price for
someone else's edit and a bad one for your own.

So **do not broadcast back to the person who caused the change.** They already
have the authoritative answer: it was the `200` from their own `PATCH`. The
usual shape is to carry the originating request through to the job and skip it
when the broadcast comes back around (afal-apps calls this its
`RescheduleBroadcast`):

```ruby
class RescheduleProjectJob < ApplicationJob
  def perform(project, origin_id: nil)
    project.reschedule!
    project.gantt_subscribers.excluding(origin_id).each { … }
    # or: skip the broadcast entirely when origin_id == Current.request_id
  end
end
```

Without it every drag costs the dragger a remount half a second after their bar
already landed — the schedule is correct, and the interface still feels broken.

---

## Accessibility

`mode: :static`, which is also the default fallback, is the accessible surface:

- The scrolling canvas is a labelled `role="region"` with `tabindex="0"`, so it
  is reachable and scrollable from the keyboard without a mouse.
- Groups collapse with `<details>`/`<summary>` — native disclosure semantics,
  no ARIA to get wrong, works with JavaScript off.
- Zoom is a group of plain `<a>` links that rewrite one query param. They work
  without JavaScript and they are real navigation, so they are links, not
  buttons.
- Every bar carries a `title` with its name and dates, and a bar that links
  somewhere carries `aria-label` with the item name.
- `fallback: :skeleton` announces itself as `role="status"` with `aria-busy`.

The island's own canvas is a mouse-first surface — React Flow drag-and-drop has
no keyboard equivalent. **If your Gantt is the only way to do something, keep a
non-canvas path to it** (a form on the item's own page, for instance). The
island is a faster way to reschedule, not the only way.

---

## Lookbook previews

| Preview | What it shows |
|---|---|
| `bali/gantt/default` | The static board, with `color_by` and `zoom` as live params |
| `bali/gantt/custom_status_catalog` | A host's own status vocabulary driving legend and colours |
| `bali/gantt/truncated` | `limit:` and its announcement |
| `bali/gantt/empty` | The empty state |
| `bali/gantt/interactive_readonly` | `mode: :interactive` with the default static fallback |
| `bali/gantt/interactive_skeleton` | The same island with `fallback: :skeleton` |
| `bali/gantt/interactive_stress` | 300 items from a fixed seed, static fallback |
| `bali/gantt/interactive_stress_skeleton` | 300 items, skeleton fallback (A/B partner of the above) |
| `bali/gantt/island_readonly` | The island mounted from hand-written markup, without the Ruby component |
| `bali/gantt/island` | The complete editable island against the dummy's endpoints — needs `bin/rails db:seed`, and edits persist |

---

## Troubleshooting

**The fallback never goes away.** The island bundle never arrived. Check the
console: a missing `react_island_meta_tags` says so by name. Otherwise confirm
`gantt-island.js` is in `entryPoints` and that the built file exists.

**Everything mounts twice.** Something started a second Stimulus `Application`.
Register on the one you expose as `window.Stimulus`; see
[react-island.md](react-island.md).

**The board jumps when the island mounts.** The two renderers disagree about
zoom. Check that `data-gantt-initial-zoom-value` is on the element and that
your page is not passing a different `zoom:` than the one in `gantt_zoom`.

**Dragging does nothing and no request is made.** `editable:` is false, or
`urls[:patch]` is missing. An unknown key in `urls:` raises at render time
precisely so a typo does not fail this quietly.

**A drag reverts a moment later.** The server answered `422` (look for the
toast) or answered `200` with a document that did not include the edit.

**The island resets while someone is using it.** A broadcast is echoing back to
the editor — see echo suppression above.

**React state breaks after using the browser's back button.** The island adds
`turbo-cache-control: no-cache` for exactly this reason; if you set that meta
yourself, Bali leaves yours alone — make sure it is not `cache`.

---

## See also

- [react-island.md](react-island.md) — the island mechanism itself
- `Bali::Gantt::Data` — the contract, with every validation rule
- `Bali::Gantt::TimeScale` / `Bali::Gantt::Colors` — the geometry and colour
  formulas both renderers share
- [../guides/migration-v2-to-v3.md](../guides/migration-v2-to-v3.md) — moving
  off the removed `Bali::GanttChart`
