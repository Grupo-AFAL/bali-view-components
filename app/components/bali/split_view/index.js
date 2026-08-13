import { Controller } from '@hotwired/stimulus'

// Whether the navigation now in flight is a back/forward rather than a new one.
// It lives at module scope because the controller instance that would remember
// it is destroyed by the very render this has to survive: Turbo replaces the
// body with the restored snapshot, and the fresh instance's `connect()` has no
// way of its own to tell a first paint from a restore. Cleared on `turbo:load`,
// which fires once every controller on the restored page has connected.
let restoringHistory = false

if (typeof window !== 'undefined') {
  window.addEventListener('popstate', () => { restoringHistory = true })
  document.addEventListener('turbo:load', () => { restoringHistory = false })
}

// The detail frame as the server first painted it, per frame id. Module scope
// for the same reason `restoringHistory` is: the instance that captured it does
// not survive the render this has to outlive. Captured only from a frame that
// has never been navigated in-page (no `src`), which is exactly the state the
// server sent — so a restore can be rewound to it. See `rewindFrameBeforeCache`.
const pristineDetail = new Map()

// Moves the master-pane row highlight when a row is clicked, so the detail
// Turbo Frame can swap without the master re-rendering — which is what keeps
// its scroll position and its selection intact.
//
// The server still paints the selection on first render and on every full-page
// navigation (a filter tab, a page of results); this controller only covers the
// in-page transitions between them.
//
// The look of a selected row comes from `.split-view-row[aria-current]` in the
// component stylesheet, so nothing here depends on class names surviving a
// Tailwind build. `selected`/`unselected` Stimulus classes are there for a host
// that wants to add its own on top:
//
//   <div data-controller="split-view"
//        data-split-view-selected-class="ring-2 ring-primary">
export class SplitViewController extends Controller {
  static targets = ['row']
  static classes = ['selected', 'unselected']
  // The detail frame's id. Not a target: the frame is the master's SIBLING, and
  // Stimulus only finds targets inside the controller element.
  static values = { frame: String }

  connect () {
    this.syncFromLocation = this.syncFromLocation.bind(this)
    this.rewindFrameBeforeCache = this.rewindFrameBeforeCache.bind(this)
    window.addEventListener('popstate', this.syncFromLocation)
    document.addEventListener('turbo:before-cache', this.rewindFrameBeforeCache)
    this.capturePristineDetail()
    // A restore that DID replace the body lands here, on the new instance.
    if (restoringHistory) this.syncFromLocation()
    // Whatever is marked right now is the selection, however it got marked.
    // Set after the restore above so it records the corrected state.
    this.selectedHref = this.rowTargets.find(row => row.hasAttribute('aria-current'))?.href ?? null
  }

  get detailFrame () {
    return this.hasFrameValue ? document.getElementById(this.frameValue) : null
  }

  // Only from a frame the server painted and nobody has navigated since: a
  // `src` means Turbo has already swapped content in, and caching THAT as the
  // pristine state would defeat the rewind below.
  //
  // Captured once per frame id and never overwritten. Since the rewind now keeps
  // the loaded detail in place (only the `src` is dropped), a restored snapshot
  // can connect with the frame holding a detail and no `src`; recapturing there
  // would replace the true empty state with that detail, and a later back to the
  // list would restore a stale record instead of the empty pane.
  capturePristineDetail () {
    if (pristineDetail.has(this.frameValue)) return

    const frame = this.detailFrame
    if (!frame || frame.hasAttribute('src')) return
    // A rewound frame carries no `src` but is NOT pristine — the stash names
    // the detail it still shows (#1029).
    if (frame.hasAttribute('data-split-view-src')) return

    pristineDetail.set(this.frameValue, frame.innerHTML)
  }

  // A frame the reader navigated in-page must not reach Turbo's snapshot cache
  // still carrying its `src` (#1012).
  //
  // A row click swaps the frame and, through the frame's own
  // `data-turbo-action="advance"`, rewrites the URL. Turbo caches the page it is
  // leaving under the OLD url — but it reads the DOM when it gets around to it,
  // and if the frame's response landed first the snapshot keeps `src` and the
  // detail. Restoring that snapshot reloads the frame (Turbo reloads any frame
  // with a `src`), the reload advances again, and the reader who pressed back is
  // thrown forward to the detail they just left. Measured: locally the snapshot
  // is taken before the response and the bug never appears; in CI it did, in
  // about a third of the runs.
  //
  // Only the `src` is stripped, NOT the content. A row-click's own advance visit
  // (`data-turbo-action="advance"`, willRender: false) fires `turbo:before-cache`
  // against the page that STAYS on screen — so wiping the detail here erased the
  // pane the reader had just opened, on every click. Dropping the `src` is what
  // #1012 needs (a src-less frame is not reloaded on restore); the loaded detail
  // is left in place, both for the surviving live pane and for a cached detail
  // URL, which restores to the right pane without a refetch. `syncFrameFromLocation`
  // resets the pane to pristine when a restore lands on a URL that selects no row.
  //
  // Keyed on the frame having a `src`, NOT on the current location: by the time
  // this fires the URL is already the detail's, so a location test would never
  // match. A server-rendered detail page carries no `src` and is left alone.
  rewindFrameBeforeCache () {
    const frame = this.detailFrame
    if (!frame || !frame.hasAttribute('src')) return

    // Stash where the pane points before dropping `src`, so a traversal that
    // lands back on this URL can recognise the pane as already right instead
    // of refetching it (#1029). Turbo strips the `src` HERE, synchronously,
    // before the controller's own popstate listener gets to compare anything —
    // without the stash a src-less pane cannot say what it shows. The stash
    // survives into the snapshot deliberately: unlike `src`, Turbo does not
    // reload a frame over a data attribute.
    frame.setAttribute('data-split-view-src', frame.getAttribute('src'))
    frame.removeAttribute('src')
  }

  // Rows appended by infinite scroll. They arrive carrying whatever selection the
  // server painted for the page they came from, which goes stale the moment the
  // reader clicks something: the page is fetched from a URL that predates the
  // click. Enforcing the live selection is what stops a second row lighting up.
  //
  // Two cases are deliberately left alone:
  //   - `selectedHref === undefined`, i.e. connect() has not run. Stimulus fires
  //     this for the rows already in the markup before connecting the controller,
  //     and those are the ones the server certainly got right.
  //   - `selectedHref === null`, i.e. nothing is selected in-page. Then the server
  //     is the only one who knows anything, and a deep link to a record on a later
  //     page depends on that: its row arrives already marked, and overruling it
  //     here would erase the highlight the appended page was fetched to deliver.
  rowTargetConnected (row) {
    if (!this.selectedHref) return

    this.applySelection(row, row.href === this.selectedHref)
  }

  disconnect () {
    window.removeEventListener('popstate', this.syncFromLocation)
    document.removeEventListener('turbo:before-cache', this.rewindFrameBeforeCache)
  }

  // Back and forward, and only those. Measured: a row click promotes the frame
  // swap to a visit, and the snapshot Turbo caches for the page being left is
  // taken between the click and the frame's response — so it holds the highlight
  // this controller had just moved next to the detail pane from BEFORE the swap.
  // Pressing back restored exactly that: a master pointing at one row, an empty
  // detail beside it.
  //
  // On a history traversal the URL is the only honest source, and it is a
  // sufficient one: each row's href IS the URL that selects it, so the highlight
  // is re-derived rather than remembered. No row matching means no selection at
  // this URL, which is what going back to the unselected list is.
  //
  // Only on a traversal. On a first paint the server's markup wins, because a
  // master can be rendered on a page whose URL is not in the rows' URL space at
  // all and deriving there would erase a correct selection.
  syncFromLocation () {
    const current = this.rowTargets.find(row => this.selectsCurrentLocation(row)) ?? null
    this.selectedHref = current?.href ?? null
    this.rowTargets.forEach(row => this.applySelection(row, row === current))
    this.syncFrameFromLocation(current)
  }

  // The other half of the rewind. A navigated frame is cached without its `src`
  // but still holding the detail it last showed, so a traversal can restore a
  // pane that no longer matches the URL:
  //
  //   - Forward to a row's own URL whose cached pane is empty (or another row's
  //     detail): point the frame at the row it belongs to and let it refetch —
  //     the request Turbo would have made had the `src` survived, now made only
  //     where it is right.
  //   - Back to a URL that selects no row (the list) while the cached pane still
  //     shows the last detail: reset it to the pristine empty state, so the list
  //     view is not left showing a stale record.
  syncFrameFromLocation (current) {
    const frame = this.detailFrame
    if (!frame) return

    if (!current) {
      const pristine = pristineDetail.get(this.frameValue)
      if (pristine !== undefined && frame.innerHTML !== pristine) {
        frame.removeAttribute('src')
        frame.removeAttribute('data-split-view-src')
        frame.innerHTML = pristine
      }
      return
    }

    // Two traps hid here (#1029). Turbo rewrites a navigated frame's `src` to
    // an ABSOLUTE URL while the row's href stays as written (usually
    // relative), so a raw string compare never matched. And by the time this
    // runs on a traversal the `src` is usually GONE — Turbo caches the page it
    // is leaving before the controller's popstate listener fires, and the
    // rewind above strips it right there — so the pane's pointer lives in the
    // stash. Either way: resolve, compare, and only refetch a pane that shows
    // something else.
    const src = frame.getAttribute('src') ?? frame.getAttribute('data-split-view-src')
    if (src && new URL(src, window.location.href).href === current.href) return

    frame.removeAttribute('data-split-view-src')
    frame.setAttribute('src', current.getAttribute('href'))
  }

  // Whether this row's href names the location we are on. Not `row.href ===
  // location.href`: the two are built by different code paths — the row by a
  // route helper, the location by whatever put it in the history — so
  // `?a=1&b=2` and `?b=2&a=1` are the same place and a string comparison calls
  // them different, losing the highlight on back. Query params are compared as
  // a set for that reason.
  //
  // Params the location has and the row does not (a page number, a filter the
  // href leaves out) do not disqualify it: the question is whether the row's
  // URL is satisfied here, not whether the two are identical. That also makes
  // path-based selection work — a row pointing at `/inbox/9` carries no params
  // and is identified by its path alone.
  selectsCurrentLocation (row) {
    const target = new URL(row.href, window.location.href)
    const here = new URL(window.location.href)

    if (target.origin !== here.origin || target.pathname !== here.pathname) return false

    return [...target.searchParams].every(
      ([key, value]) => here.searchParams.getAll(key).includes(value)
    )
  }

  select (event) {
    const clicked = event.currentTarget
    this.selectedHref = clicked.href
    this.rowTargets.forEach(row => this.applySelection(row, row === clicked))
  }

  applySelection (row, selected) {
    if (selected) {
      row.setAttribute('aria-current', 'true')
    } else {
      row.removeAttribute('aria-current')
    }

    // The plural readers, not `this.selectedClass`: a host writing two classes
    // into one attribute would otherwise reach `classList.toggle` with a space
    // in the string, which throws InvalidCharacterError.
    this.toggleClasses(row, this.selectedClasses, selected)
    this.toggleClasses(row, this.unselectedClasses, !selected)
  }

  toggleClasses (row, classes, on) {
    if (classes.length === 0) return

    on ? row.classList.add(...classes) : row.classList.remove(...classes)
  }
}
