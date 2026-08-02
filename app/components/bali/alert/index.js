import { Controller } from '@hotwired/stimulus'

const STORAGE_PREFIX = 'bali:alert:dismissed:'

/**
 * Alert Controller
 *
 * Drives every dismissal a `Bali::Alert` (and therefore a `Bali::Toast`) can have:
 *
 *   - the close button, through the `dismiss` action;
 *   - a `dismissId` value, which remembers the dismissal in localStorage so the
 *     alert stays hidden on later page loads;
 *   - a `duration` value in milliseconds, which closes the alert on its own.
 *
 * The element leaves on a timer read from its own computed animation, never on
 * `animationend`. The v2 controller waited for that event, and it does not always
 * arrive: Chrome freezes CSS animations in a background tab, so a toast opened in
 * a tab the user then switched away from stayed on screen indefinitely (measured:
 * `playState: "running"`, `currentTime: 0` seventeen seconds in). The same hang
 * happened in any host whose CSS did not carry the animation at all -- which was
 * every host before the keyframes landed in the package, and is still any host
 * that overrides the leaving class with a name it never styled.
 *
 * Reading the duration back from the CSS is also what makes
 * `prefers-reduced-motion` work without a branch here: the stylesheet zeroes the
 * animation, the computed duration comes back as 0s, and the element goes at once.
 */
export class AlertController extends Controller {
  static classes = ['leaving']

  static values = {
    dismissId: String,
    duration: Number
  }

  connect () {
    if (this.dismissed) return this.hide()

    if (this.durationValue > 0) {
      this.closeTimer = setTimeout(() => this.close(), this.durationValue)
    }
  }

  disconnect () {
    clearTimeout(this.closeTimer)
    clearTimeout(this.removalTimer)
  }

  dismiss () {
    if (this.persistent) localStorage.setItem(this.storageKey, 'true')

    this.close()
  }

  close () {
    if (this.closing) return

    this.closing = true
    clearTimeout(this.closeTimer)

    if (!this.hasLeavingClass) return this.remove()

    this.element.classList.add(...this.leavingClasses)
    this.removalTimer = setTimeout(() => this.remove(), this.leavingDuration)
  }

  remove () {
    this.element.remove()
  }

  hide () {
    this.element.hidden = true
  }

  /**
   * How long the leaving animation lasts, in milliseconds, according to the
   * styles that are on the element right now. Reading it after the class is
   * added forces the style recalculation, so the value is the post-class one.
   */
  get leavingDuration () {
    const styles = getComputedStyle(this.element)

    return toMilliseconds(styles.animationDuration) + toMilliseconds(styles.animationDelay)
  }

  get persistent () {
    return this.hasDismissIdValue && this.dismissIdValue.length > 0
  }

  get dismissed () {
    return this.persistent && localStorage.getItem(this.storageKey) === 'true'
  }

  get storageKey () {
    return `${STORAGE_PREFIX}${this.dismissIdValue}`
  }
}

/**
 * The longest time in a CSS time list. `animation-duration` is a list because an
 * element can run several animations at once, and the element is only gone once
 * the slowest has finished.
 */
function toMilliseconds (value) {
  const times = String(value)
    .split(',')
    .map(time => {
      const seconds = parseFloat(time)

      if (isNaN(seconds)) return 0

      return time.trim().endsWith('ms') ? seconds : seconds * 1000
    })

  return Math.max(0, ...times)
}
