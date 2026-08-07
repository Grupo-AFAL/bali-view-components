# Master-Detail Screens

The inbox shape: a list of items on the left, the detail of the selected one on
the right. Clicking a row swaps only the right column, so the list keeps its
scroll position and its highlight — which is the whole reason to build the
screen this way instead of navigating to a detail page.

`Bali::SplitView::Component` owns the grid, the Turbo Frame around the detail,
the Stimulus controller that moves the highlight — **and the listing**. The
detail pane stays completely yours.

- Live example: `/lookbook/preview/bali/split_view/structured_list`
- Working reference in the dummy app: `spec/dummy/app/controllers/split_views_controller.rb`
  and `spec/dummy/app/views/split_views/` — the whole Rails side in one action.

---

## The shape

```erb
<%= render Bali::SplitView::Component.new(frame_id: "inbox-detail") do |split| %>
  <% split.with_list(header: t("inbox.title"), count: @pagy.count,
                     selected: params[:selected], pagy: @pagy) do |list| %>
    <% @items.each do |item| %>
      <% list.with_item(id: item.id,
                        href: inbox_path(selected: item.id, **@filters),
                        title: item.title,
                        subtitle: item.subtitle,
                        icon: item.icon,
                        meta: l(item.due_on, format: :short),
                        meta_color: (:error if item.overdue?)) do |row| %>
        <% row.with_tag(text: item.kind_label, color: :info) %>
      <% end %>
    <% end %>
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

**Nothing above says how a row is wired.** `data-turbo-frame`,
`data-split-view-target`, `data-action` and `aria-current` are written by the
component — they were the same four attributes in every host template, and one
of them missing meant a row that silently reloaded the whole page.

**Options on the SplitView**

- `frame_id` (required) — id of the detail Turbo Frame. Rows point at it with
  `data-turbo-frame`, so it has to be unique in the page.
- `master_width` — width of the left column from `lg` up. A CSS length or
  percentage (`"420px"` default, `"24rem"`, `"30%"`). Anything more expressive
  goes in your own stylesheet, overriding `--bali-split-master-width`.
- `advance` — emit `data-turbo-action="advance"` on the frame so a row click
  pushes its URL into the history and the selection is deep-linkable
  (default: `true`).

**Slots on the SplitView**

- `list` — the structured listing. **The way to build a master.**
- `master` — the free-form left column. The escape hatch, unchanged and still
  supported; see [When `list` does not fit](#when-list-does-not-fit).
- `detail` — what the server renders for the current selection.
- `empty_detail` — shown inside the frame when there is no selection. Ignored
  when `detail` is present.

Below `lg` the two panes stack, master on top. That needs no JavaScript and no
option; see [Full-page detail on a phone](#full-page-detail-on-a-phone) if you
want the other mobile behaviour.

---

## The list

**Options on `with_list`**

- `header` / `count` — the listing's own title and counter.
- `selected` — the id of the selected record. Compared against each item's `id:`,
  so the "is this the current row?" expression is written once instead of per row.
- `pagy` — a Pagy object. Drives both the no-JS pagination controls and the page
  infinite scroll fetches next.
- `next_url` — an explicit next page, for a listing that pages without Pagy. Wins
  over the one derived from `pagy`.
- `infinite_scroll` — `false` keeps the pagination controls and mounts no
  observer, for a listing short enough that paging is a click.
- `item_name` / `max_height` — passed to the pagination summary, and to
  `--bali-split-master-max-h` on the scroll area.

`with_empty_state` replaces the rows when there are none — see
[Two empty states, not one](#two-empty-states-not-one) for why the words are
yours and not the component's.

**Options on `with_item`**

| | |
|---|---|
| `title` | **Required.** The row's line of text. |
| `href` | **Required.** The URL that selects this row, and the one the selection deep-links to. |
| `id` | Compared with the list's `selected:`; also the row's DOM id. Without it a row can never be current. |
| `subtitle` | Second line, truncated. |
| `icon` | Leading icon. |
| `meta` | Trailing column — a date, a count. |
| `meta_color` | `:error`, `:warning`, `:success`, `:primary`. The overdue case both source listings paint red. |
| `with_tag(text:, color:)` | Any number of badges above the title. |
| a block | Free content under the subtitle, for whatever the fields do not name. |

### Where these fields come from

The set is the union of the two production listings this was generalised from —
gobierno-corporativo's inbox and afal-apps' inbox widget — rather than a copy of
either:

| Element | gc inbox | afal-apps widget | In the API |
|---|---|---|---|
| Title | yes | yes | `title:`, required |
| Subtitle | yes | yes | `subtitle:` |
| Leading icon | no — tags carry the kind | yes | `icon:`, optional |
| Tags | two (kind + urgency) | none | `with_tag`, any number |
| Trailing date | yes, neutral | yes, **red when overdue** | `meta:` + `meta_color:` |
| Header + count | yes | yes | `header:` + `count:` |
| Bordered card around it | yes | yes | rendered by the component |
| Urgency dot | yes | no | the block |
| Requester avatar | yes | no | the block |
| Grouping with a per-group count | yes (by urgency) | yes (by kind) | **not yet — see below** |

The two rows disagree about almost everything except the title and the subtitle,
which is why the rest is optional and why the block exists at all.

**Grouping is deliberately absent.** Both listings group, so unlike in the first
release the pattern is now triangulable — but grouping and infinite scroll pull
against each other: an appended page arrives as a flat list of rows, and merging
it into existing group headers needs the server to say which group each row
belongs to. That is its own design, and shipping half of it would produce
listings that break on the second page.

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

### Paging: infinite by default

Give `with_list` a `pagy:` and the listing pages itself. There is no control to
click and no endpoint to add:

- The list renders **ordinary pagination controls** and a sentinel below the rows.
- The `split-view-list` controller hides the controls on connect and watches the
  sentinel with an `IntersectionObserver` rooted on the scroll area.
- As the sentinel comes into view it fetches **the same index URL, one page
  further on**, lifts the rows out of the reply and appends them.

That order is the point: the controls are in the markup and enhancement removes
them, so a reader without JavaScript gets working pagination rather than a
spinner that never resolves.

**Why fetch-and-extract and not a Turbo Stream.** The next page is rendered by
the action that already renders the list, so there is nothing to add on the
server: no `respond_to`, no `page.turbo_stream.append`, no partial extracted for
the purpose. The rows arrive with their wiring because the component rendered
them, and any index that can render this list can already answer the request.
The cost is transferring a whole page and discarding the parts we do not need,
which for a listing of this size is not worth a second code path.

The next URL is read back out of each fetched page rather than incremented in
the browser, so the server stays in charge of what "next" means — including
running out, which is how the end of the list is detected.

**Corners worth knowing:**

- **Deep link to a record on a later page.** The detail renders immediately (your
  action looks the record up against the whole table, not the current page), but
  its row is simply not on screen. The highlight appears when infinite scroll
  reaches its page. For that to work the next URL has to carry the selection —
  a Pagy-derived one does, since Pagy keeps the request's params.
- **Back after scrolling.** Turbo caches the page as it was when you left it, so
  going back keeps the pages you had already appended instead of resetting to
  page one. Measured, and pinned in `cypress/e2e/split-view-list.cy.js`.
- **A page that fails to load** leaves the rows untouched and offers a retry that
  asks for the same page again, rather than skipping it.

---

## Filtering the list

Tabs, buckets and filter chips belong to the listing, so `with_list` has a place
for them: `with_filter` adds a pill to a band between the header and the rows —
**outside** the scroll area, so the pills stay put while the rows move under
them, and **inside** the card, so they read as part of the listing.

**Every pill is a link.** There is no form around the band, no submit button and
no clear button, because a filter is a URL:

```erb
<% split.with_list(header: t("inbox.title"), count: @pagy.count,
                   selected: params[:selected], pagy: @pagy) do |list| %>
  <% list.with_filter(label: t("inbox.buckets.all"),
                      href: inbox_path,
                      active: @bucket.nil?) %>
  <% Inbox::BUCKETS.each do |bucket| %>
    <% list.with_filter(label: t("inbox.buckets.#{bucket}"),
                        count: @bucket_counts[bucket],
                        href: inbox_path(bucket: (@bucket == bucket ? nil : bucket)),
                        active: @bucket == bucket) %>
  <% end %>
  <%# … items … %>
<% end %>
```

```ruby
def show
  @bucket = params[:bucket].presence_in(Inbox::BUCKETS)
  @pagy, @items = pagy(filter(current_user.inbox_items, @bucket), limit: 20)
end
```

That controller is the whole server side. No FilterForm, no Ransack, no form
object — the filter is a query param you read.

**Options on `with_filter`**

| | |
|---|---|
| `label` | **Required.** The pill's text. |
| `href` | **Required.** Where clicking it goes. |
| `active` | Whether this is the current filter. Drives `aria-current="true"` and the styling. |
| `count` | Optional number after the label. `0` renders — "Revisiones 0" is information. |

### Clearing is a URL, not a button

The ternary in the `href` above is what replaces a Clear control: the **active**
pill points at the listing *without* its param, so clicking it again turns the
filter off. Rendering an explicit "All" pill that points at the bare listing
works too, and the two compose — the example above does both.

The component does not build these URLs for you, and that is deliberate: only
the caller knows what its params mean, whether the filter is exclusive, and
whether "off" means dropping the param or setting it to something else.

### What filtering does to everything else

Nothing, and that is the design. A pill click is an **ordinary full-page GET**:

- **The infinite scroll resets for free.** The server renders page one; there is
  no reset to perform and no state in the browser to clear.
- **The filter travels into the pages the sentinel fetches**, because the next
  URL is derived from the request the server answered. Nothing in the controller
  knows what a filter is. Measured in `cypress/e2e/split-view-list.cy.js`.
- **Back still works**, because the highlight is re-derived from the URL and
  matches on the params a row's href actually carries, ignoring the filter
  params it does not.

**Selection and filters are independent.** A row's href carries the filters, so
the selection deep-links back into the filtered listing. Filtering does not clear
the selection; if the selected record is filtered out, its detail stays and no row
is highlighted — the same state as a deep link to a record on a later page.

### One group, and why it wraps

The band is a single set of pills with one active value. It is not a filter
panel: several groups, ranges and free-text search are a different screen, and a
master column ~420px wide is the wrong place for them. A listing that needs that
much filtering wants it above the split view, or wants the `master` slot.

The band is `flex-wrap`, so pills spill onto a second line instead of running off
the edge — which is the bug that produced this design. The band it replaced held
a filter form whose controls laid out in a row, and in a 420px column they
overflowed. Eight pills in a 418px band wrap onto four lines with nothing
overflowing; measured, and pinned in the Cypress spec.

---

## When `list` does not fit

The `master` slot takes any markup at all, and is what a listing the structured
API cannot express should use — a tree, a calendar, rows with a shape of their
own. It is the same component either way: the free slot sits inside the same
controller element, so hand-written rows are its targets too.

The four attributes `with_item` writes for you become yours to write:

```erb
<% split.with_master do %>
  <%= render Bali::Card::Component.new(style: :bordered, body_class: "p-0") do %>
    <%= render "bucket_tabs" %>

    <div class="split-view-scroll">
      <% @items.each do |item| %>
        <%= link_to inbox_path(selected: item.id, **@filters),
              class: "split-view-row px-4 py-3 border-b border-b-base-200/70",
              aria: { current: (item == @selected ? "true" : nil) },
              data: {
                turbo_frame: "inbox-detail",
                split_view_target: "row",
                action: "click->split-view#select"
              } do %>
          <div class="font-medium text-sm truncate"><%= item.title %></div>
        <% end %>
      <% end %>
    </div>

    <%= render Bali::PaginationFooter::Component.new(pagy: @pagy) %>
  <% end %>
<% end %>
```

- **`class: "split-view-row"`** — the look of a row, including its selected
  state, comes from this class.
- **`aria-current` from the server** — what paints the selection on the first
  render and after any full-page navigation. The controller only covers the
  clicks in between.
- **`data-turbo-frame`** — what makes the click swap the frame instead of the
  page.
- **`data-split-view-target` + `data-action`** — what lets the controller move
  the highlight without a round trip.

**Carry the current filters in the row's href.** The href is the URL the
selection deep-links to; drop the filters and reloading that URL gives an
unfiltered list with a mysteriously selected row. `with_item` does not save you
from this one — the href is yours in both APIs.

**Do not put `data-turbo-action="advance"` on the row.** The frame already
carries it, and a link-level one wins over the frame — so it silently defeats
`advance: false`.

Infinite scroll is not available here: it is the list component that renders the
sentinel and knows where the rows go.

---

## Making the list scroll

`with_list` scrolls its own rows and takes `max_height:`. The rest of this
section is for the `master` slot, where `.split-view-scroll` is opt-in and goes
around **the part of the master that should scroll** — usually the list alone,
so tabs above it and pagination below it stay put:

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
this is composition, not a component option. In a structured list it goes in
`list.with_empty_state`; in a `master` slot, wherever the rows would have been:

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

The href and the location are matched on path plus query params **as a set**.
The location routinely carries params a row's href never had — a page number, a
sort — and lists the shared ones in another order, and comparing the two as
strings would call that a different place and drop the highlight.

---

## When the detail request fails

Two different things happen, and the error response decides which. Both are
measured against the dummy app:

- **A response that says to reload** — Rails' own exception page, or any page
  carrying `<meta name="turbo-visit-control" content="reload">` — makes Turbo
  abandon the frame and visit the URL as a whole page. The user lands on the
  error page. Loud, and usually what you want for a bug.
- **Anything else with no matching frame** — a bare 500 body, a JSON error, a
  custom error page that does not contain `<turbo-frame id="inbox-detail">` — is
  **ignored**. Turbo rejects with *"The response (500) did not contain the
  expected `<turbo-frame id="inbox-detail">` and will be ignored"*, and the pane
  keeps the detail it already had.

The second one is the case to decide about, because the screen does not look
broken: the highlight has already moved optimistically to the row that failed,
so the master says "you are on row 7" beside row 3's detail, and they disagree
until the next click. Three ways out, cheapest first:

1. **Render the error inside the frame.** If the response contains
   `<turbo-frame id="inbox-detail">` with the message in it, Turbo swaps it like
   any other reply and the pane says what went wrong. This is the only option
   that keeps the user on the screen they were on, and it is usually right when
   a failed detail is an expected outcome (gone, forbidden).
2. **Add `<meta name="turbo-visit-control" content="reload">`** to the error
   page's `<head>` — Turbo names this in the message itself — to get the
   full-page behaviour of the first case for a genuine bug.
3. **Handle `turbo:frame-missing` yourself**: `event.preventDefault()` in a
   listener and then decide (a toast, a retry, a redirect).

Bali does not choose for you, because the right answer depends on whether a
failing detail is an expected outcome on that screen or a defect.

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

- **Not a row designer.** `with_item` names the fields the two listings it was
  drawn from agree on. A row that wants a different anatomy uses the block, and
  one that wants a different *shape* uses the `master` slot — neither is a reason
  to grow another keyword.
- **Not a filter host.** Tabs and filter chips are not part of `with_list`; they
  go above the split view, or in `master` alongside a hand-rolled listing. The
  screens that need them do not agree on where they sit.
- **Not a re-render.** Never answer a row click by re-rendering the master — it
  loses the scroll position, which is the one thing this pattern exists to keep.
  That is also why infinite scroll appends rows instead of replacing the list.

---

## See also

- [Components guide](components.md#splitview) — the API reference.
- `Bali::EmptyState` — the empty states above.
- `Bali::PaginationFooter` — what the list renders for a reader without
  JavaScript, and what a hand-rolled master should render itself.
