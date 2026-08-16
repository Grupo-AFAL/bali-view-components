import { Controller } from '@hotwired/stimulus'

export class CarouselController extends Controller {
  static values = {
    type: { type: String, default: 'carousel' },
    startAt: { type: Number, default: 0 },
    perView: { type: Number, default: 1 },
    autoplay: { type: String, default: 'false' },
    gap: { type: Number, default: 0 },
    focusAt: { type: String, default: 'center' },
    breakpoints: Object,
    peek: Object
  }

  async connect () {
    const { default: Glide } = await import('@glidejs/glide')

    const options = {
      type: this.typeValue,
      startAt: this.startAtValue,
      perView: this.perViewValue,
      autoplay: this.autoplayValue === 'false' ? false : this.autoplayValue,
      gap: this.gapValue,
      focusAt:
        this.focusAtValue === 'center' ? 'center' : parseInt(this.focusAtValue)
    }

    if (this.hasBreakpointsValue) {
      options.breakpoints = this.breakpointsValue
    }

    if (this.hasPeekValue) {
      options.peek = this.peekValue
    }

    this.glide = new Glide(this.element, options)
    // Same two events Glide's own controls listen to, so the class and the
    // attribute always move together.
    this.glide.on(['mount.after', 'move.after'], this.syncBulletSelection)
    this.glide.mount()
  }

  disconnect () {
    if (!this.glide) return

    this.glide.destroy()
  }

  // Glide moves a class onto the active bullet and touches nothing else. The
  // bullets are a `role=tablist`, where `aria-selected` is the whole answer to
  // "which slide am I on": left to Glide it stays on the first bullet forever,
  // so a screen reader announces slide 1 as the current one no matter which is
  // showing (WCAG 4.1.2).
  syncBulletSelection = () => {
    const bullets = this.element.querySelectorAll(
      '[data-glide-el="controls[nav]"] [data-glide-dir]'
    )

    bullets.forEach((bullet, index) => {
      bullet.setAttribute('aria-selected', String(index === this.glide.index))
    })
  }
}
