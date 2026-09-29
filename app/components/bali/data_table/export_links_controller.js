import { Controller } from '@hotwired/stimulus'

// RUBY TWIN: `Bali::DataTable::ToolbarHref::TRANSIENT_PARAMS`. A test reads this literal and
// compares it against the Ruby constant: moving it on one side without the other left the two
// halves of the same link disagreeing and nothing failed.
const TRANSIENT_PARAMS = ['page', 'clear_filters', 'clear_search']

// A filters submit responds `turbo_stream` and replaces ONLY the listing node: there is no
// visit, so Turbo does NOT fire `turbo:load` and this controller does not reconnect either —
// it lives outside the replaced node. Listening to that signal alone left the href frozen in
// exactly the case it exists for. `turbo:before-stream-render` is the one that covers that
// branch; `turbo:submit-end` covers the submit that neither navigates nor streams (a frame
// response).
const SYNC_EVENTS = ['turbo:load', 'turbo:before-stream-render', 'turbo:submit-end']

/**
 * Export Links Controller
 *
 * Keeps the export hrefs pointing at the slice the user is looking at.
 *
 * The server already paints them right on a full load or on a Turbo Drive visit, but the
 * export lives in the PageHeader's ⋯ — OUTSIDE the node that a filters submit's turbo_stream
 * replaces. Without this, the first filter leaves the href frozen with the slice from the
 * initial load: the same "I exported what was filtered and took everything" bug, silently
 * again.
 *
 * `filters#_submit` pushes the new URL to the history BEFORE sending the form, so by the time
 * any of the SYNC_EVENTS arrives `location.search` already describes the new slice. It also
 * covers Turbo's cache restoration, where the snapshot can bring hrefs from another visit.
 *
 *   <div data-controller="export-links">
 *     <a data-export-links-target="link" href="/movies?format=csv">CSV</a>
 *   </div>
 */
export default class extends Controller {
  static targets = ['link']

  // `false` when the server painted the slice by hand (see `params:` in with_export): there
  // the href is not a snapshot of the URL but a host decision.
  static values = { sync: { type: Boolean, default: true } }

  connect () {
    this.sync()
    SYNC_EVENTS.forEach(name => document.addEventListener(name, this.sync))
  }

  disconnect () {
    SYNC_EVENTS.forEach(name => document.removeEventListener(name, this.sync))
  }

  sync = () => {
    // With an explicit `params:` the host has already decided what to export —including `{}`,
    // which is the opt-out for "exporting everything on purpose"—, so guessing it from the URL
    // undoes that as soon as Stimulus boots, with nothing to give it away.
    if (!this.syncValue) return

    const current = new URLSearchParams(window.location.search)

    this.linkTargets.forEach((link) => {
      const url = new URL(link.href, window.location.origin)
      const format = url.searchParams.get('format')
      // Without `format` the link is not an export link: there is nothing to preserve and
      // rewriting it would turn it into a copy of the current URL.
      if (!format) return

      link.href = this.mergedHref(url, current, format)
    })
  }

  /**
   * The SAME merge `ToolbarHref#build_toolbar_href` does in Ruby: the browser URL overwrites
   * the whole key (like `Hash#merge`, without interleaving values of a repeated key), but what
   * the host put in `url:` and the browser does not carry survives. Replacing one's query
   * string erased it: a `url: exports_path(kind: :movies)` came out without `kind` and the
   * export pointed at another set — the opposite of what the server had served.
   */
  mergedHref (url, current, format) {
    const merged = new URLSearchParams(url.search)

    for (const key of new Set(current.keys())) {
      merged.delete(key)
      current.getAll(key).forEach(value => merged.append(key, value))
    }
    // They are dropped from the MERGED result, like Ruby's `.except`: a `page` coming from
    // the host's `url:` exports one page just as if it came from the browser.
    TRANSIENT_PARAMS.forEach(key => merged.delete(key))
    merged.set('format', format)

    url.search = merged.toString()
    return url.toString()
  }
}
