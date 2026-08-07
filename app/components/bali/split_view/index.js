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

  connect () {
    this.syncFromLocation = this.syncFromLocation.bind(this)
    window.addEventListener('popstate', this.syncFromLocation)
    // A restore that DID replace the body lands here, on the new instance.
    if (restoringHistory) this.syncFromLocation()
    // Whatever is marked right now is the selection, however it got marked.
    // Set after the restore above so it records the corrected state.
    this.selectedHref = this.rowTargets.find(row => row.hasAttribute('aria-current'))?.href ?? null
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
