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
  it will hit the same wall. `topLayerHost` and `enterTopLayer` are exported for that; they
  are not private to the package.

## What is not covered yet

`Modal` and `Drawer` are still ordinary positioned elements at `--bali-z-modal` and
`--bali-z-drawer`; they do not use `showModal()` yet. `ConfirmDialog` is the one overlay in
the package that is already a modal `<dialog>`, and it holds nothing but text and two
buttons, so no popup ever opens inside it.

The BlockNote portals inside `BlockEditor` and `Status`' panel read `--bali-z-popover` and
are not wired to this utility. They are not reachable from inside a modal dialog today, and
wiring them without a case to measure against would be guessing.
