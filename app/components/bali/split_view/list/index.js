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

    this.mergeGroups(rows)
    this.rowsTarget.append(...rows.children)

    // The next page is read back out of the page we just fetched rather than
    // incremented here: the server owns what "next" means, including running out.
    this.nextUrlValue = list.dataset.splitViewListNextUrlValue || ''
    if (!this.nextUrlValue) {
      this.showState('end')
      this.observer?.unobserve(this.sentinelTarget)
    }
  }

  // A grouped listing arrives as its own set of groups, and the first of them is
  // usually the group the list already ends with — the page boundary fell inside
  // it. Left alone that renders the heading twice, one per page.
  //
  // ONLY the seam is merged: the last group on screen against the first group
  // that arrived. A repeat anywhere else means the listing is not ordered by its
  // group (`order(:kind, …)`, the key first), and moving those rows up under an
  // earlier heading would silently reorder what the server sent — a worse bug
  // than a repeated heading, and a much quieter one. So it is left visible and
  // named in the console instead.
  //
  // An ungrouped listing has no keys, falls through both branches, and appends
  // exactly as it did before.
  mergeGroups (incoming) {
    const first = incoming.firstElementChild
    const key = first?.dataset.splitViewGroupKey
    const last = this.rowsTarget.lastElementChild

    if (key && key === last?.dataset.splitViewGroupKey) {
      const into = last.querySelector('.split-view-group-rows')
      const from = first.querySelector('.split-view-group-rows')
      if (into && from) {
        into.append(...from.children)
        // Removed before the caller appends what is left, so the heading that
        // was merged away does not come along with it.
        first.remove()
      }
    }

    this.warnAboutScatteredGroups(incoming)
  }

  warnAboutScatteredGroups (incoming) {
    const seen = new Set(
      [...this.rowsTarget.children].map(group => group.dataset.splitViewGroupKey).filter(Boolean)
    )
    const repeated = [...incoming.children]
      .map(group => group.dataset.splitViewGroupKey)
      .filter(key => key && seen.has(key))

    if (repeated.length === 0) return

    console.warn(
      `[split-view-list] the appended page repeats ${repeated.join(', ')}, which means the ` +
      'listing is not ordered by its group key. Order it by the key first ' +
      '(`order(:kind, :created_at)`) or the same heading will show up once per page.'
    )
  }

  showState (name) {
    ;['loader', 'end', 'error'].forEach((state) => {
      this[`${state}Targets`].forEach((element) => { element.hidden = state !== name })
    })
  }
}
