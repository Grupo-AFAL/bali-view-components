// Gantt island (#705): mounts GanttFlow through the COMPLETE circuit of a host —
// startIslandLoader('gantt') in the main bundle reads the metas from
// react_island_meta_tags, injects the gantt-island.js entry, registerIsland
// registers on window.Stimulus with a guard, and GanttController (a subclass of
// ReactIslandController) mounts React Flow with values→props.
//
// Since #970 the island is the only renderer, so these previews are the
// component's: `default` (readonly) and `editable`. The skeleton→island swap is
// measured separately, in gantt-swap.cy.js.
//
// Visibility/structure is what is measured, not loose textContent (repo memory).
// The editable preview hits the dummy's reference endpoints
// (Admin::Projects::SchedulesController) against the seeded project: the edits
// PERSIST and dragging back only compensates in part (the snap is not exactly
// symmetric) — `bin/rails db:seed` restores the dates. The assertions do not
// depend on absolute dates for that very reason.

const instances = (win) =>
  win.Stimulus.controllers.filter((c) => c.identifier === 'gantt')

const widthOf = ($el) => $el[0].getBoundingClientRect().width

const rowFor = (name) => cy.get(`div[title="${name}"]`).filter('[class*="cursor-pointer"]')

// Drags a React Flow node `dx` px horizontally. d3-drag listens for mousedown
// on the node and then follows mousemove/mouseup on the AUT's window — the
// synthetic events need `view: win` (d3 does select(event.view)) or nodrag
// blows up with "Cannot read properties of undefined".
const dragNode = (selector, dx) => {
  cy.window().then((win) => {
    cy.get(selector).first().then(($node) => {
      const rect = $node[0].getBoundingClientRect()
      const startX = rect.left + rect.width / 2
      const startY = rect.top + rect.height / 2
      cy.wrap($node)
        .trigger('mousedown', { button: 0, clientX: startX, clientY: startY, view: win, force: true })
      cy.document()
        .trigger('mousemove', { clientX: startX + dx / 2, clientY: startY, view: win, force: true })
      cy.document()
        .trigger('mousemove', { clientX: startX + dx, clientY: startY, view: win, force: true })
      cy.document()
        .trigger('mouseup', { clientX: startX + dx, clientY: startY, view: win, force: true })
    })
  })
}

describe('Gantt island', () => {
  it('mounts the island via the lazy loader on the host Stimulus', () => {
    cy.visit('/bali/gantt/default')

    cy.get('.react-flow').should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')
    cy.window().should((win) => expect(instances(win)).to.have.length(1))

    // Readonly: no resize handles (they only exist with editable=true).
    cy.get('.cursor-ew-resize').should('not.exist')
  })

  it('paints the milestone as a diamond and the critical edge with the error color (D10)', () => {
    cy.visit('/bali/gantt/default')

    // React Flow mounts with onlyRenderVisibleElements: at the density this
    // preview opens with (`:auto` → day, 24 px/day over a 43-day window) the
    // milestone falls outside the Cypress viewport and does not exist as a
    // node. In "month" the whole window fits and it can be measured.
    cy.get('[role="group"][aria-label="Zoom"]').contains('button', 'Month').click()

    // First it checks that the WHOLE window is inside the viewport, and the
    // number comes from the document itself instead of a constant: if
    // sample_data grows until it no longer fits even at month density, the
    // failure says so and not "D10 broken", which is where a `[data-milestone]`
    // that does not match sends you.
    cy.get('[data-controller="gantt"]').then(($mount) => {
      const withDates = JSON.parse($mount.attr('data-gantt-data-value'))
        .items.filter((item) => item.starts_on).length

      cy.get('.react-flow__node').should(($nodes) => {
        expect($nodes.length, 'visible nodes at month density: if there are fewer than the items ' +
          'with dates, the preview dataset grew and culling is eating the right-hand side')
          .to.be.at.least(withDates)
      })
    })

    cy.get('[data-milestone]').should('exist')

    // The 21→40 dependency joins two critical items → .critical edge. Its
    // computed stroke resolves var(--color-error) and differs from a normal one.
    cy.get('.react-flow__edge.critical').should('exist')
    cy.get('.react-flow__edge.critical path').first().then(($critical) => {
      const criticalStroke = getComputedStyle($critical[0]).stroke
      cy.get('.react-flow__edge:not(.critical) path').first().should(($normal) => {
        expect(criticalStroke).to.not.equal(getComputedStyle($normal[0]).stroke)
      })
    })
  })

  it('zooming writes the namespaced gantt_zoom param without navigating and rescales', () => {
    cy.visit('/bali/gantt/default')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)

    // The preview opens on "day": that is the zoom the server resolved from
    // `:auto` against the window and passed to the island in initial-zoom (#970).
    cy.get('[data-controller="gantt"]').should('have.attr', 'data-gantt-initial-zoom-value', 'day')

    cy.get('.react-flow__node').first().then(($bar) => {
      const dayWidth = widthOf($bar)
      // Scoped to the zoom group: a loose contains('Week') matches the hidden
      // button in the columns dropdown.
      cy.get('[role="group"][aria-label="Zoom"]').contains('button', 'Week').click()
      cy.location('search').should('include', 'gantt_zoom=week')
      // day = 24 px/day vs week = 8: the same bar shrinks 3x.
      cy.get('.react-flow__node').first().should(($after) => {
        expect(widthOf($after)).to.be.lessThan(dayWidth / 2)
      })
    })

    // replaceState, not navigation: the island stays mounted (1 instance).
    cy.window().should((win) => expect(instances(win)).to.have.length(1))
  })

  it('collapsing a group hides its bars and color-by changes the painting', () => {
    cy.visit('/bali/gantt/default')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)

    // Color-by: the inline background of the first bar's body changes formula
    // (the node wrapper carries no background; the body does).
    cy.get('.react-flow__node').first().find('div[style*="background"]').first().then(($bar) => {
      const statusFill = $bar[0].style.background
      cy.get('[role="group"][aria-label="Color by"]').contains('button', 'Priority').click()
      cy.get('.react-flow__node').first().find('div[style*="background"]').first().should(($after) => {
        expect($after[0].style.background).to.not.equal(statusFill)
      })
    })

    // Collapse: the caret of the table's first group reduces the rows/bars.
    cy.get('.react-flow__node').then(($nodes) => {
      const before = $nodes.length
      cy.get('button[aria-expanded="true"]').first().click()
      cy.get('.react-flow__node').should(($after) => {
        expect($after.length).to.be.lessThan(before)
      })
    })
  })

  it('dragging a bar posts the contract PATCH and reconciles', () => {
    cy.intercept('PATCH', '/admin/projects/*/schedule').as('patch')
    cy.visit('/bali/gantt/editable')

    cy.get('.react-flow').should('be.visible')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)
    // Editable: the resize handles exist (they show up on hover).
    cy.get('.cursor-ew-resize').should('exist')

    // The edits PERSIST in the dummy's DB and this spec runs over and over
    // against that same DB. The item's state is saved so it can be put back
    // through the same contract endpoint at the end.
    //
    // The way back used to be a second drag of the same distance, and that does
    // NOT work: the drag back is not the inverse of the drag out (measured: the
    // way out moves 5 days, the way back 0), so the date drifted ~5 days per run
    // until the item moved past the next one and the `cy.wait` for the second
    // PATCH died by timeout. It was never seen in CI because every run does
    // `db:schema:load db:seed`; locally it showed up after a few repetitions.
    cy.get('[data-controller="gantt"]').then(($island) => {
      const items = JSON.parse($island.attr('data-gantt-data-value')).items
      const id = Number(Cypress.$('.react-flow__node').first().attr('data-id'))
      const item = items.find((i) => Number(i.id) === id)
      cy.wrap({
        // Absolute: `cy.request` resolves a relative one against the baseUrl,
        // which here points inside Lookbook and not at the endpoint.
        url: `${window.location.origin}${$island.attr('data-gantt-patch-url-value')}`,
        id,
        name: item.name,
        startsOn: item.starts_on,
        days: Math.round((Date.parse(item.ends_on) - Date.parse(item.starts_on)) / 86400000) + 1
      }).as('draggedItem')
    })

    // The row of the DRAGGED item (by its name, not by position: the order of
    // the rows depends on the dates) is the witness of the reconcile — table and
    // bars come out of the SAME `rows`, and the PATCH's 200 arrives before React
    // repositions anything.
    cy.get('@draggedItem').then(({ name }) => {
      rowFor(name).invoke('text').then((initialText) => {
        dragNode('.react-flow__node', 80)
        cy.wait('@patch').then(({ request, response }) => {
          expect(request.body.item.id).to.be.a('number')
          expect(request.body.item.starts_on).to.match(/^\d{4}-\d{2}-\d{2}$/)
          expect(request.body.item.duration_days).to.be.greaterThan(0)
          expect(response.statusCode).to.equal(200)
          // Reconcile: the COMPLETE document, not a patch.
          expect(response.body).to.have.all.keys('groups', 'items', 'dependencies', 'critical_ids')
        })
        rowFor(name).should('not.have.text', initialText)
        cy.get('.react-flow__node').should('have.length.greaterThan', 0).and('be.visible')
        cy.get('.alert-error').should('not.exist')
      })
    })

    // Restore through the API: deterministic, and it leaves the DB as it found it.
    cy.get('@draggedItem').then(({ url, id, startsOn, days }) => {
      cy.request('PATCH', url, { item: { id, starts_on: startsOn, duration_days: days } })
        .its('status')
        .should('equal', 200)
    })
  })
})
