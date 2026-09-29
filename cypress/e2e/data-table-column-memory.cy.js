// The column selector's per-device memory records the user's DECISIONS, and a decision is a
// difference: the state left on screen against the defaults the server declared at the time.
// This spec is the whole coverage of #1144 — the fix is pure JS and the repo has no JS unit
// test harness, so Minitest cannot reach it.
describe('DataTable: column selector memory', () => {
  const visitWith = (url, key, value) =>
    cy.visit(url, {
      onBeforeLoad (win) {
        if (value !== null) win.localStorage.setItem(key, value)
      }
    })

  const storedAt = (key) => cy.window().then((win) => win.localStorage.getItem(key))
  const parsedAt = (key) => storedAt(key).then((raw) => JSON.parse(raw))

  // Four columns (0 Name · 1 Status · 2 Amount · 3 Created At), all four visible by default. A
  // memory naming only 0..2 is exactly the case in the issue: "Created At" is the column that
  // was added later.
  describe('with all four columns visible by default', () => {
    const key = 'bali:columns:toolbar-demo'
    const listing = '#toolbar-demo'
    const url = '/bali/data_table/with_toolbar_buttons'

    const visit = (value = null) => visitWith(url, key, value)
    const header = (index) => cy.get(`${listing} thead th`).eq(index)
    const box = (index) =>
      cy.get(`${listing} [data-controller~="column-selector"] input[data-column-index="${index}"]`)
    const stored = () => parsedAt(key)

    describe('legacy format (bare array of visible indices)', () => {
      it('lets a column the memory never knew be born visible', () => {
        visit('[0,1,2]')

        header(3).should('be.visible').and('contain', 'Created At')
        box(3).should('be.checked')
      })

      it('keeps the column the user had hidden', () => {
        visit('[0,2,3]')

        header(1).should('not.be.visible')
        box(1).should('not.be.checked')
        header(0).should('be.visible')
        header(2).should('be.visible')
        header(3).should('be.visible')
      })

      it('rewrites it in full, and a second read leaves it alone', () => {
        visit('[0,2,3]')

        stored().should('deep.equal', {
          v: 2, hidden: [1], known: [0, 1, 2, 3], serverHidden: []
        })

        cy.reload()

        header(1).should('not.be.visible')
        header(3).should('be.visible')
        stored().should('deep.equal', {
          v: 2, hidden: [1], known: [0, 1, 2, 3], serverHidden: []
        })
      })

      // The measured cost of the inference, pinned so nobody "improves" it by accident: hiding
      // the LAST column is indistinguishable from never having known it, so it comes back once.
      it('gives the last hidden column back exactly once', () => {
        visit('[0,1,2]')

        header(3).should('be.visible')

        box(3).uncheck({ force: true })
        header(3).should('not.be.visible')
        cy.reload()

        header(3).should('not.be.visible')
        box(3).should('not.be.checked')
      })

      it('falls back to the defaults when the legacy value names no column', () => {
        visit('[]')

        header(0).should('be.visible')
        header(3).should('be.visible')
        stored().should('deep.equal', {
          v: 2, hidden: [], known: [0, 1, 2, 3], serverHidden: []
        })
      })

      // 256 is the first index the guard has to reject, which is why the seed is that one and
      // not any other: with `<=` instead of `<` the ceiling accepted 257 indices, this value got
      // through the filter and the inference hid the whole table.
      it('ignores an index over the ceiling and does not hide the table', () => {
        visit('[256]')

        header(0).should('be.visible')
        header(3).should('be.visible')
        stored().should('deep.equal', {
          v: 2, hidden: [], known: [0, 1, 2, 3], serverHidden: []
        })
      })

      it('ignores an absurd index without hanging the page', () => {
        visit('[999999999]')

        header(0).should('be.visible')
        header(3).should('be.visible')
      })
    })

    describe('v2 format', () => {
      it('remembers the column the user hid', () => {
        visit(JSON.stringify({ v: 2, hidden: [3], known: [0, 1, 2, 3], serverHidden: [] }))

        header(3).should('not.be.visible')
        box(3).should('not.be.checked')
        header(0).should('be.visible')
      })

      it('lets a column the memory does not know be born visible', () => {
        visit(JSON.stringify({ v: 2, hidden: [1], known: [0, 1, 2], serverHidden: [] }))

        header(1).should('not.be.visible')
        header(3).should('be.visible')
        box(3).should('be.checked')
      })

      // The other half of the fix: stored and declared agree, so nobody decided anything, and
      // the host changing its mind — here it declares column 3 visible — does reach the user.
      it('does not hide a column that was hidden because the server said so', () => {
        visit(JSON.stringify({ v: 2, hidden: [3], known: [0, 1, 2, 3], serverHidden: [3] }))

        header(3).should('be.visible')
        box(3).should('be.checked')
      })

      // `force`: the panel is opened by daisyUI's `:focus-within`, so the box is not actionable
      // with the menu closed. What matters is the `change` it fires.
      it('writes what is hidden on hide, and clears it on show', () => {
        visit()

        box(1).uncheck({ force: true })
        header(1).should('not.be.visible')
        stored().should('deep.equal', {
          v: 2, hidden: [1], known: [0, 1, 2, 3], serverHidden: []
        })

        box(1).check({ force: true })
        header(1).should('be.visible')
        stored().should('deep.equal', {
          v: 2, hidden: [], known: [0, 1, 2, 3], serverHidden: []
        })
      })

      it('sanitises a value holding entries that are not indices', () => {
        visit(JSON.stringify({
          v: 2, hidden: ['1', 'x', -3, 1], known: [0, 1, 2, 3], serverHidden: []
        }))

        header(1).should('not.be.visible')
        header(0).should('be.visible')
        header(3).should('be.visible')
      })

      // Fail safe against a future format: back to the server's defaults, and the value is NOT
      // overwritten — the version that wrote it can still read it.
      it('ignores a version it does not know and does not overwrite it', () => {
        const future = JSON.stringify({ v: 3, hidden: [1], known: [0, 1, 2, 3] })
        visit(future)

        header(1).should('be.visible')
        header(3).should('be.visible')
        storedAt(key).should('equal', future)
      })
    })
  })

  // The preview with a column the HOST declares off (`with_column(visible: false)`). This is the
  // branch where the memory can over-claim: the column is born hidden without the user touching
  // anything, and recording that as their preference is #1144 wearing a different hat.
  describe('with a column the host declares hidden', () => {
    const key = 'bali:columns:optional-demo'
    const listing = '#optional-demo'
    const url = '/bali/data_table/with_optional_column'

    const visit = (value = null) => visitWith(url, key, value)
    const header = (index) => cy.get(`${listing} thead th`).eq(index)
    const box = (index) =>
      cy.get(`${listing} [data-controller~="column-selector"] input[data-column-index="${index}"]`)
    const stored = () => parsedAt(key)

    it('renders it hidden, and writes nothing when there is no memory', () => {
      visit()

      header(3).should('not.be.visible')
      box(3).should('not.be.checked')
      storedAt(key).should('equal', null)
    })

    // The migration write is the one that bit: it runs on its own, with no user action. Column 3
    // landing in BOTH lists is how the value says "nobody decided this".
    it('does not record it as the user\'s decision when migrating', () => {
      visit('[0,1,2]')

      header(3).should('not.be.visible')
      stored().should('deep.equal', {
        v: 2, hidden: [3], known: [0, 1, 2, 3], serverHidden: [3]
      })
    })

    it('does not drag it along when another column is hidden', () => {
      visit()

      box(1).uncheck({ force: true })
      header(1).should('not.be.visible')
      stored().should('deep.equal', {
        v: 2, hidden: [1, 3], known: [0, 1, 2, 3], serverHidden: [3]
      })
    })

    it('remembers that the user turned it on', () => {
      visit()

      box(3).check({ force: true })
      header(3).should('be.visible')
      stored().should('deep.equal', {
        v: 2, hidden: [], known: [0, 1, 2, 3], serverHidden: [3]
      })

      cy.reload()

      header(3).should('be.visible')
      box(3).should('be.checked')
    })
  })

  // A `selectable:` table puts a REAL `<th>` at index 0 — the select-all box — that the selector
  // does not declare: the canonical preview declares 1..5. The legacy format runs straight into
  // it, because a bare array infers the range 0..ceiling and the 0 gets in there without ever
  // having been a toggleable column.
  describe('with a selectable table, where index 0 is not a column', () => {
    const key = 'bali:columns:lookbook_movies'
    const listing = '#lookbook_movies'
    const url = '/bali/data_table/complete'

    it('leaves the selection box alone when migrating, and does not record it', () => {
      visitWith(url, key, '[1,2,4,5]')

      cy.get(`${listing} thead th`).eq(0).should('be.visible')
      cy.get(`${listing} thead th`).eq(3).should('not.be.visible')
      cy.get(`${listing} thead th`).eq(1).should('be.visible')
      cy.get(`${listing} thead th`).eq(5).should('be.visible')

      parsedAt(key).should('deep.equal', {
        v: 2, hidden: [3], known: [1, 2, 3, 4, 5], serverHidden: []
      })
    })
  })

  // View 2 of the preview records columns [0, 2].
  describe('with a saved view applied', () => {
    const key = 'bali:columns:saved-views-preview'
    const listing = '#saved-views-preview'
    const url = '/bali/data_table/with_saved_views?saved_view=2'

    it('neither restores the device memory nor migrates it', () => {
      visitWith(url, key, '[0,1,2,3]')

      cy.get(`${listing} thead th`).eq(2).should('be.visible')
      cy.get(`${listing} thead th`).eq(1).should('not.be.visible')
      cy.get(`${listing} thead th`).eq(3).should('not.be.visible')
      storedAt(key).should('equal', '[0,1,2,3]')
    })
  })

  // The other reader of the same key. With no selector on screen (cards, calendar) the saved
  // views controller falls back to the device memory, and the payload that travels to
  // `bali_saved_views.payload` is still a list of VISIBLE indices, which is what
  // `apply_visible_columns` reads on the other side.
  describe('saved views in cards mode', () => {
    const gridUrl = '/bali/data_table/complete?view=grid'
    const gridKey = 'bali:columns:lookbook_movies'

    // The submit is intercepted in the capture phase: preventDefault stops Turbo and the browser
    // without stopping the Stimulus action, which listens on the form itself.
    const visitGrid = (value) =>
      cy.visit(gridUrl, {
        onBeforeLoad (win) {
          win.localStorage.setItem(gridKey, value)
          win.addEventListener('submit', (event) => event.preventDefault(), true)
        }
      })

    // `?? null`: a `.then` returning `undefined` passes the previous subject through, and the
    // assertion would compare against the raw JSON instead of failing on the missing columns.
    const payloadAfterSubmit = (value) => {
      visitGrid(value)

      cy.get('[data-saved-views-target="saveForm"] form').then(($form) => {
        $form[0].dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
      })

      return cy.get('[data-saved-views-target="payload"]').invoke('val')
        .then((raw) => JSON.parse(raw).columns ?? null)
    }

    it('translates the v2 format into the list of visible columns', () => {
      payloadAfterSubmit(JSON.stringify({
        v: 2, hidden: [3], known: [1, 2, 3, 4, 5], serverHidden: []
      })).should('deep.equal', [1, 2, 4, 5])
    })

    it('still reads the legacy format as it stands', () => {
      payloadAfterSubmit('[1,2,4,5]').should('deep.equal', [1, 2, 4, 5])
    })

    it('does not migrate the key, because no selector is there to rewrite it', () => {
      visitGrid('[1,2,4,5]')

      cy.get('[data-saved-views-target="payload"]').should('exist')
      storedAt(gridKey).should('equal', '[1,2,4,5]')
    })
  })
})
