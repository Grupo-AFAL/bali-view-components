import { cdp, frameAt } from '../support/accessibility_tree'
import { drag } from '../support/tap'

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

  it('the Owner legend swatch is the colour of that owner\'s progress fill', () => {
    cy.visit('/bali/gantt/default')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)
    cy.get('[role="group"][aria-label="Color by"]').contains('button', 'Owner').click()

    cy.get('.react-flow__node span.rounded-full[title]').should(($avatars) => {
      const doc = $avatars[0].ownerDocument
      const paint = (el) => doc.defaultView.getComputedStyle(el).backgroundColor
      // The toolbar's status filter draws the same swatch; the footer is the `.border-t` bar.
      const swatches = new Map(
        [...doc.querySelectorAll('.border-t span.rounded-sm[style*="background"]')]
          .map((swatch) => [swatch.nextElementSibling.textContent, paint(swatch)])
      )
      expect($avatars.length, 'bars with an owner').to.be.at.least(2)
      $avatars.toArray().forEach((avatar) => {
        const owner = avatar.title.split(/\s+/)[0]
        const progress = avatar.parentElement.querySelector('.inset-y-0.left-0')
        expect(swatches.get(owner), `${owner}'s legend swatch`).to.equal(paint(progress))
      })
    })
  })

  // Only the status pill's text reads a catalog's --color-neutral as base-content (ganttColors.js).
  // Under the bar's base-content label, a progress painted base-content read 1.21:1 on `dark`.
  it("paints a catalog's --color-neutral progress in neutral, not in the bar label's ink", () => {
    cy.intercept({ method: 'GET', url: /\/lookbook\/preview\/bali\/gantt\// }, (req) => {
      req.on('response', (res) => {
        res.body = String(res.body).replaceAll('&quot;--color-success&quot;', '&quot;--color-neutral&quot;')
      })
    })
    cy.visit('/bali/gantt/default')
    cy.get('[data-controller="gantt"]').should('have.attr', 'data-gantt-catalogs-value').and('include', '"--color-neutral"')
    cy.document().then((doc) => doc.documentElement.setAttribute('data-theme', 'dark'))

    cy.get('.react-flow__node div[title="Stakeholder interviews"]').should(([bar]) => {
      const doc = bar.ownerDocument
      expect(doc.getAnimations(), 'transitions settled').to.have.length(0)
      const style = (el) => doc.defaultView.getComputedStyle(el)
      const token = (name) => {
        const probe = doc.body.appendChild(Object.assign(doc.createElement('div'), { style: `background: var(--color-${name})` }))
        const colour = style(probe).backgroundColor
        probe.remove()
        return colour
      }

      const progress = style(bar.querySelector('.inset-y-0.left-0')).backgroundColor
      expect(progress, 'progress under the label').to.equal(token('neutral'))
      expect(progress, 'base-content, the label\'s ink off the progress').to.not.equal(token('base-content'))
    })
  })

  // The warning comes from React Flow's first read of its pane, in an effect that runs before the
  // board's measured height lands (it reads again on every resize). Opened at no height, the board
  // logged #004 on every load; on a 358 px board the table also opened at 380 px and left the
  // pane no width, and at 320 px its 300 px floor left none.
  ;[[1280, 800], [390, 844], [320, 700]].forEach(([width, height]) => {
    it(`mounts React Flow on a pane with a size in a ${width} px window`, () => {
      cy.viewport(width, height)
      cy.visit('/bali/gantt/default', { onBeforeLoad: (win) => cy.spy(win.console, 'warn').as('warn') })
      cy.get('.react-flow__node').should('have.length.greaterThan', 0)

      cy.get('@warn').then((warn) => {
        const flow = warn.args.map(([message]) => String(message)).filter((message) => message.includes('error#004'))
        expect(flow, 'React Flow warning #004').to.deep.equal([])
      })
    })
  })

  // A board mounted hidden (an inactive tab) measures no width, and it measures again only when
  // the body resizes: in a layout whose body is the window's height, showing it does not. Its
  // table keeps the skeleton's CSS width, which is no number to drag from.
  it('drags the splitter on a board that mounted hidden', () => {
    cy.intercept({ method: 'GET', url: /\/lookbook\/preview\/bali\/gantt\/default/ }, (req) => {
      req.on('response', (res) => {
        res.body = String(res.body).replace('<div class="bali-gantt"',
          '<style>body { height: 100vh; overflow: auto }</style><div class="bali-gantt" style="display: none"')
      })
    })
    cy.visit('/bali/gantt/default')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)
    cy.get('.bali-gantt').invoke('removeAttr', 'style')

    cy.get('div[title="Drag to resize the table"]').then(([splitter]) => {
      const table = splitter.previousElementSibling
      expect(table.style.width, 'table at the skeleton width').to.equal('var(--gantt-name-col)')
      const start = table.getBoundingClientRect().width
      const { left, top } = splitter.getBoundingClientRect()
      const at = (x) => ({ clientX: x, clientY: top + 10, button: 0, eventConstructor: 'PointerEvent' })

      cy.wrap(splitter).trigger('pointerdown', at(left))
      cy.document().trigger('pointermove', at(left + 40))
      cy.document().trigger('pointerup', at(left + 40))
      cy.document().should(() => {
        expect(table.getBoundingClientRect().width, 'table width after a 40 px drag').to.be.closeTo(start + 40, 1)
      })
    })
  })

  // A phone's table opens at 60% of the board, under the 260 px the splitter held as its floor:
  // the first move widened a 215 px table to 260, and it could not be dragged back.
  it('drags a phone board\'s table narrower than it opened', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/gantt/default')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)

    cy.get('div[title="Drag to resize the table"]').then(([splitter]) => {
      const table = splitter.previousElementSibling
      const start = table.getBoundingClientRect().width
      const { left, top } = splitter.getBoundingClientRect()
      const at = (x) => ({ clientX: x, clientY: top + 10, button: 0, eventConstructor: 'PointerEvent' })

      cy.wrap(splitter).trigger('pointerdown', at(left))
      cy.document().trigger('pointermove', at(left + 10))
      cy.document().should(() => {
        expect(table.getBoundingClientRect().width, 'table width after a 10 px drag').to.be.closeTo(start + 10, 1)
      })
      cy.document().trigger('pointermove', at(left - 60))
      cy.document().trigger('pointerup', at(left - 60))
      cy.document().should(() => {
        expect(table.getBoundingClientRect().width, 'table width after a 60 px drag back').to.be.closeTo(start - 60, 1)
      })
    })
  })

  it('follows a finger dragging the splitter', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/gantt/default')
    cy.get('.react-flow__node').should('have.length.greaterThan', 0)

    cy.get('div[title="Drag to resize the table"]').then(($splitter) => {
      const table = $splitter[0].previousElementSibling
      const start = table.getBoundingClientRect().width

      cy.then(() => drag($splitter, 0, { dx: -60, steps: 12 }))
      cy.document().should(() => {
        expect(table.getBoundingClientRect().width, 'table width after a 60 px drag').to.be.closeTo(start - 60, 1)
      })
    })
  })

  // The minimap is 204 px wide and sits 14 px from the timeline's right edge. In a narrower
  // timeline it spilled over the table, 218 px of it at 320 px, so there it is not drawn.
  ;[[320, 700, false], [390, 844, false], [768, 1024, true], [1280, 800, true]].forEach(([width, height, drawn]) => {
    it(`${drawn ? 'draws the minimap inside' : 'leaves out the minimap of'} the timeline in a ${width} px window`, () => {
      cy.viewport(width, height)
      cy.visit('/bali/gantt/default')
      cy.get('.react-flow__node').should('have.length.greaterThan', 0)

      cy.get('.react-flow').then(([pane]) => {
        const minimap = pane.parentElement.querySelector('div[title^="Minimap"]')
        if (!drawn) {
          expect(minimap, 'minimap').to.equal(null)
          return
        }
        const outer = pane.getBoundingClientRect()
        const inner = minimap.getBoundingClientRect()
        expect(inner.left, 'minimap left edge inside the timeline').to.be.at.least(outer.left)
        expect(inner.right, 'minimap right edge inside the timeline').to.be.at.most(outer.right)
      })
    })
  })

  // The row carets and the floating zoom controls draw inline SVGs inside named buttons. Left in
  // Chromium's accessibility tree they read as nine images with no name.
  it('keeps the icons out of the accessibility tree and leaves their buttons named', () => {
    cy.visit('/bali/gantt/default')
    cy.get('button[title="Zoom in"]').should('exist')

    cy.url().then((url) =>
      cdp('Page.getFrameTree')
        .then(({ frameTree }) => cdp('Accessibility.getFullAXTree', { frameId: frameAt(frameTree, url).id }))
    ).then(({ nodes }) => {
      const shown = nodes.filter((n) => !n.ignored)
      const named = (role) => shown.filter((n) => n.role?.value === role).map((n) => n.name?.value || '')
      expect(named('image').filter((name) => !name), 'images with no name').to.have.length(0)
      expect(named('button').filter((name) => !name), 'buttons with no name').to.have.length(0)
      expect(named('button'), 'floating controls').to.include.members(['Zoom in', 'Zoom out', 'Fit to window', 'Go to today'])
      expect(named('button'), 'row toggles').to.include('Collapse')
    })
  })

  // At 390 px the toolbar wraps before the colour-by control, and the label naming it stayed
  // behind, alone at the end of the line above.
  it('wraps the colour-by label with its control in a 390 px window', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/gantt/default')

    cy.get('[role="group"][aria-label="Color by"]').should(([control]) => {
      const label = [...control.closest('.flex-wrap').querySelectorAll('span')].find((span) => span.textContent === 'Color')
      const middle = (el) => {
        const { top, bottom } = el.getBoundingClientRect()
        return (top + bottom) / 2
      }
      expect(middle(label), 'label on the line of its control').to.be.closeTo(middle(control), 1)
    })
  })

  // Where the toolbar wraps, a separator at the start or the end of a line divides nothing: at
  // 414 px both ended one, and at 320 the second started one. Hidden but still laid out, the one
  // starting a line pushed its first control 9 px in.
  ;[
    ['', ''],
    [' with the creation buttons', 'data-gantt-manageable-value="true" data-gantt-new-group-url-value="/groups/new" data-gantt-new-item-url-value="/items/new"']
  ].forEach(([variant, values]) => {
    it(`divides only controls on the same line as the window narrows and widens${variant}`, () => {
      cy.intercept({ method: 'GET', url: /\/lookbook\/preview\/bali\/gantt\/default/ }, (req) => {
        req.on('response', (res) => {
          res.body = String(res.body).replace('data-controller="gantt"', `data-controller="gantt" ${values}`)
        })
      })
      cy.viewport(1280, 800)
      cy.visit('/bali/gantt/default')
      cy.get('.react-flow__node').should('have.length.greaterThan', 0)
      cy.get('[data-separator]').should('have.length', values ? 3 : 2)

      ;[1280, 414, 390, 320, 1280].forEach((width) => {
        cy.viewport(width, 800)
        cy.get('[data-separator]').should(($separators) => {
          const box = (el) => el.getBoundingClientRect()
          const sameLine = (a, b) => box(a).top < box(b).bottom && box(a).bottom > box(b).top
          const items = [...$separators[0].parentElement.children]
            .filter((el) => !el.matches('[data-separator]') && el.childNodes.length > 0)
          const style = (el) => el.ownerDocument.defaultView.getComputedStyle(el)

          $separators.each((index, separator) => {
            const name = `${width} px: separator ${index + 1}`
            if (style(separator).display === 'none') {
              const { previousElementSibling: before, nextElementSibling: after } = separator
              expect(sameLine(before, after), `${name}, left out, between controls on one line`).to.equal(false)
              return
            }
            const x = box(separator).left
            const line = items.filter((item) => sameLine(item, separator))
            const between = line.some((item) => box(item).right <= x) && line.some((item) => box(item).left >= x)
            expect(style(separator).visibility === 'visible', `${name} shown, between controls on its line`).to.equal(between)
          })

          const starts = items.filter((item, index) => !items.slice(0, index).some((earlier) => sameLine(earlier, item)))
            .map((item) => Math.round(box(item).left))
          expect([...new Set(starts)], `${width} px: x where each line starts`).to.have.length(1)
        })
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
