import { Controller } from '@hotwired/stimulus'
import tippy from 'tippy.js'

export class TooltipController extends Controller {
  static targets = ['content', 'trigger']
  static values = {
    placement: { type: String, default: 'top' },
    trigger: { type: String, default: 'mouseenter focus' }
  }

  connect () {
    if (this.contentTarget.content.textContent.trim().length === 0) return

    this.tippy = tippy(this.triggerTarget, {
      allowHTML: true,
      appendTo: 'parent',
      content: this.contentTarget.content,
      placement: this.placementValue,
      trigger: this.triggerValue
    })
  }

  disconnect () {
    if (!this.tippy) return

    this.tippy.destroy()
  }
}
