import { Controller } from '@hotwired/stimulus'

/**
 * NumberFormat Controller
 *
 * Groups the thousands of a numeric text input while it is being typed:
 * `1500200` reads `1,500,200` keystroke by keystroke, and the caret stays where
 * the typist left it instead of jumping to the end of the field.
 *
 *   <input type="text" inputmode="decimal"
 *          data-controller="number-format"
 *          data-number-format-delimiter-value=","
 *          data-number-format-separator-value=".">
 *
 * Both separators arrive as values instead of being resolved here, and that is
 * the whole reason this controller takes any configuration at all. `Intl` would
 * read them from the *browser's* locale, while the value it produces has to
 * survive `Bali::Concerns::NumericAttributesWithCommas`, which parses it with
 * Rails'. Someone on an English browser filling a Spanish form would have had
 * the two halves disagree about which character is the decimal point — the
 * failure that concern was written to end, reintroduced one layer up.
 *
 * Mounted for you by `f.currency_group`, `f.percentage_group` and their bare
 * halves; `f.number_group` takes `delimited: true` to opt in.
 *
 * The element has to be an input with a caret. A `type="number"` input refuses
 * to store a value holding a delimiter — the browser hands back the empty
 * string and reports no `selectionStart` — so there is nothing here it could do.
 */
export class NumberFormatController extends Controller {
  static values = {
    delimiter: { type: String, default: ',' },
    separator: { type: String, default: '.' }
  }

  connect () {
    if (!this.formattable) {
      console.warn(
        `[bali] number-format needs an input with a caret; ${this.describeElement()} has none, ` +
        'so it cannot hold a thousands delimiter. Leaving the field alone.'
      )
      return
    }

    this.element.addEventListener('keydown', this.deleteAcrossDelimiter)
    this.element.addEventListener('input', this.format)
    this.element.addEventListener('blur', this.completeHalfTypedDecimal)

    this.adoptServerValue()
  }

  disconnect () {
    this.element.removeEventListener('keydown', this.deleteAcrossDelimiter)
    this.element.removeEventListener('input', this.format)
    this.element.removeEventListener('blur', this.completeHalfTypedDecimal)
  }

  // A caret position, not merely a non-null one: `selectionStart` is `null` on
  // every input type that has no caret to report — `number`, `date`, `color`,
  // which are exactly the types that also refuse to store a delimited value —
  // and `undefined` on anything that is not a form control at all. Testing
  // against `null` alone would let a `<div>` through and throw on `value`.
  get formattable () {
    return typeof this.element.selectionStart === 'number'
  }

  describeElement () {
    const tag = this.element.tagName.toLowerCase()

    return this.element.type ? `<${tag} type="${this.element.type}">` : `<${tag}>`
  }

  // Arrow functions throughout: these are handed to addEventListener, so `this`
  // has to stay bound to the controller.

  format = () => {
    const input = this.element
    const typed = this.stableCount(input.value.slice(0, input.selectionStart))
    const grouped = this.grouped(input.value)

    // Nothing moved, so nothing is touched. Reassigning `value` here would reset
    // the caret to the end of the field on every keystroke that needs no
    // regrouping — which is most of them.
    if (grouped === input.value) return

    input.value = grouped

    if (document.activeElement !== input) return

    const caret = this.caretAfter(grouped, typed)
    input.setSelectionRange(caret, caret)
  }

  /**
   * Backspace over a delimiter looks broken without this: the delimiter is
   * deleted, the digits regroup, and the same delimiter reappears in the same
   * place. The key seems to do nothing, and holding it down does nothing
   * forever. So a deletion aimed at a delimiter is redirected at the digit
   * behind it, which is what the typist meant.
   */
  deleteAcrossDelimiter = (event) => {
    const backspace = event.key === 'Backspace'
    if (!backspace && event.key !== 'Delete') return

    const input = this.element
    // A selection deletes exactly what it covers, delimiters included.
    if (input.selectionStart !== input.selectionEnd) return

    const target = backspace ? input.selectionStart - 1 : input.selectionStart
    if (input.value[target] !== this.delimiterValue) return

    event.preventDefault()

    const digit = backspace ? target - 1 : target + 1
    if (digit < 0 || digit >= input.value.length) return

    input.value = input.value.slice(0, digit) + input.value.slice(digit + 1)
    input.setSelectionRange(digit, digit)

    // Reformats through the listener above, and lets everything else watching
    // the field — an autosave, a `submit-on-change` — see the edit it would
    // otherwise miss, since assigning `value` fires no event of its own.
    input.dispatchEvent(new Event('input', { bubbles: true }))
  }

  /**
   * `1.` and `.5` are both reasonable things to have half-typed, and both are
   * rejected by the `pattern` the FormBuilder puts on the field. Completing them
   * on the way out beats letting the typist discover it at submit time, from a
   * browser bubble that only says the format is wrong.
   */
  completeHalfTypedDecimal = () => {
    const separator = this.separatorValue
    const input = this.element
    let value = input.value

    if (value.endsWith(separator)) value = value.slice(0, -separator.length)

    const sign = value.startsWith('-') ? '-' : ''
    const body = value.slice(sign.length)
    if (body.startsWith(separator)) value = `${sign}0${body}`

    if (value === input.value) return

    input.value = value
    input.dispatchEvent(new Event('input', { bubbles: true }))
  }

  /**
   * Rails renders a decimal as a machine number — `1500200.75`, a dot, whatever
   * the locale. Grouping that as typed input would be a silent corruption
   * wherever the dot is the *delimiter*: in Spanish it would be dropped as noise
   * and the field would display, then resubmit, `150.020.075`. So the dot is
   * translated to the locale's separator first.
   *
   * Only a machine-shaped value is touched. A field re-rendered after a failed
   * validation holds whatever the typist actually entered, and regrouping that
   * would delete the very characters that made it invalid — leaving them staring
   * at a plausible number underneath an error message explaining it is not one.
   */
  adoptServerValue () {
    if (!/^-?\d+(\.\d+)?$/.test(this.element.value)) return

    // Replaced through a function, like `delimit` below: a `$` in a replacement
    // string is a back-reference, and a separator is not the place to find out.
    this.element.value = this.grouped(
      this.element.value.replace('.', () => this.separatorValue)
    )
  }

  /**
   * The field as it should read: a leading minus, the integer digits in groups
   * of three, and at most one decimal separator. Everything else the typist
   * produced was either a delimiter they typed themselves or a slip.
   */
  grouped (value) {
    const sign = value.startsWith('-') ? '-' : ''
    const [integer, ...rest] = this.digitsAndSeparators(value).split(this.separatorValue)
    const body = `${sign}${this.delimit(integer)}`

    // A second separator is dropped rather than honoured: `1.2.3` is not a
    // number, and treating the extra one as a delimiter is the reading that
    // keeps the digits.
    if (rest.length === 0) return body

    return `${body}${this.separatorValue}${rest.join('')}`
  }

  delimit (digits) {
    return digits.replace(/\B(?=(\d{3})+(?!\d))/g, () => this.delimiterValue)
  }

  /** The number under the formatting: the digits and the decimal separators. */
  digitsAndSeparators (value) {
    return [...value].filter(char => /\d/.test(char) || char === this.separatorValue).join('')
  }

  /**
   * Where the caret goes after regrouping: past the same stable characters it
   * was past before. The delimiters are the characters that move, so counting
   * those is what makes a caret drift toward the end of the field, one position
   * per group, as the amount grows.
   */
  caretAfter (value, count) {
    if (count === 0) return 0

    let seen = 0
    for (let index = 0; index < value.length; index++) {
      if (this.isStable(value[index])) seen++
      if (seen === count) return index + 1
    }

    return value.length
  }

  stableCount (value) {
    return [...value].filter(char => this.isStable(char)).length
  }

  // What grouping keeps, in the order it keeps it: the sign, the digits and the
  // decimal separator. Everything else in the field is a delimiter this
  // controller put there and is free to move.
  isStable (char) {
    return /\d/.test(char) || char === this.separatorValue || char === '-'
  }
}
