import { Controller } from '@hotwired/stimulus'

export class TooltipController extends Controller {
  static targets = ['content', 'trigger']
  static values = {
    placement: { type: String, default: 'top' },
    trigger: { type: String, default: 'mouseenter focus' }
  }

  async connect () {
    if (this.contentTarget.content.textContent.trim().length === 0) return

    const { default: tippy } = await import('tippy.js')

    this.tippy = tippy(this.triggerTarget, {
      allowHTML: true,
      appendTo: 'parent',
      content: this.contentTarget.content,
      placement: this.placementValue,
      trigger: this.triggerValue,
      arrow: true,
      offset: [0, 24]
    })
  }

  disconnect () {
    if (!this.tippy) return

    this.tippy.destroy()
  }
}
