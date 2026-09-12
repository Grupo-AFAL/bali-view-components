import { Controller } from '@hotwired/stimulus'

/**
 * Chat container controller — keeps a live conversation scrolled to the latest
 * message without taking the scrollbar away from someone reading history.
 *
 * Targets:
 *   - messages  the scrollable region, and the Turbo Stream append target
 *   - typing    zero or more typing indicators, shown/hidden by class
 *
 * Values:
 *   - threshold  px short of the bottom that still counts as "at the bottom"
 *
 * Actions:
 *   - trackPosition  bound to `scroll` on the messages element by the component
 *   - showTyping / hideTyping  for a host that drives the indicator from the page
 *     rather than from a Turbo Stream (e.g. `turbo:submit-end->chat#showTyping`)
 *
 * Whether to follow a new message has to be decided from the position the reader
 * was in BEFORE it arrived: appending grows scrollHeight while scrollTop stays
 * put, so by the time the MutationObserver runs, an element that was at the bottom
 * measures as scrolled up by exactly the height of what just arrived. Hence the
 * flag, refreshed from real scroll events — which an append does not produce.
 */
export class ChatController extends Controller {
  static targets = ['messages', 'typing']

  static values = {
    threshold: { type: Number, default: 64 }
  }

  connect () {
    if (!this.hasMessagesTarget) return

    this.atBottom = true
    this.scrollToBottom()
    // Web fonts and images can still change the height after connect, which would
    // leave the first paint a little short of the bottom.
    this.settleFrame = window.requestAnimationFrame(() => this.autoscroll())

    this.observer = new MutationObserver(() => this.autoscroll())
    this.observer.observe(this.messagesTarget, { childList: true })
  }

  disconnect () {
    window.cancelAnimationFrame(this.settleFrame)
    this.observer?.disconnect()
  }

  trackPosition () {
    this.atBottom = this.distanceFromBottom <= this.thresholdValue
  }

  autoscroll () {
    if (this.atBottom) this.scrollToBottom()
  }

  // Sending a message is an act of participation, not of reading: follow the
  // conversation down even if the reader had scrolled up.
  showTyping () {
    this.typingTargets.forEach(element => element.classList.remove('hidden'))
    this.scrollToBottom()
  }

  hideTyping () {
    this.typingTargets.forEach(element => element.classList.add('hidden'))
  }

  scrollToBottom () {
    if (!this.hasMessagesTarget) return

    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    this.atBottom = true
  }

  get distanceFromBottom () {
    const element = this.messagesTarget
    return element.scrollHeight - element.scrollTop - element.clientHeight
  }
}
