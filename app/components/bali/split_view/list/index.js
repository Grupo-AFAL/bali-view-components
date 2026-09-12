import { Controller } from '@hotwired/stimulus'

// Infinite scroll for a SplitView master listing, by fetch-and-extract: it asks the
// server for the SAME index URL one page further on, and lifts the rows out of the
// reply. No endpoint, no Turbo Stream and no serializer of its own — anything that
// can render this list can already answer the request, and the rows arrive with the
// wiring the component put on them because the server is the thing that rendered
// them.
//
// The list also renders ordinary pagination controls. They are what a reader without
// JavaScript pages with; this controller hides them on connect and takes over. That
// order matters: the controls exist in the markup and are removed by enhancement,
// rather than being summoned by a failure that never gets detected.
export class SplitViewListController extends Controller {
  static targets = ['rows', 'scroller', 'sentinel', 'pagination', 'loader', 'end', 'error']
  static values = {
    nextUrl: String,
    rowsId: String,
    // How far below the fold to start fetching. One screen of margin means the rows
    // are usually there before the reader reaches the bottom.
    rootMargin: { type: String, default: '300px' }
  }

  connect () {
    this.loading = false
    this.visible = false
    this.paginationTargets.forEach(element => { element.hidden = true })
    this.sentinelTarget.hidden = false
    this.showState('loader')

    this.observer = new IntersectionObserver(
      (entries) => {
        this.visible = entries.some(entry => entry.isIntersecting)
        if (this.visible) this.loadNext()
      },
      { root: this.hasScrollerTarget ? this.scrollerTarget : null, rootMargin: this.rootMarginValue }
    )
    this.observer.observe(this.sentinelTarget)
  }

  disconnect () {
    this.observer?.disconnect()
    this.observer = null
  }

  retry (event) {
    event?.preventDefault()
    this.showState('loader')
    this.loadNext()
  }

  async loadNext () {
    // The observer fires again while a fetch is in flight — the sentinel is still on
    // screen, and it stays there until the rows that push it down have arrived.
    if (this.loading || !this.nextUrlValue) return

    this.loading = true
    this.showState('loader')

    try {
      const response = await fetch(this.nextUrlValue, {
        headers: { Accept: 'text/html' },
        credentials: 'same-origin'
      })
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)

      this.append(await response.text())
    } catch (error) {
      // Nothing is appended and nextUrlValue is untouched, so `retry` resumes from
      // exactly where this attempt started.
      this.showState('error')
      console.error('[split-view-list] could not load the next page', error)
      return
    } finally {
      this.loading = false
    }

    // Measured: a page of rows is not always enough to push the sentinel back off
    // screen — a short page, or a pane taller than the rows it just received. The
    // observer only reports a CHANGE in intersection, so a sentinel that never
    // stopped intersecting never asks again and the list stalls one page in.
    if (this.visible && this.nextUrlValue) this.loadNext()
  }

  append (html) {
    const page = new DOMParser().parseFromString(html, 'text/html')
    const list = page.getElementById(this.rowsIdValue)
    const rows = list?.querySelector('[data-split-view-list-target="rows"]')

    if (!rows) {
      // The reply rendered, but not this list — a redirect to a login page, or an
      // index that stopped rendering the component. Appending nothing silently
      // would look identical to reaching the end.
      throw new Error(`no #${this.rowsIdValue} rows in the response`)
    }

    this.rowsTarget.append(...rows.children)

    // The next page is read back out of the page we just fetched rather than
    // incremented here: the server owns what "next" means, including running out.
    this.nextUrlValue = list.dataset.splitViewListNextUrlValue || ''
    if (!this.nextUrlValue) {
      this.showState('end')
      this.observer?.unobserve(this.sentinelTarget)
    }
  }

  showState (name) {
    ;['loader', 'end', 'error'].forEach((state) => {
      this[`${state}Targets`].forEach((element) => { element.hidden = state !== name })
    })
  }
}
