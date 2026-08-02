import { Controller } from '@hotwired/stimulus'
import zIndexFor from '../../../assets/javascripts/bali/utils/z-index.js'

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
    if (this.contentTarget.content.textContent.trim().length === 0) return

    this.makeTriggerFocusable()

    const { default: tippy } = await import('tippy.js')

    this.tippy = tippy(this.triggerTarget, {
      allowHTML: true,
      appendTo: this.appendToOption,
      content: this.contentTarget.content,
      placement: this.placementValue,
      trigger: this.triggerValue,
      theme: 'bali',
      arrow: true,
      offset: [0, 24],
      zIndex: zIndexFor('tooltip')
    })
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
  get appendToOption () {
    const value = this.appendToValue

    if (value === 'parent') return 'parent'
    if (value === 'body') return () => document.body

    return () => document.querySelector(value) || document.body
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
