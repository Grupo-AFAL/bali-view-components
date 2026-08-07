# Bali::Gantt::Component

A Gantt chart: a React Flow island that draws the schedule you hand it as a
plain data document. Drag a bar to move it, resize it to change its duration,
draw an edge to create a dependency; the toolbar carries zoom, search,
filtering, the column selector, colour-by, the minimap, the critical path and
fullscreen. A board that only reads passes no `urls:` and no `editable:` — the
same island, with the editing controls gone.

**The island is the only renderer.** Bali shipped a server-rendered `:static`
board alongside it through v3.1's betas and removed it in #970: keeping two
renderers of the same schedule in parity was a permanent tax on every feature,
and the static one had already fallen eight behind (minimap, colour selector,
dependencies, critical path, fullscreen, design alignment, filtering, column
selector) — features the read-only portfolio case wants too. If you pinned
`v3.1.0.beta.6`/`beta.7` and passed `mode:`, `fallback:`, `limit:`,
`zoom_links:`, `group_label:` or `color_by:`, see
[migration-v3-to-v31.md](../guides/migration-v3-to-v31.md).

**This means the Gantt needs JavaScript.** The component renders a loading
skeleton inside the island's mount and a `<noscript>` notice beside it; a
visitor who never runs the bundle gets the notice, not a schedule. If some of
your visitors need the plan without JavaScript, give them a non-canvas path to
it — a table of the same items on the item's own page, for instance.

- Data contract, renames and validation rules: `Bali::Gantt::Data` (start there).
- Island mechanics (`ReactIslandController`, entries, loaders): [react-island.md](react-island.md).
- Executable reference for every endpoint below: `spec/dummy/app/controllers/admin/projects/`
  and `spec/dummy/app/models/project_gantt.rb`.

---

## Installation

All four steps are required — without the bundle the component renders its
skeleton and nothing else.

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
the skeleton stays on screen and nothing else breaks.

---

## Basic usage

### Editable

```erb
<% gantt = ProjectGantt.new(@project) %>
<%= render Bali::Gantt::Component.new(
      data: gantt.to_h,
      statuses: gantt.statuses,
      catalogs: gantt.catalogs,
      zoom: params[:gantt_zoom],
      editable: policy(@project).reschedule?,
      manageable: policy(@project).manage?,
      urls: {
        patch: project_schedule_path(@project),
        schedule: project_schedule_path(@project),
        dependencies: project_dependencies_path(@project)
      },
      id: dom_id(@project, :gantt)) %>
```

`ProjectGantt` here is **your** serializer — the object that turns your models
into the contract. `spec/dummy/app/models/project_gantt.rb` is a complete one to
copy from.

`editable` and `manageable` are yours to decide — the island only hides the
controls. **Authorize every endpoint server-side anyway**; a value in a data
attribute is a suggestion, not a permission.

### Read-only

```erb
<%= render Bali::Gantt::Component.new(
      data: PortfolioGantt.new(@programme).to_h,
      statuses: PortfolioGantt::STATUSES,
      zoom: params[:gantt_zoom]) %>
```

The same island with nothing to post to: no `urls:`, `editable`/`manageable`
left `false`. Zoom, collapse, search, filter, colour-by, the column selector and
the minimap are pure view state, so a viewer needs no endpoints at all.

---

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `data:` | required | The Gantt document (`Hash` or a prebuilt `Bali::Gantt::Data`) |
| `zoom:` | `:auto` | `:auto`, `:day`, `:week` or `:month` — usually `params[:gantt_zoom]`. `:auto` is resolved **server-side** against the window and handed to the island, so it opens at the right density instead of rescaling on mount |
| `zoom_param:` | `"gantt_zoom"` | Namespaced query param the island persists the zoom into. Never a bare `zoom`, which collides with any other control on the page |
| `statuses:` | humanized defaults | Status catalog `[{ value:, label:, color: }]`; `color` is a daisyUI variable name (`"--color-info"`) or `nil` for neutral. **Cover the group statuses too**: groups render as bars and feed the same legend, and any value the catalog misses falls back to `value.humanize` — an untranslated English label is how the gap shows up (measured in afal-apps#462, where stage statuses leaked "Not started" into a Spanish UI) |
| `catalogs:` | `{ statuses: statuses }` | Island catalogs: `{ statuses: [{value, label, color}], priorities: [{value, label, hue}] }`. A key you leave out falls back to the island's own defaults |
| `i18n:` | `Bali::Gantt::Translations.island` | Flat string table for the island |
| `editable:` | `false` | May move and resize items |
| `manageable:` | `false` | May add/remove dependencies and create records |
| `urls:` | `{}` | `patch:`, `dependencies:`, `schedule:`, `item_template:`, `new_group:`, `new_item:`. An unknown key raises |
| `date_locale:` | `I18n.locale` | date-fns locale for axis labels (`"en"` / `"es"`) |
| `id:` | `nil` | DOM id. Give it one if you broadcast (see below) |

Any other option (`class:`, `aria:`, …) lands on the wrapper element. `data:` is
the schedule, so it is not available for HTML data attributes — put those on
your own wrapper.

**Removed in #970**, and refused by name rather than silently emitted as an HTML
attribute: `mode:`, `fallback:`, `limit:`, `zoom_links:`, `group_label:` and
`color_by:`. All six configured the server-rendered board; the island owns the
zoom switcher, the name column, colour-by and how much of the document it
draws.

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

## The skeleton and the swap

The component renders the mount element with the skeleton inside it:

```html
<div id="gantt_project_1" class="bali-gantt" data-controller="gantt"
     data-gantt-data-value='{"groups":[…],"items":[…]}'
     data-gantt-initial-zoom-value="day" …>
  <noscript>…this timeline needs JavaScript…</noscript>
  <div class="bali-gantt-skeleton" role="status" aria-busy="true">…</div>
</div>
```

The island mounts into a container prepended to that element and removes the
skeleton from inside React's first commit — after the DOM carries the island,
before the browser paints. One frame shows the skeleton, the next shows the
island, and no frame shows an empty box. (It used to clear the mount up front
and let React fill it later; on a 300-item board with the CPU throttled 6x that
was a white screen for about two seconds.) `cypress/e2e/gantt-swap.cy.js`
measures exactly that ordering from inside the page.

The skeleton is **not** a configuration choice — it is the mechanism, and there
is no option to turn it off. It is fixed-size and carries none of the real
schedule: the point is to hold the box without rendering anything expensive, and
a placeholder built from real data would be a second renderer by accident.

Two things ride with it:

- **`data-gantt-initial-zoom-value`**, the one piece of geometry the server
  still decides. Without it the island opens at its own default (`week`)
  whatever the window says, and a board that should have opened at day zoom
  rescales the moment it mounts. Once mounted the island owns the zoom and
  writes it to the URL.
- **A `<noscript>` notice.** The skeleton says `aria-busy="true"` and means
  "loading"; to a visitor who will never run the bundle that would be a lie held
  forever, so the notice says plainly that the timeline needs JavaScript. It is
  translated (`bali_view.gantt.noscript`).

**If the bundle never arrives, the mount is not emptied.** The island's error
notice is prepended to the skeleton rather than replacing it, so a failed load
looks like a failure with a message, not a blank region.

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

Read this before you make the Gantt the only way to do something.

The island's canvas is a **mouse-first surface** — React Flow drag-and-drop has
no keyboard equivalent, and #970 removed the server-rendered board that used to
sit behind it. So:

- **Keep a non-canvas path to every action.** A form on the item's own page that
  sets its dates, a table of the schedule, a list view. The island is a faster
  way to reschedule, not the only way it may be possible.
- **Without JavaScript there is no board.** The `<noscript>` notice inside the
  mount says so rather than leaving a placeholder claiming "loading" forever.
  Point it at that alternate path if you have one.

What the island itself does carry: the toolbar is real `<button>`s in labelled
`role="group"`s (zoom, colour-by, columns), group rows collapse from buttons
carrying `aria-expanded`, the table half is keyboard-reachable, and the loading
skeleton announces itself as `role="status"` with `aria-busy="true"`.

---

## Lookbook previews

| Preview | What it shows |
|---|---|
| `bali/gantt/default` | The read-only island, with `zoom` as a live param |
| `bali/gantt/editable` | The complete editable island against the dummy's endpoints — needs `bin/rails db:seed`, and edits persist |
| `bali/gantt/stress` | 300 items from a fixed seed: watch the skeleton hand over without a gap |
| `bali/gantt/empty` | An empty document — the island still mounts and draws its own empty canvas |

`spec/dummy/app/views/admin/projects/show.html.erb` (`?view=timeline`) is the
same island in a **real layout** rather than a preview: the asset paths go up
through `content_for :head`, which is the step a Lookbook preview cannot show.

---

## Troubleshooting

**The skeleton never goes away.** The island bundle never arrived. Check the
console: a missing `react_island_meta_tags` says so by name. Otherwise confirm
`gantt-island.js` is in `entryPoints` and that the built file exists. The error
notice is prepended to the skeleton, so look above it before assuming nothing
happened.

**Everything mounts twice.** Something started a second Stimulus `Application`.
Register on the one you expose as `window.Stimulus`; see
[react-island.md](react-island.md).

**The board rescales the moment it appears.** The island opened at its own
default instead of the zoom the server resolved. Check that
`data-gantt-initial-zoom-value` is on the element and that your page is not
passing a different `zoom:` than the one in `gantt_zoom`.

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
- `Bali::Gantt::TimeScale` — how `zoom: :auto` resolves against the window
- `Bali::Gantt::Colors` — the default status → daisyUI colour map a host
  inherits when it passes no catalog
- [../guides/migration-v2-to-v3.md](../guides/migration-v2-to-v3.md) — moving
  off the removed `Bali::GanttChart`
