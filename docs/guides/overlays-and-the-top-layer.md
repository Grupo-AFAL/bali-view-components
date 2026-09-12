# Overlays and the top layer

Bali orders every overlay it renders through the stacking scale in
`app/assets/stylesheets/bali/z_index.css` — `dropdown` 200, `drawer` 300, `modal` 400,
`command` 500, `popover` 600, `toast` 700, `tooltip` 800. This guide is about the one
thing that scale cannot order, and what the package does instead.

## The scale stops at the top layer

A `<dialog>` opened with `showModal()`, and any element shown with `showPopover()`, are
painted in the **top layer**. The top layer sits above the whole document and above every
`z-index` there is. `--bali-z-tooltip: 800` does not beat it. Neither would 8000.

So read the tokens as *"above every other overlay Bali renders into the document"*, not as
*"above everything"*. Inside the document the ordering is exact; against a top-layer element
there is no number that wins.

The rule that follows is the only one available: **an overlay that has to appear over
something in the top layer has to join the top layer itself.**

## Why being painted on top is only half of it

A modal dialog does a second thing that is easy to miss: it makes every node **outside its
own subtree inert**. Inert nodes take no pointer events and are skipped by hit-testing.

That is why a popup which a widget portals to `<body>` — flatpickr's calendar, SlimSelect's
list, tippy's balloon, `ImageGrid`'s lightbox — breaks in two independent ways at once
inside a modal dialog, and why fixing one of them is not enough.

Measured in Chrome on `bali/drawer/dirty_form`, hit-testing the centre of a
`.flatpickr-day` with `document.elementFromPoint` while a sibling `<dialog>` was open:

| Calendar's position | Result of the hit-test |
| --- | --- |
| under `<body>`, no dialog | `SPAN.flatpickr-day` — clickable |
| under `<body>`, dialog open | `DIALOG.modal` — covered |
| under `<body>` + `showPopover()` | `DIALOG.modal` — and `elementsFromPoint` returns `[DIALOG, HTML]`, so the calendar is not in the hit-test stack at all. The top layer does not lift a node out of the dialog's inertness. |
| moved into the `<dialog>` | `SPAN.flatpickr-day` at scroll offset 0, but 900px off-screen once the page behind is scrolled |
| moved in **and** `showPopover()` | `SPAN.flatpickr-day` — clickable at any scroll offset |

The two halves fix different failures:

- **Moving the node into the overlay's subtree** is what defeats the inertness.
- **`showPopover()`** is what restores the coordinate system. Both widgets position their
  popup in document coordinates (`window.scrollY + rect.top`), which is right for a child
  of `<body>` and wrong for a child of a `position: fixed` dialog — and `showModal()` does
  not lock the page behind it, so the offset is real. An element in the top layer resolves
  `position: absolute` against the initial containing block again, so the numbers the widget
  already wrote become correct without patching either library's arithmetic. It also lifts
  the popup clear of the panel's `overflow-y: auto`, which would otherwise clip it.

## What the package does about it

`app/assets/javascripts/bali/utils/top-layer.js` exports three functions:

- `topLayerHost(element)` — the nearest ancestor `<dialog>` that is `:modal`, or `null`.
- `enterTopLayer(popup, host)` — moves `popup` into `host` and shows it as a
  `popover="manual"` element. Returns `false` when the browser has no Popover API, which is
  the signal to leave the widget alone rather than reparent it half-way.
- `leaveTopLayer(popup)` — idempotent, and safe on a popup that never entered.

Four controllers use it, and each takes only what it needs:

| Widget | What happens inside a modal dialog |
| --- | --- |
| `datepicker-controller` (flatpickr) | The calendar joins the top layer on `onOpen` and leaves on `onClose`. Skipped when the calendar is deliberately in flow (`static`) or when the call site named its own container with an `appendTo` target. |
| `slim-select-controller` | `.ss-content` joins once, at connect. SlimSelect debounces all four of its open/close callbacks by 100 ms, so a hook that reparented there would fire long after the list was already on screen. The list is parked at `top: -9999px` while closed, so staying in the top layer shows nothing. |
| `tooltip` and `hover_card` (tippy) | The balloon is appended to the dialog instead of the configured `appendTo`. No popover: Popper recomputes its offsets against whatever `offsetParent` the balloon ends up with, and the dialog root is `position: fixed`, so the arithmetic stays right by itself. |
| `image_grid` | The lightbox is built inside the dialog and shown as a popover. It is `position: fixed; inset: 0`, so there are no offsets to keep correct. |

Two small CSS blocks — in `bali/datepicker.css` and `bali/slim_select.css` — undo the
`[popover]` rules from the UA stylesheet that those sheets do not already override:
`inset: 0`, `margin: auto`, and for the calendar `overflow: auto`, which would turn it into a
scroll container that clips its own arrow.

**Outside a modal dialog nothing happens at all.** `topLayerHost` returns `null`, every
widget behaves exactly as it did, and the stacking scale keeps meaning what it says.

## If you own the dialog

Nothing to do: put a Bali field inside your `<dialog>` and it works. The mechanism keys off
`:modal`, not off any Bali markup, so it covers a dialog your application renders just as
well as one the package will render.

Two things are worth knowing:

- A `<dialog>` opened with **`show()`** rather than `showModal()` is *not* in the top layer
  and does *not* make anything inert. It is an ordinary positioned box that the stacking
  scale already orders, so the package leaves popups inside it alone.
- If you portal an overlay of your own to `<body>` and open it from inside a modal dialog,
  it will hit the same wall. The three functions are published for exactly that:

  ```js
  import { topLayerHost, enterTopLayer, leaveTopLayer } from 'bali-view-components/utils'

  const host = topLayerHost(triggerElement)
  if (host) enterTopLayer(myPopup, host)   // on open
  leaveTopLayer(myPopup)                   // on close; idempotent, safe if it never entered
  ```

  `enterTopLayer` returns `false` when the browser has no Popover API — the signal to leave
  your widget alone rather than reparent it half-way, since a reparented popup with no top
  layer inherits the dialog's fixed containing block and lands off-screen on a scrolled page.

## Which of Bali's own overlays are in the top layer

Four, and they got there by the same route — a native `<dialog>` opened with
`showModal()`:

| Overlay | Element |
| --- | --- |
| `Modal` | the component's root is the `<dialog>` |
| `Drawer` | the component's root is the `<dialog>` |
| `Command` | a `<dialog>` inside the container, wrapping the backdrop and the panel |
| `ConfirmDialog` | a `<dialog>` built in JavaScript |

**Among themselves they no longer stack by tier.** The top layer is ordered by the sequence
things entered it, so the overlay opened *last* is on top — a command palette opened over a
drawer covers it, and so would a drawer opened over a modal. `--bali-z-drawer: 300` and
`--bali-z-modal: 400` still apply to the element, but they only decide anything for a panel
the server rendered `active:` in the moment before its controller promotes it, and in a
browser with no `<dialog>` support at all.

## Opening an overlay by name, and the local mode

`Modal` and `Drawer` open on one event each (`bali:modal:open` / `bali:drawer:open`,
dispatched on `document`), and the event comes in two shapes:

- **A broadcast** — no `detail.id`. Every *shared* overlay on the page answers. This is the
  ordinary `modal: true` / `drawer: true` trigger against the layout's `#main-modal` /
  `#main-drawer`, and it is why an overlay that belongs to one feature must opt out with
  `shared: false`: with two overlays answering the same broadcast, the one nobody closes
  afterwards stays `showModal()`-ed and the whole document behind it goes inert (#854).
- **An addressed open** — `detail.id` names the overlay, and only the one whose `<dialog>`
  has that id answers.

On top of that, a trigger can open an overlay in two modes:

| Mode | Trigger | What happens |
| --- | --- | --- |
| Remote | `modal: true` or `modal: { id: }` on a `Bali::Link` (needs the href) | `modal#open` fetches the href and swaps it into the overlay, skeleton first |
| Local | `modal: { id:, local: true }` on `Link`, `Button` or a dropdown item | `modal#openLocal` dispatches the addressed open with no content: the overlay keeps what the server rendered — no fetch |

The local mode is for the overlay whose content is already on the page — an edit form
rendered next to the row it edits. Declare that overlay addressable and unshared:

```erb
<%= render Bali::Modal::Component.new(id: 'health-modal', active: false, shared: false) do %>
  ...
<% end %>
```

`shared: false` requires the explicit `id:` (an unshared overlay only ever opens when an
event names it) and, on the modal, also renders the controller on the `<dialog>` itself —
under the page-level controller the `template` target is whichever dialog comes first in
the DOM, so an addressed open would be compared against the wrong id. The drawer always
carries its own controller; it only needs `drawer_id:` and `shared: false`. In both, the
`id:` on the trigger is mandatory — `local: true` without one raises, because the only
thing it could do is the #854 broadcast.

## What has to follow them up there

Anything the scale ranks **above** those four, because no z-index reaches over the top
layer:

- **Field popups** — flatpickr, SlimSelect, tippy, `ImageGrid` — join from inside the panel
  whose field opened them, as described above.
- **The command palette** joins as its own dialog, so ⌘K still opens over a half-filled
  drawer.
- **The toast stack** moves into the open overlay for as long as it lasts and moves back out
  on close, driven by the `toast-container` controller. The node travels but its id does
  not, so a host's `turbo_stream.append "toast-notifications"` keeps landing in the same
  place. This is what makes the usual failed-submit flow work: a 422 leaves the panel open
  by design, and the flash that comes with it would otherwise be painted underneath.

A toast that is already showing when an overlay opens is *not* pulled up after it — only
toasts that arrive while an overlay is open, plus whatever the stack is holding at that
moment. In practice a toast auto-dismisses in three seconds, so the window is small; if it
matters to you, open the overlay first.

## What is not covered

The BlockNote portals inside `BlockEditor` and `Status`' panel read `--bali-z-popover` and
are not wired to this utility. They are not reachable from inside a modal dialog today, and
wiring them without a case to measure against would be guessing.
