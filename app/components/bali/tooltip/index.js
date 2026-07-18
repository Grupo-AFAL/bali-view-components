import { Controller } from '@hotwired/stimulus'

export class TooltipController extends Controller {
  static targets = ['content', 'trigger']
  static values = {
    placement: { type: String, default: 'top' },
    trigger: { type: String, default: 'mouseenter focus' },
    appendTo: { type: String, default: 'parent' }
  }

  async connect () {
    if (this.contentTarget.content.textContent.trim().length === 0) return

    const { default: tippy } = await import('tippy.js')

    this.tippy = tippy(this.triggerTarget, {
      allowHTML: true,
      appendTo: this.appendToOption,
      content: this.contentTarget.content,
      placement: this.placementValue,
      trigger: this.triggerValue,
      theme: 'bali',
      arrow: true,
      offset: [0, 24]
    })
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
    if (!this.tippy) return

    this.tippy.destroy()
  }
}
