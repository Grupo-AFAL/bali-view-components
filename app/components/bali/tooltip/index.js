import { Controller } from '@hotwired/stimulus'
import zIndexFor from '../../../assets/javascripts/bali/utils/z-index.js'
import { topLayerHost } from '../../../assets/javascripts/bali/utils/top-layer.js'

// Anything the browser puts in the tab order on its own. A trigger slot holding one of
// these already has a keyboard route to the tooltip; a slot holding plain text does not.
const FOCUSABLE = [
  'a[href]',
  'button',
  'input',
  'select',
  'textarea',
  'summary',
  '[contenteditable]',
  '[tabindex]:not([tabindex="-1"])'
].join(', ')

export class TooltipController extends Controller {
  static targets = ['content', 'trigger']
  static values = {
    placement: { type: String, default: 'top' },
    // See Bali::Tooltip::Component::DEFAULT_TRIGGER for why this is `focusin`.
    trigger: { type: String, default: 'mouseenter focusin' },
    appendTo: { type: String, default: 'parent' }
  }

  async connect () {
    if (this.isEmpty) return

    this.makeTriggerFocusable()

    const { default: tippy } = await import('tippy.js')

    this.tippy = tippy(this.triggerTarget, {
      allowHTML: true,
      appendTo: this.appendToOption,
      content: this.balloonContent,
      placement: this.placementValue,
      trigger: this.triggerValue,
      theme: 'bali',
      arrow: true,
      offset: [0, 24],
      zIndex: zIndexFor('tooltip')
    })
  }

  // A copy, because tippy MOVES what it is handed: `setContent` runs `appendChild` on
  // anything that is an Element or a Fragment (tippy.esm.js:491-502), so handing it
  // `template.content` emptied the `<template>` on the first connect and left it empty for
  // good. Nothing noticed while the node stayed put, but the moment the same node is
  // disconnected and reconnected — a list reordered with `insertBefore`, a node pulled out
  // and put back, a morph that keeps the element and reconnects its controllers — `connect`
  // re-read a `<template>` that no longer had anything in it, `isEmpty` returned true, and
  // neither the balloon nor the tab stop was rebuilt. Measured in Chrome on
  // `bali/tooltip/help_tip`, removing the element and re-inserting it:
  //
  //                          template.content.children | tippy built | tabindex
  //   page load                                      0 |        true |      "0"
  //   after re-insert                                0 |       false |     null
  //
  // The first row is the defect on its own: the template is already empty once the first
  // connect returns. Cloning makes it the source of truth every connect reads, and the
  // three candidates measured out like this, over two connects of the same node:
  //
  //                    template survives | balloon on reconnect | nested controller connects
  //   move (before)                   no |                empty |                  1 of 2
  //   cloneNode(true)                yes |                 full |                  2 of 2
  //   template.innerHTML             yes |                 full |                  2 of 2
  //
  // Neither copy duplicates an id: a `<template>`'s content is inert and outside the
  // document, so the balloon's copy is the only one `getElementById` can reach — measured
  // 1, never 2. `cloneNode` over `innerHTML` because the string route is tippy's other
  // branch, the one guarded by `allowHTML`: with that flag off it sets `textContent` and a
  // markup-only balloon (an `<svg>`, an `<img>` — a shape #788 made explicitly supported)
  // renders as escaped text. Cloning stays on the branch this component already used, and
  // `direct_upload` and `document_editor` read their templates the same way.
  //
  // What a copy cannot carry is a listener a caller attached to a node still inside the
  // `<template>`; measured, it does not fire. That is the trade, and it is the right way
  // round: template content is inert markup the document never held, so there was no live
  // node to hold a reference to. Dropdown is the opposite case and keeps the opposite
  // symmetry on purpose — its menu IS rendered DOM the reader operates, so it moves the
  // real node and `disconnect` puts it back. Restoring on exit here would buy nothing: it
  // would leave the template empty for the whole life of the connection anyway.
  get balloonContent () {
    return this.contentTarget.content.cloneNode(true)
  }

  // `with_trigger` and no content block is a tooltip with nothing to say, and building a
  // balloon for it would open an empty box on hover and — since #776 — claim a tab stop for
  // it. So the guard is right to exist; what it measured was wrong. It asked "is there any
  // plain text?", and the component is explicitly built to carry markup: the template wraps
  // the content in a `<template>` and tippy runs with `allowHTML: true`. Balloon content
  // that is only an `<svg>`, an `<img>` or any other element has `textContent === ''`, so a
  // legitimate tooltip — an icon legend, an image preview, a sparkline — returned here and
  // was never built, silently. Measured on the emitted markup, with the newlines the ERB
  // leaves around the content:
  //
  //   content                    textContent.trim() | children | childNodes | innerHTML.trim()
  //   `<p>Plain help text</p>`                   15 |        1 |          3 |               22
  //   `<svg>…</svg>`                              0 |        1 |          3 |              166
  //   nothing                                     0 |        0 |          1 |                0
  //
  // `childNodes` cannot tell the last two apart — the empty one still holds the whitespace
  // text node from the template. `children` can, so asking for both no text AND no elements
  // keeps the genuinely empty tooltip behaving exactly as it did.
  get isEmpty () {
    const { content } = this.contentTarget

    return content.textContent.trim().length === 0 && content.children.length === 0
  }

  // A tooltip whose trigger cannot be reached by the keyboard is content that only exists
  // for a mouse (WCAG 1.4.13). The common help-tip slot — a bare `<span>?</span>` — is
  // exactly that shape: measured on `bali/tooltip/help_tip`, Chromium's accessibility tree
  // reported NO interactive element on the page at all. The wrapper becomes the tab stop
  // only when the slot brought none of its own, so a trigger built out of a button or a
  // link keeps its single stop instead of gaining a second, unnamed one in front of it.
  makeTriggerFocusable () {
    if (this.triggerTarget.hasAttribute('tabindex')) return
    if (this.triggerTarget.querySelector(FOCUSABLE)) return

    this.triggerTarget.setAttribute('tabindex', '0')
    this.addedTabIndex = true
  }

  // Resolves the `appendTo` value into a tippy.js `appendTo` option.
  // 'parent' keeps the balloon inside the trigger (default). 'body' or a
  // CSS selector portals it out of clipping ancestors.
  //
  // A modal overlay overrides all three: everything outside its subtree is inert,
  // so a balloon portaled to <body> is painted under the overlay and stops taking
  // pointer events (utils/top-layer.js carries the measurement). Unlike flatpickr
  // and SlimSelect, tippy needs no help beyond the move — Popper recomputes the
  // offsets against whatever offsetParent the balloon ends up with, and the
  // overlay root is `position: fixed`, so the arithmetic stays right by itself.
  get appendToOption () {
    const value = this.appendToValue

    if (value === 'parent') return element => topLayerHost(element) ?? element.parentNode
    if (value === 'body') return element => topLayerHost(element) ?? document.body

    return element =>
      topLayerHost(element) ?? document.querySelector(value) ?? document.body
  }

  disconnect () {
    if (this.addedTabIndex && this.hasTriggerTarget) {
      this.triggerTarget.removeAttribute('tabindex')
    }
    this.addedTabIndex = false

    if (!this.tippy) return

    this.tippy.destroy()
  }
}
