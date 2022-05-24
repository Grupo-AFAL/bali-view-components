import { Controller } from '@hotwired/stimulus'
import tippy from 'tippy.js'

export class HelpTipController extends Controller {
  static targets = ['content', 'trigger']
  static values = {
    placement: { type: String, default: 'top' },
    trigger: { type: String, default: 'mouseenter focus' }
  }

  connect () {
    tippy(this.triggerTarget, {
      allowHTML: true,
      appendTo: 'parent',
      content: this.contentTarget.content,
      placement: this.placementValue,
      trigger: this.triggerValue
    })
  }
}
