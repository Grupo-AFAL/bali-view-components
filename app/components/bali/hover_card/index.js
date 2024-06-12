import { Controller } from '@hotwired/stimulus'
import useDispatch from 'bali/utils/use-dispatch'

const ARROW_SVG = `
<svg width="14" height="8" viewBox="0 0 14 8" fill="none">
  <path d="M14 8L7 8L0 8L7 0L14 8Z" fill="white"/>
  <path d="M7 0.759296L12.8981 7.5L7 7.5L1.10188 7.5L7 0.759296Z" stroke="#1C1817" stroke-opacity="0.2"/>
  <path d="M2.20708 7H11.7911L12.8 8H1.39999L2.20708 7Z" fill="white"/>
</svg>
`

/*
  Hovercard controller:
    It generates a hovercard component to show some content
    obtained via a fetch request or template.
*/
export class HovercardController extends Controller {
  static classes = ['content']
  static targets = ['template', 'trigger']
  static values = {
    url: String,
    placement: { type: String, default: 'auto' },
    trigger: { type: String, default: 'mouseenter focus' },
    contentPadding: { type: Boolean, default: true },
    appendTo: { type: String, default: 'body' },
    zIndex: { type: Number, default: 9999 }
  }

  async connect () {
    useDispatch(this)

    this.contentLoaded = false

    const content = this.hasTemplateTarget ? this.templateTarget.innerHTML : ''

    const { default: tippy } = await import('tippy.js')

    this.tippy = tippy(this.triggerTarget, {
      allowHTML: true,
      arrow: ARROW_SVG,
      duration: 100,
      appendTo: this.appendToProp(),
      content,
      placement: this.placementValue,
      trigger: this.triggerValue,
      interactive: true,
      zIndex: this.zIndexValue,
      onTrigger: this.onTrigger,
      onCreate: this.onCreate,
      onShow: this.onShow,
      onHide: this.onHide
    })
  }

  appendToProp () {
    if (this.appendToValue === 'body') return () => document.body
    if (this.appendToValue === 'parent') return 'parent'

    return document.querySelector(this.appendToValue)
  }

  disconnect () {
    this.tippy?.destroy()
  }

  onCreate = instance => {
    if (this.hasContentClass) {
      instance.popper.classList.add(...this.contentClasses)
    } else {
      instance.popper.classList.add('hover-card-tippy-wrapper')
    }
  }

  onTrigger = () => {
    if (this.hasUrlValue && this.urlValue.length > 0 && !this.contentLoaded) {
      this.loadContent()
    }
  }

  onShow = () => {
    this.element.classList.add('is-active')
    this.dispatch('show', { tippy: this.tippy })
  }

  onHide = () => {
    this.element.classList.remove('is-active')
    this.dispatch('hide', { tippy: this.tippy })
  }

  async loadContent () {
    const response = await fetch(this.urlValue)
    let html = await response.text()

    if (this.contentPaddingValue) {
      html = `<div class="hover-card-content">${html}</div>`
    }

    this.tippy.setContent(html)
    this.contentLoaded = true
  }
}
