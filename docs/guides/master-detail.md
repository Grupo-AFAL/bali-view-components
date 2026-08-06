# Master-Detail Screens

The inbox shape: a list of items on the left, the detail of the selected one on
the right. Clicking a row swaps only the right column, so the list keeps its
scroll position and its highlight — which is the whole reason to build the
screen this way instead of navigating to a detail page.

`Bali::SplitView::Component` gives you the three parts that are identical in
every such screen — the responsive grid, the Turbo Frame around the detail, and
the Stimulus controller that moves the highlight. **Everything else is yours.**
Tabs, filter chips, pagination and the rows themselves go inside the `master`
slot in whatever shape the screen needs; no two master-detail screens agree on
that arrangement, so the component does not try to own it.

- Live example: `/lookbook/preview/bali/split_view/default`
- Working reference in the dummy app: `spec/dummy/app/controllers/split_views_controller.rb`
  and `spec/dummy/app/views/split_views/` — the whole Rails side in one action.

---

## The shape

```erb
<%= render Bali::SplitView::Component.new(frame_id: "inbox-detail") do |split| %>
  <% split.with_master do %>
    <%= render "master_pane", items: @items, selected: @selected %>
  <% end %>

  <% if @selected %>
    <% split.with_detail do %>
      <%= render "detail_pane", item: @selected %>
    <% end %>
  <% else %>
    <% split.with_empty_detail do %>
      <%= render Bali::EmptyState::Component.new(
        title: t("inbox.detail.none.title"),
        description: t("inbox.detail.none.description"),
        icon: "inbox"
      ) %>
    <% end %>
  <% end %>
<% end %>
```

**Options**

- `frame_id` (required) — id of the detail Turbo Frame. Rows point at it with
  `data-turbo-frame`, so it has to be unique in the page.
- `master_width` — width of the left column from `lg` up. A CSS length or
  percentage (`"420px"` default, `"24rem"`, `"30%"`). Anything more expressive
  goes in your own stylesheet, overriding `--bali-split-master-width`.
- `advance` — emit `data-turbo-action="advance"` on the frame so a row click
  pushes its URL into the history and the selection is deep-linkable
  (default: `true`).

**Slots**

- `master` — the left column, free-form. Wrapped in the `split-view` controller
  element, so rows inside it can be its targets.
- `detail` — what the server renders for the current selection.
- `empty_detail` — shown inside the frame when there is no selection. Ignored
  when `detail` is present.

Below `lg` the two panes stack, master on top. That needs no JavaScript and no
option; see [Full-page detail on a phone](#full-page-detail-on-a-phone) if you
want the other mobile behaviour.

---

## The Rails side

One action renders both the full page and the frame response. There is no
second controller and no `respond_to` block: Turbo asks for the same URL and
extracts the matching frame from the reply.

```ruby
class InboxController < ApplicationController
  def show
    @items    = current_user.inbox_items.then { |scope| filter(scope) }
    @selected = @items.find_by(id: params[:selected])
  end
end
```

`params[:selected]` is the entire deep-linking mechanism:

- Loaded cold, `/inbox?selected=42` renders the whole page with row 42 already
  highlighted and its detail in the frame.
- Reached by a row click, Turbo fetches the same URL, takes only
  `<turbo-frame id="inbox-detail">` out of the response, and puts it in the
  page. The master is never touched.

**Order the list deterministically.** The master is not re-rendered on a row
click, so a list whose order depends on `updated_at` will disagree with itself
after the detail pane writes to a record.

### The row

```erb
<%= link_to inbox_path(selected: item.id, **@filters),
      id: dom_id(item, :inbox_row),
      class: "split-view-row px-4 py-3 border-b border-base-200/70",
      aria: { current: (item == @selected ? "true" : nil) },
      data: {
        turbo_frame: "inbox-detail",
        split_view_target: "row",
        action: "click->split-view#select"
      } do %>
  <div class="font-medium text-sm truncate"><%= item.title %></div>
  <div class="text-xs text-base-content/60 truncate"><%= item.subtitle %></div>
<% end %>
```

Four things are load-bearing:

- **`class: "split-view-row"`** — the look of a row, including its selected
  state, comes from this class. Add your own padding and separators next to it.
- **`aria-current` from the server** — this is what paints the selection on the
  first render and after any full-page navigation (a filter tab, another page
  of results). The controller only covers the clicks in between.
- **`data-turbo-frame`** — what makes the click swap the frame instead of the
  page.
- **`data-split-view-target` + `data-action`** — what lets the controller move
  the highlight without a round trip.

**Carry the current filters in the row's href.** The href is the URL the
selection deep-links to; drop the filters and reloading that URL gives an
unfiltered list with a mysteriously selected row.

**Do not put `data-turbo-action="advance"` on the row.** The frame already
carries it, and a link-level one wins over the frame — so it silently defeats
`advance: false`.

---

## Making the list scroll

`.split-view-scroll` is opt-in and goes around **the part of the master that
should scroll**, usually the list alone, so tabs above it and pagination below
it stay put:

```erb
<%= render Bali::Card::Component.new(style: :bordered, body_class: "p-0") do %>
  <%= render "bucket_tabs" %>

  <div class="split-view-scroll">
    <%= render partial: "row", collection: @items %>
  </div>

  <%= render Bali::PaginationFooter::Component.new(pagy: @pagy) %>
<% end %>
```

Its height is `var(--bali-split-master-max-h, calc(100vh - 20rem))`. The default
is a guess about your chrome; when it is wrong, say so on the element rather
than writing a new `max-height`:

```erb
<div class="split-view-scroll" style="--bali-split-master-max-h: 26rem">
```

---

## Two empty states, not one

A list with nothing in it means one of two things, and they need different
words and different offers. "No results" next to filters the user set is a dead
end; the useful thing is a way out of them.

`Bali::EmptyState::Component` already has the `cta` slot for exactly this, so
this is composition, not a component option:

```erb
<% if @items.none? %>
  <% if @filters.none? %>
    <%= render Bali::EmptyState::Component.new(
      title: t("inbox.empty.zero.title"),
      description: t("inbox.empty.zero.description"),
      icon: "inbox",
      size: :sm
    ) %>
  <% else %>
    <%= render Bali::EmptyState::Component.new(
      title: t("inbox.empty.filtered.title"),
      description: t("inbox.empty.filtered.description"),
      icon: "filter-x",
      size: :sm
    ) do |state| %>
      <% state.with_cta do %>
        <%= render Bali::Link::Component.new(
          name: t("inbox.filters.clear"),
          href: inbox_path,
          variant: :ghost,
          size: :sm
        ) %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

`@filters.none?` stands for whatever "the user narrowed this" means on your
screen — an active tab, a search term, a set of chips. Compute it once in the
controller; the condition is easy to get subtly wrong in two places.

The detail pane's empty state is a third, different one, and it belongs in
`empty_detail`: nothing is wrong, the user simply has not picked anything yet.

---

## Full-page detail on a phone

The default below `lg` is stacked: master on top, detail underneath. That is one
scroll for both, which is right when the rows are short.

When the detail is long, the alternative is master-only, with a row click
navigating to a detail page of its own. There is no option for this because it
is not a layout change — it is a different route, and the component cannot
invent one.

The mechanism is Turbo's own fallback, measured both ways:

| The frame `data-turbo-frame` names is… | What a row click does |
|---|---|
| in the DOM | swaps the frame — **even with `display: none` on it** |
| not in the DOM at all | an ordinary full-page visit to the row's href |

So the row markup never changes. What changes is whether the page renders the
split view, and **that has to be a server-side decision** — hiding it with
`lg:hidden` leaves the frame in the DOM, and Turbo swaps a frame nobody can see.

Rails variants are the tool for that:

```ruby
class InboxController < ApplicationController
  before_action { request.variant = :phone if browser.device.mobile? }

  def show
    @items    = filter(current_user.inbox_items)
    @selected = @items.find_by(id: params[:selected])
  end
end
```

`show.html+phone.erb` renders the master alone — no `SplitView`, no frame — and
`show.html.erb` renders the split view as above. On a phone the same row click
becomes a real visit to `/inbox?selected=42`, which the same action already
answers with a whole page. One route, one response, and a real back button.

If you would rather not sniff the User-Agent, the same split works off anything
the server can see: a `?view=` param, a user preference, a cookie your layout
sets from a media query on first load.

---

## Back and forward

With `advance: true` the URL is the selection, and the browser buttons work.
One thing is worth knowing because it explains a line in the controller:

Turbo promotes the frame swap to a visit, and the snapshot it caches for the
page being left is taken **between** the click and the frame's response. That
snapshot therefore holds the highlight the controller has just moved, next to
the detail pane from before the swap. Restoring it would show a master pointing
at one row with an unrelated detail beside it.

So on a history traversal the controller re-derives the highlight from the URL
rather than trusting the snapshot. It can, because each row's href *is* the URL
that selects it. **This is also why the href matters**: rows whose href is not
the URL that selects them lose their highlight on back. If your rows link
somewhere else entirely, use `advance: false` — the frame still swaps, nothing
is pushed into the history, and none of this applies.

On a first render the server's markup always wins, since a master can perfectly
well live on a page whose URL is not in its rows' URL space.

---

## Styling the rows

The selected row is `.split-view-row[aria-current]`, drawn as a tinted
background plus an inset `box-shadow` bar down the left edge.

**It is a shadow and not a left border on purpose.** Rows are usually separated
with `border-b border-base-200/70`, and Tailwind's `border-<color>` utility sets
the colour of all four sides, not just the one `border-b` drew. Utilities beat
`@layer components`, so a `border-l-primary` in Bali's stylesheet renders
base-200 under it and the highlight disappears. The shadow also paints inside
the padding box, so the selection moves between rows without shifting any text.

To add to the selected look rather than replace it, use the Stimulus classes on
the master element:

```erb
<div data-controller="split-view" data-split-view-selected-class="ring-2 ring-primary">
```

Those are applied on top of `aria-current`, so they only need to cover what the
attribute-driven CSS does not. Remember that a class only present in a JS
attribute has to appear somewhere Tailwind scans — which your row partial does,
if the server renders the same selected state.

---

## What this is not

- **Not a list component.** The rows are yours. If they all look the same across
  your app, that is a partial in your app, not an option here.
- **Not a filter or pagination host.** Those go in `master` as content, because
  the screens that need them do not agree on where they sit.
- **Not a re-render.** Never answer a row click by re-rendering the master — it
  loses the scroll position, which is the one thing this pattern exists to keep.

---

## See also

- [Components guide](components.md#splitview) — the API reference.
- `Bali::EmptyState` — the empty states above.
- `Bali::PaginationFooter` — pagination inside the master.
