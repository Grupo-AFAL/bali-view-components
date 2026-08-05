// Keeps a portaled popup usable when the field that opens it sits inside an
// overlay that lives in the top layer.
//
// A `<dialog>` shown with `showModal()` paints above the whole document and
// above every z-index, and it makes every node outside its own subtree inert.
// Widgets that portal their popup to `<body>` — flatpickr's calendar,
// SlimSelect's list, tippy's balloon, ImageGrid's lightbox — therefore lose
// twice over: the popup is painted under the overlay AND it stops receiving
// pointer events.
//
// Measured on Chrome over `bali/drawer/dirty_form`, hit-testing the centre of a
// `.flatpickr-day` with `document.elementFromPoint` while a sibling `<dialog>`
// was open:
//
//   calendar under <body>, no dialog       SPAN.flatpickr-day   clickable
//   calendar under <body>, dialog open     DIALOG.modal         covered
//   calendar under <body> + showPopover()  DIALOG.modal         still covered —
//       and `elementsFromPoint` returns `[DIALOG, HTML]`, so the calendar is not
//       in the hit-test stack at all. The top layer does not lift a node out of
//       the inertness a modal dialog imposes on everything outside itself.
//   calendar moved into the <dialog>       SPAN.flatpickr-day   clickable at
//       scroll offset 0, but 900px off-screen once the page behind is scrolled
//       (`showModal()` does not lock that scroll).
//   calendar moved in + showPopover()      SPAN.flatpickr-day   clickable at any
//       scroll offset.
//
// So the two halves fix different failures and neither one is optional:
//
//   * moving the node into the overlay's subtree is what defeats the inertness;
//   * `showPopover()` is what restores the coordinate system. Both widgets
//     position their popup in document coordinates (`window.scrollY + rect.top`),
//     which is right for a child of `<body>` and wrong for a child of a
//     `position: fixed` dialog. An element in the top layer resolves
//     `position: absolute` against the initial containing block again, so the
//     numbers the widget already wrote become correct without patching either
//     library's arithmetic. It also lifts the popup clear of the panel's
//     `overflow-y: auto`, which would otherwise clip it.
//
// Outside a top-layer overlay nothing happens: `topLayerHost` returns null, the
// caller leaves the widget exactly as it was, and the stacking scale in
// `z_index.css` keeps meaning what it says.

// `:modal` and `:popover-open` are what this file is built on, and a browser
// without them has no top layer to join either. Probing once keeps a missing
// selector from throwing inside a widget's open hook.
let selectorsSupported

function supported () {
  if (selectorsSupported === undefined) {
    try {
      document.documentElement.matches(':modal, :popover-open')
      selectorsSupported = true
    } catch {
      selectorsSupported = false
    }
  }

  return selectorsSupported
}

// The nearest ancestor overlay that is in the top layer, or null. Only modal
// dialogs qualify: a `<dialog>` opened with `show()` is an ordinary positioned
// box that the stacking scale already orders, and moving popups into it would
// buy nothing but the clipping.
export function topLayerHost (element) {
  if (!supported() || !(element instanceof window.Element)) return null

  let dialog = element.closest('dialog')

  while (dialog) {
    if (dialog.matches(':modal')) return dialog
    dialog = dialog.parentElement?.closest('dialog') ?? null
  }

  return null
}

// Moves `popup` into `host` and puts it in the top layer. Returns false when the
// browser has no Popover API, which is the signal to leave the widget alone
// rather than reparent it half-way: a reparented popup with no top layer is
// worse than an untouched one, because it inherits the dialog's fixed
// containing block and lands off-screen on a scrolled page.
export function enterTopLayer (popup, host) {
  if (!popup || !host || !supported()) return false
  if (typeof popup.showPopover !== 'function') return false

  try {
    if (popup.parentElement !== host) host.appendChild(popup)
    if (!popup.hasAttribute('popover')) popup.setAttribute('popover', 'manual')
    // `manual` and not `auto`: light dismiss would fight the widget's own
    // outside-click handling, and closing on Escape is the guard Modal and
    // Drawer already implement around flatpickr.
    if (!popup.matches(':popover-open')) popup.showPopover()

    return true
  } catch {
    return false
  }
}

// Idempotent, and safe on a popup that never entered: the widget's own close
// path calls this without knowing whether the field was inside an overlay.
export function leaveTopLayer (popup) {
  if (!popup || !supported()) return
  if (typeof popup.hidePopover !== 'function') return

  try {
    if (popup.matches(':popover-open')) popup.hidePopover()
  } catch {
    // Detached or never a popover; there is nothing to leave.
  }
}
