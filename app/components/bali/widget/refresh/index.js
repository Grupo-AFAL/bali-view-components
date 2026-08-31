import { Controller } from '@hotwired/stimulus'

// KEEPS ONE CARD CURRENT. The card asks the server for itself, the server answers
// with a turbo-stream replacing this same element, and Turbo swaps it — the same
// exchange a resize already uses, minus the write.
//
// ON THE CARD rather than on the grid, so a widget rendered outside a dashboard
// still refreshes. It costs one timer per refreshing card, which is affordable
// because `refresh_every` is opt-in: a dashboard marks the two tiles that go
// stale, not all seventeen. If that stops being true, the endpoint already takes
// `keys[]`, so batching is a change in here and nowhere else.
//
// REPLACING THIS ELEMENT DISCONNECTS THIS CONTROLLER. The replacement carries the
// same attributes, so Stimulus connects a fresh instance and the next tick is
// scheduled there — which is why this uses `setTimeout` and re-arms rather than
// `setInterval`. An interval on a soon-to-be-destroyed controller would keep the
// old timer alive across the swap until GC, double-firing for a beat.
export class WidgetRefreshController extends Controller {
  static values = {
    url: String,
    // Milliseconds. Ruby converts, so no unit maths happens on this side.
    interval: Number
  }

  connect () {
    this.inFlight = false
    // Bound once so `removeEventListener` in `disconnect` can find it again.
    this.onVisibility = () => this.visibilityChanged()
    document.addEventListener('visibilitychange', this.onVisibility)
    this.schedule()
  }

  disconnect () {
    clearTimeout(this.timer)
    document.removeEventListener('visibilitychange', this.onVisibility)
  }

  // A HIDDEN TAB IS THE WHOLE COST. A dashboard left open in a background tab
  // would otherwise poll for hours against a screen nobody is looking at.
  // Browsers throttle background timers but do not stop them, so this is not
  // something the platform handles for us.
  //
  // Refreshing immediately on RETURN rather than waiting out the interval: the
  // card the user is looking at is the stale one, and they came back to read it.
  visibilityChanged () {
    clearTimeout(this.timer)
    if (document.hidden) return

    this.refresh()
  }

  schedule () {
    clearTimeout(this.timer)
    if (this.intervalValue <= 0) return

    this.timer = setTimeout(() => this.refresh(), this.intervalValue)
  }

  // THE FOUR REASONS TO SKIP A TICK, all of which re-arm rather than stopping —
  // a refresh is never urgent, so deferring is always the cheap answer.
  //
  //   hidden      nobody is looking; `visibilitychange` refreshes on return
  //   editing     the grid is mid-drag. Replacing a card here fights SortableJS,
  //               which is tracking these exact nodes, and would drop the one
  //               under the pointer
  //   in flight   a slow server must not accumulate a queue of stale requests
  //   focus here  a replaced element takes focus to `<body>` with it. The grid
  //               restores focus after a RESIZE because the user asked for that
  //               one; nobody asked for this, so it waits instead
  skip () {
    return document.hidden ||
      this.element.closest('.editing') !== null ||
      this.inFlight ||
      this.element.contains(document.activeElement)
  }

  async refresh () {
    if (this.skip()) return this.schedule()

    this.inFlight = true

    try {
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.append('keys[]', this.element.dataset.widgetKey)

      const response = await fetch(url, {
        headers: { Accept: 'text/vnd.turbo-stream.html' },
        // A poll must never be served from cache, and `no-store` also keeps it
        // out of the back/forward cache a later navigation would read.
        cache: 'no-store'
      })

      if (response.ok) await this.renderStream(response)
    } catch (error) {
      // SILENT BY DESIGN, unlike the grid's writes. A failed save loses work the
      // user did and has to be announced; a failed refresh loses nothing — the
      // card keeps showing the last good answer, which is still true, just older.
      // Announcing it would interrupt a screen-reader user over nothing.
      console.error(error)
    } finally {
      this.inFlight = false
    }

    // `isConnected` because a successful refresh has already replaced this
    // element: the new controller schedules its own tick, and re-arming here
    // would leave a detached duplicate running.
    if (this.element.isConnected) this.schedule()
  }

  // Its own method so a test can observe it, and matching the grid's.
  async renderStream (response) {
    if (!window.Turbo) return

    const body = await response.text()
    if (body?.includes('<turbo-stream')) window.Turbo.renderStreamMessage(body)
  }
}
