// Bali::BpmnEditor embedded in an app's own page (BPMN-50): the app's look
// on nodes, a selection the app controls, the minimal chrome, notes on a
// read-only diagram, no rules, and two different flows compared by name.

const SPLIT = '/bali/bpmn_editor/split_view'
const MAP = '#split_map_bpmn'
const FLOW = '[data-testid="bpmn-split-flow"]'
const box = (name) => cy.contains(`${MAP} .react-flow__node-bpmn`, name)
const zoomOf = (scope) => cy.get(`${scope} .bpmn-editor [aria-live="polite"]`).invoke('text').then((text) => parseInt(text, 10))

// Samples every animation frame for `ms`: whether the map draws any box past
// its own edges and whether its selected box is inside it, and the zoom of the
// flow's diagram on the right once its nodes are shown.
const sampleFrames = (win, ms) => new Promise((resolve) => {
  const frames = []
  const start = win.performance.now()
  const scaleOf = (viewport) => Number(new win.DOMMatrix(win.getComputedStyle(viewport).transform).a.toFixed(4))
  const tick = () => {
    const doc = win.document
    const map = doc.querySelector(`${MAP} .react-flow`).getBoundingClientRect()
    const boxes = [...doc.querySelectorAll(`${MAP} .react-flow__node-bpmn`)].map((node) => node.getBoundingClientRect())
    const selected = doc.querySelector(`${MAP} .bpmn-node.is-selected`)
    const box = selected && selected.getBoundingClientRect()
    const viewport = doc.querySelector(`${FLOW} .react-flow__viewport`)
    const shown = viewport && [...viewport.querySelectorAll('.react-flow__node')].some((node) => win.getComputedStyle(node).visibility !== 'hidden')
    frames.push({
      cut: boxes.some((b) => b.left < map.left - 1 || b.right > map.right + 1),
      selectedInside: box ? box.left >= map.left - 1 && box.right <= map.right + 1 && box.top >= map.top - 1 && box.bottom <= map.bottom + 1 : null,
      flowZoom: shown ? scaleOf(viewport) : null
    })
    if (win.performance.now() - start < ms) win.requestAnimationFrame(tick); else resolve(frames)
  }
  win.requestAnimationFrame(tick)
})

// Every `bali-bpmn:selection-change` the page hears, in order.
const recordSelections = () => cy.window().then((win) => {
  win.selections = []
  win.document.addEventListener('bali-bpmn:selection-change', (event) => win.selections.push({ target: event.target.id, ...event.detail }))
})

describe('BPMN editor embedded in an app page', () => {
  describe('split view', () => {
    beforeEach(() => {
      cy.viewport(1440, 1000)
      cy.visit(SPLIT)
      box('Alta de proveedor').should('be.visible')
    })

    it('starts on the map alone, read-only, without handles or quick menu', () => {
      cy.get('.split-view-component--collapsible').should('have.attr', 'data-split-state', 'closed')
      cy.get(`${MAP} .bpmn-node.is-selected`).should('not.exist')
      cy.get(`${MAP} .bpmn-canvas`).should('have.class', 'is-readonly')
      cy.get(`${MAP} [data-testid="bpmn-quick-menu"]`).should('not.exist')
      cy.get(`${MAP} [data-testid="bpmn-properties"]`).should('not.exist')
      cy.get(FLOW).should('not.exist')
    })

    it('selects the node the app names on load, and opens its flow', () => {
      cy.visit(`${SPLIT}?selected=b3`)
      cy.get(`${MAP} .bpmn-node.is-selected`).should('have.length', 1).and('contain', 'Alta de proveedor')
      cy.get('.split-view-component--collapsible').should('have.attr', 'data-split-state', 'open')
      cy.get('[data-testid="bpmn-split-title"]').should('have.text', 'Alta de proveedor')
    })

    it('slides the flow in on a box click, walks the boxes, and clears the map on close', () => {
      box('Alta de proveedor').click()
      cy.get('.split-view-component--collapsible').should('have.attr', 'data-split-state', 'open')
      cy.get('[data-testid="bpmn-split-title"]').should('have.text', 'Alta de proveedor')
      cy.get(`${FLOW} .react-flow__node-bpmn`).should('have.length.greaterThan', 3)
      cy.get('[data-testid="bpmn-split-next"]').click()
      cy.get('[data-testid="bpmn-split-title"]').should('have.text', 'Pago a proveedores')
      cy.get(`${MAP} .bpmn-node.is-selected`).should('have.length', 1).and('contain', 'Pago a proveedores')
      cy.get('[data-testid="split-view-close"]').should('not.be.visible')
      cy.get('[data-testid="bpmn-split-close"]').click()
      cy.get('.split-view-component--collapsible').should('have.attr', 'data-split-state', 'closed')
      cy.get(`${MAP} .bpmn-node.is-selected`).should('not.exist')
      cy.get(FLOW).should('not.exist')
      box('Alta de proveedor').click()
      cy.get('[data-testid="bpmn-split-title"]').should('have.text', 'Alta de proveedor')
      cy.get('body').type('{esc}')
      cy.get('.split-view-component--collapsible').should('have.attr', 'data-split-state', 'closed')
      cy.get(`${MAP} .bpmn-node.is-selected`).should('not.exist')
    })

    // The detail slides in over 300 ms while the map's column shrinks: the map
    // follows it frame by frame, and the flow is fitted once, to the size it
    // has open.
    it('keeps the map whole and the flow at one zoom while the detail slides in and out', () => {
      let frames
      cy.window().then((win) => { frames = sampleFrames(win, 900) })
      box('Alta de proveedor').click()
      cy.then(() => frames).then((list) => {
        expect(list.length, 'frames sampled').to.be.greaterThan(20)
        expect(list.filter((f) => f.cut), 'frames with the map cut').to.have.length(0)
        expect(list.filter((f) => f.selectedInside === false), 'frames with the selected box out of view').to.have.length(0)
        expect(list.filter((f) => f.selectedInside), 'frames with the box selected').to.have.length.greaterThan(10)
        const zooms = [...new Set(list.map((f) => f.flowZoom).filter((z) => z !== null))]
        expect(zooms, 'zooms the flow showed').to.have.length(1)
      })
      cy.window().then((win) => { frames = sampleFrames(win, 900) })
      cy.get('body').type('{esc}')
      cy.then(() => frames).then((list) => {
        expect(list.filter((f) => f.cut), 'frames with the map cut while closing').to.have.length(0)
        expect([...new Set(list.map((f) => f.flowZoom).filter((z) => z !== null))], 'zooms while closing').to.have.length.at.most(1)
      })
    })

    // `master_width: :equal` and `height: :screen`: the two diagrams are the
    // same box — the detail's own «Close» sits in its header, beside the
    // title, and the two headers are one height.
    ;[[1440, 1000], [1440, 600]].forEach(([width, height]) => {
      it(`gives the map and the flow the same box at ${width}×${height}`, () => {
        cy.viewport(width, height)
        cy.visit(SPLIT)
        box('Alta de proveedor').click()
        cy.get('.split-view-component--collapsible').should('have.attr', 'data-split-state', 'open')
        cy.wait(400)
        cy.get(`${FLOW} .bpmn-editor`).should('be.visible').then(($flow) => {
          cy.get(`${MAP} .bpmn-editor`).then(($map) => {
            const [map, flow] = [$map[0].getBoundingClientRect(), $flow[0].getBoundingClientRect()]
            expect(flow.top, 'top').to.be.closeTo(map.top, 2)
            expect(flow.height, 'height').to.be.closeTo(map.height, 2)
            expect(flow.width, 'width').to.be.closeTo(map.width, 1)
            // In the page's coordinates: the click may have scrolled it.
            cy.window().then((win) => expect(map.bottom + win.scrollY, 'bottom').to.be.closeTo(win.innerHeight, 2))
          })
        })
      })
    })

    it('keeps only the zoom controls and folds the legend in the minimal chrome', () => {
      cy.get(MAP).within(() => {
        cy.get('.react-flow__minimap').should('not.exist')
        cy.get('[data-testid="bpmn-save-status"], [data-testid="bpmn-help"], [data-testid="bpmn-stencil"]').should('not.exist')
        cy.get('.bpmn-editor button[aria-label="Descargar SVG"]').should('not.exist')
        cy.get('button[aria-label="Centrar flujo"]').should('be.visible')
        cy.get('.bpmn-legend button').should('have.attr', 'aria-expanded', 'false')
      })
    })

    it('only selects on a click when the app takes the open-reference over, and says so', () => {
      recordSelections()
      cy.location('href').then((before) => {
        box('Alta de cliente').click()
        cy.location('href').should('eq', before)
      })
      cy.get(`${MAP} .bpmn-node.is-selected`).should('have.length', 1).and('contain', 'Alta de cliente')
      cy.window().its('selections').should('deep.equal', [
        {
          target: 'split_map_bpmn',
          node_id: 'b1',
          reference: { id: 'b1', label: 'Alta de cliente', url: '/lookbook/preview/bali/bpmn_editor/default?box=b1' },
          type: 'sub_process',
          lane_id: 'm1',
          lane_name: 'Comercial'
        }
      ])
      cy.get('[data-testid="bpmn-split-title"]').should('have.text', 'Alta de cliente')
      cy.get(`${FLOW} .bali-bpmn-editor`).should('have.id', 'split_flow_customer_v1')
      cy.get('[data-testid="bpmn-split-lane"]').should('have.text', 'Comercial')
      cy.get(`${MAP} .react-flow__pane`).click(12, 12)
      cy.window().its('selections').should('have.length', 2).its(1).should('deep.equal', { target: 'split_map_bpmn', node_id: null, reference: null })
    })

    it('moves the selection on bali-bpmn:select, without echoing it back', () => {
      recordSelections()
      cy.get(MAP).then(($map) => {
        $map[0].dispatchEvent(new CustomEvent('bali-bpmn:select', { detail: { node_id: 'b6' } }))
      })
      cy.get(`${MAP} .bpmn-node.is-selected`).should('have.length', 1).and('contain', 'Cierre contable')
      cy.get(MAP).then(($map) => {
        $map[0].dispatchEvent(new CustomEvent('bali-bpmn:select', { detail: { node_id: null } }))
      })
      cy.get(`${MAP} .bpmn-node.is-selected`).should('not.exist')
      cy.window().its('selections').should('have.length', 0)
    })

    it('selects a focused node with Enter or Space', () => {
      recordSelections()
      cy.get(`${MAP} .bpmn-node[data-node-id="b4"]`).should('have.attr', 'tabindex', '0').focus().type('{enter}')
      cy.get(`${MAP} .bpmn-node.is-selected`).should('contain', 'Pago a proveedores')
      cy.get(`${MAP} .bpmn-node[data-node-id="b2"]`).focus().type(' ')
      cy.get(`${MAP} .bpmn-node.is-selected`).should('have.length', 1).and('contain', 'Facturación')
      cy.window().its('selections').then((list) => expect(list.map((s) => s.node_id)).to.deep.equal(['b4', 'b2']))
    })

    it('fits again when its container changes size', () => {
      // With `height: :content` the map's box has a height of its own to change.
      cy.visit(`${SPLIT}?height=content`)
      box('Alta de proveedor').should('be.visible')
      zoomOf(MAP).then((before) => {
        cy.get(`${MAP}`).parent().invoke('css', 'height', '260px')
        cy.wait(600)
        zoomOf(MAP).should('be.lessThan', before)
      })
    })

    it('saves a note on the read-only flow to its own endpoint, and only the notes', () => {
      cy.intercept('PUT', '**/annotations*').as('notes')
      cy.intercept('PUT', '**/diagram*').as('diagram')
      box('Alta de proveedor').click()
      cy.get(FLOW).within(() => {
        cy.contains('.react-flow__node-bpmn', 'Revisar documentación').click()
        cy.get('[data-testid="bpmn-properties"] input').first().should('be.disabled')
        cy.contains('button', 'Agregar nota').click()
        cy.get('textarea[aria-label="Nota"]').last().type('¿Quién firma?')
      })
      cy.wait('@notes').then(({ request, response }) => {
        expect(Object.keys(request.body).sort()).to.deep.equal(['annotations', 'version'])
        expect(request.body.annotations.map((a) => a.text)).to.deep.equal(['¿Quién firma?'])
        expect(response.statusCode).to.eq(200)
        expect(response.body.annotations[0].text).to.eq('¿Quién firma?')
      })
      cy.get(`${FLOW} .react-flow .bpmn-note-number`).should('have.length', 1)
      cy.get(`${FLOW} [data-testid="bpmn-save-status"]`).should('not.exist')
      cy.get('@diagram.all').should('have.length', 0)
    })
  })

  it('lets a small embedded diagram fit below 40 % with min_zoom', () => {
    cy.viewport(390, 900)
    cy.visit(SPLIT)
    box('Alta de proveedor').click()
    cy.get(`${FLOW} .react-flow__node-bpmn`).should('have.length.greaterThan', 3)
    cy.wait(400)
    zoomOf(FLOW).should('be.lessThan', 40)
  })

  describe('the app’s appearance on nodes', () => {
    beforeEach(() => cy.visit('/bali/bpmn_editor/default?appearance=true'))

    it('draws the colour, the badge with legible text and the fading', () => {
      cy.contains('.react-flow__node-bpmn', 'Validar factura').within(() => {
        cy.get('[data-appearance="#E9A23B"]').should('exist')
        cy.get('[data-testid="bpmn-node-badge"]').should('have.text', 'En proceso')
          .and('have.css', 'color', 'rgb(17, 24, 39)')
      })
      cy.contains('.react-flow__node-bpmn', 'Programar transferencia').find('[data-appearance="#2563eb"]').should('exist')
      cy.contains('.react-flow__node-bpmn', 'Emitir factura').find('.bpmn-node').should('have.class', 'is-dimmed')
      cy.contains('[data-testid="bpmn-legend"] li', 'En proceso').should('exist')
    })

    it('says in words what the colour, the badge and the fading show', () => {
      cy.contains('.react-flow__node-bpmn', 'Validar factura').find('.bpmn-node').should('have.attr', 'aria-label', 'Validar factura, En proceso')
      cy.contains('.react-flow__node-bpmn', 'Emitir factura').find('.bpmn-node').should('have.attr', 'aria-label', 'Emitir factura, atenuado')
    })

    it('carries the colour and the badge into the exported SVG', () => {
      cy.get('[data-testid="bpmn-node-badge"]').should('have.length', 2)
      cy.get('button[aria-label="Descargar SVG"]').click()
      cy.readFile(`${Cypress.config('downloadsFolder')}/diagram.svg`).then((svg) => {
        expect(svg).to.contain('data-appearance="#E9A23B"')
        expect(svg).to.contain('>En proceso</text>')
        expect(svg).to.contain('opacity="0.45"')
      })
    })
  })

  it('runs no rules with rules: false: no pending issues and no Rules dialog', () => {
    cy.visit('/bali/bpmn_editor/playground?sample=partners')
    cy.get('[data-testid="bpmn-pending-button"]').should('exist')
    cy.visit('/bali/bpmn_editor/playground?sample=partners&rule_severity=off')
    cy.get('[data-testid="bpmn-save-status"]').should('exist')
    cy.get('[data-testid="bpmn-pending-button"]').should('not.exist')
    cy.contains('button', 'Reglas').should('not.exist')
  })

  // The review preview's previous version had «Imprimir factura» where the
  // current one has «Notificar al proveedor»: drawn on one canvas, the removed
  // one moves along its lane instead of covering the added one.
  it('keeps a removed and an added element in the same place apart in the overlay', () => {
    cy.visit('/bali/bpmn_editor/review')
    cy.get('[data-testid="bpmn-compare-button"]').click()
    cy.contains('button', 'Superpuesto').click()
    cy.contains('[data-testid="bpmn-compare"] .react-flow__node-bpmn', 'Imprimir factura').then(($removed) => {
      cy.contains('[data-testid="bpmn-compare"] .react-flow__node-bpmn', 'Notificar al proveedor').then(($added) => {
        const a = $removed[0].getBoundingClientRect()
        const b = $added[0].getBoundingClientRect()
        expect(a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom, 'drawn on top of each other').to.eq(false)
      })
    })
  })

  describe('connecting', () => {
    beforeEach(() => {
      cy.visit('/bali/bpmn_editor/playground')
      cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    })

    it('says what to do, fades what cannot be reached, follows the pointer and cancels with Esc', () => {
      cy.get('[data-testid="bpmn-connect"]').click()
      cy.get('[data-testid="bpmn-connect-banner"]').should('contain', 'Conectando: elige el origen')
      cy.contains('.react-flow__node-bpmn', 'Validar factura').click()
      cy.get('[data-testid="bpmn-connect-banner"]').should('contain', 'Conectando: elige el destino · Esc para cancelar')
      cy.get('[data-testid="bpmn-properties"]').should('not.exist')
      cy.contains('.react-flow__node-bpmn', 'Validar factura').find('.bpmn-node').should('have.class', 'is-connect-source')
      cy.contains('.react-flow__node-bpmn', 'Factura recibida').find('.bpmn-node').should('have.class', 'is-connect-invalid')
      cy.contains('.react-flow__node-bpmn', 'Programar transferencia').find('.bpmn-node').should('not.have.class', 'is-connect-invalid')
      cy.get('.bpmn-canvas').trigger('pointermove', 700, 400, { force: true })
      cy.get('[data-testid="bpmn-connect-guide"] line').invoke('attr', 'x2').then((first) => {
        cy.get('.bpmn-canvas').trigger('pointermove', 760, 460, { force: true })
        cy.get('[data-testid="bpmn-connect-guide"] line').invoke('attr', 'x2').should('not.eq', first)
      })
      cy.get('.bpmn-editor').type('{esc}')
      cy.get('[data-testid="bpmn-connect-banner"]').should('not.exist')
      cy.get('[data-testid="bpmn-connect-guide"]').should('not.exist')
    })

    it('shows the banner for the quick menu’s connection and the palette’s connectors too', () => {
      cy.get('[data-palette-key="message_flow"]').click()
      cy.get('[data-testid="bpmn-connect-banner"]').should('be.visible').find('button').click()
      cy.get('[data-testid="bpmn-connect-banner"]').should('not.exist')
      cy.contains('.react-flow__node-bpmn', 'Validar factura').click()
      cy.get('[data-testid="bpmn-quick-menu"] [data-quick-connect]').click()
      cy.get('[data-testid="bpmn-connect-banner"]').should('contain', 'elige el destino')
    })
  })

  it('never lays the lane’s pending marker over its name', () => {
    cy.visit('/bali/bpmn_editor/playground?sample=empty')
    ;['Solicitante', 'Compras'].forEach((name) => {
      cy.get('[data-testid="bpmn-add-lane"]').click()
      cy.get('input.bpmn-rename').type(`${name}{enter}`)
    })
    cy.get('.bpmn-lane-header .bpmn-lane-issue').should('have.length', 2)
    cy.get('.bpmn-lane-header').each(($header) => {
      const name = $header[0].querySelector('.bpmn-lane-name').getBoundingClientRect()
      const marker = $header[0].querySelector('.bpmn-lane-issue').getBoundingClientRect()
      const overlap = name.left < marker.right && marker.left < name.right && name.top < marker.bottom && marker.top < name.bottom
      expect(overlap, 'the marker covers the name').to.eq(false)
    })
  })

  describe('two different flows compared', () => {
    beforeEach(() => {
      cy.viewport(1440, 1000)
      cy.visit('/bali/bpmn_editor/compare_flows')
      cy.get('[data-testid="bpmn-compare-button"]').click()
    })

    const pane = (side) => `[data-testid="bpmn-compare-pane"][data-side="${side}"]`
    const zoomIn = (side) => cy.get(pane(side)).find('button[aria-label="Acercar"]').click()
    const zoomOf = (side) => cy.get(pane(side)).find('[aria-live="polite"]').invoke('text')

    it('gives the two panes of the comparison the same width and height', () => {
      cy.get('[data-testid="bpmn-compare-pane"]').should('have.length', 2).then(($panes) => {
        const [base, current] = [...$panes].map((pane) => pane.getBoundingClientRect())
        expect(current.width, 'width').to.be.closeTo(base.width, 1)
        expect(current.height, 'height').to.be.closeTo(base.height, 1)
      })
    })

    it('opens side by side, pairs another process by name, and offers no overlay for it', () => {
      cy.get('[data-testid="bpmn-compare-pane"]').should('have.length', 2)
      cy.get('[data-testid="bpmn-compare-by-name"]').should('be.visible')
      cy.get('[data-testid="bpmn-compare-modes"]').should('not.exist')
      cy.get(pane('base')).find('.bpmn-node.bpmn-diff-removed').should('have.length', 2)
      cy.get(pane('current')).find('.bpmn-node.bpmn-diff-added').should('have.length', 2)
    })

    it('compares against what is picked, offering the overlay for versions of the same process', () => {
      cy.get('[data-testid="bpmn-compare-pick"] option').should('have.length', 4)
      cy.get('[data-testid="bpmn-compare-pick"]').select('v1 (ids estables)')
      cy.get('[data-testid="bpmn-compare-summary"] summary').should('have.text', '3 agregados · 1 quitado · 0 cambiados')
      cy.get('[data-testid="bpmn-compare-modes"]').should('be.visible')
      cy.contains('button', 'Superpuesto').click()
      cy.get('[data-testid="bpmn-compare-pane"]').should('have.length', 1)
      // Recreated ids: the same changes by name, but nothing says it is the same process.
      cy.get('[data-testid="bpmn-compare-pick"]').select('v1 (ids recreados)')
      cy.get('[data-testid="bpmn-compare-summary"] summary').should('have.text', '3 agregados · 1 quitado · 0 cambiados')
      cy.get('[data-testid="bpmn-compare-modes"]').should('not.exist')
      cy.get('[data-testid="bpmn-compare-pane"]').should('have.length', 2)
    })

    it('keeps the two panes’ zoom together unless «Sync» is off', () => {
      cy.wait(400)
      zoomIn('base')
      cy.wait(400)
      zoomOf('base').then((base) => zoomOf('current').should('eq', base))
      cy.get('[data-testid="bpmn-compare-sync"]').uncheck()
      zoomIn('base')
      cy.wait(400)
      zoomOf('base').then((base) => zoomOf('current').should('not.eq', base))
    })

    it('highlights an element’s counterpart in the other pane', () => {
      cy.wait(400)
      cy.contains(`${pane('current')} .react-flow__node-bpmn`, 'Notificar al solicitante').trigger('mouseover')
      cy.contains(`${pane('base')} .react-flow__node-bpmn`, 'Notificar al solicitante').find('.bpmn-node').should('have.class', 'is-highlighted')
      cy.contains(`${pane('current')} .react-flow__node-bpmn`, 'Notificar al solicitante').trigger('mouseout')
      cy.get(`${pane('base')} .bpmn-node.is-highlighted`).should('not.exist')
    })

    it('fades what did not change with «Only changes»', () => {
      cy.contains(`${pane('current')} .react-flow__node-bpmn`, 'Revisar documentación').find('.bpmn-node').should('have.css', 'opacity', '1')
      cy.get('[data-testid="bpmn-compare-only-changes"]').check()
      cy.contains(`${pane('current')} .react-flow__node-bpmn`, 'Revisar documentación').find('.bpmn-node').should('have.css', 'opacity', '0.25')
      cy.contains(`${pane('current')} .react-flow__node-bpmn`, 'Validar datos fiscales').find('.bpmn-node').should('have.css', 'opacity', '1')
    })

    it('says what changed in each change of the list', () => {
      cy.get('[data-testid="bpmn-compare-summary"] summary').click()
      cy.contains('[data-change]', 'Registrar en el sistema').find('[data-testid="bpmn-compare-detail"]').should('have.text', 'tipo: Tarea de servicio → Tarea')
      cy.contains('[data-change]', 'Notificar al solicitante').find('[data-testid="bpmn-compare-detail"]').should('have.text', 'carril: Solicitante → Mesa de control')
    })

    it('marks every change with a symbol too, not with colour alone', () => {
      cy.get('[data-testid="bpmn-compare-legend"]').should('contain', '+').and('contain', '−').and('contain', '✎').and('contain', '⇄')
      ;['added', 'removed', 'changed', 'moved'].forEach((mark) => {
        cy.get(`[data-testid="bpmn-compare"] .bpmn-node [data-mark="${mark}"]`).should('have.length.at.least', 1)
      })
      cy.contains('[data-testid="bpmn-compare"] .react-flow__node-bpmn', 'Notificar al solicitante')
        .find('.bpmn-node').should('have.attr', 'aria-label').and('contain', 'Movido de carril')
      cy.get('[data-testid="bpmn-compare"] g.bpmn-edge-diff-mark').should('have.length.at.least', 1)
    })

    it('counts the changes, moves to another lane included, and takes you to each one', () => {
      cy.get('[data-testid="bpmn-compare-summary"] summary')
        .should('have.text', '7 agregados · 7 quitados · 2 cambiados (1 movido de carril)')
      cy.get('[data-testid="bpmn-compare-summary"] summary').click()
      cy.get('[data-testid="bpmn-compare-changes"] button').should('have.length', 10)
      cy.get('[data-testid="bpmn-compare-sync"]').uncheck()
      cy.contains('[data-testid="bpmn-compare-changes"] button', 'Firmar contrato').click()
      cy.contains(`${pane('base')} .react-flow__node-bpmn`, 'Firmar contrato').find('.bpmn-node').should('have.class', 'is-highlighted')
      cy.wait(500)
      cy.get(pane('base')).then(($pane) => {
        const box = $pane[0].getBoundingClientRect()
        cy.contains(`${pane('base')} .react-flow__node-bpmn`, 'Firmar contrato').then(($node) => {
          const node = $node[0].getBoundingClientRect()
          expect(Math.abs(node.left + node.width / 2 - (box.left + box.width / 2))).to.be.lessThan(40)
          expect(Math.abs(node.top + node.height / 2 - (box.top + box.height / 2))).to.be.lessThan(40)
        })
      })
    })

    it('says one change in the singular and several in the plural', () => {
      cy.get('[data-testid="bpmn-compare-pick"]').select('v1 (ids estables)')
      cy.get('[data-testid="bpmn-compare-summary"] summary').should('have.text', '3 agregados · 1 quitado · 0 cambiados')
      cy.visit('/bali/bpmn_editor/compare_flows?locale=en')
      cy.get('[data-testid="bpmn-compare-button"]').click()
      cy.get('[data-testid="bpmn-compare-pick"]').select('v1 (stable ids)')
      cy.get('[data-testid="bpmn-compare-summary"] summary').should('have.text', '3 added · 1 removed · 0 changed')
    })

    it('fits each version into its own pane side by side', () => {
      cy.get('[data-testid="bpmn-compare-pane"]').should('have.length', 2)
      cy.wait(600)
      cy.get('[data-testid="bpmn-compare-pane"]').each(($pane) => {
        const pane = $pane[0].getBoundingClientRect()
        cy.wrap($pane).find('.react-flow__node-bpmn').each(($node) => {
          const node = $node[0].getBoundingClientRect()
          expect(node.left).to.be.gte(pane.left - 1)
          expect(node.right).to.be.lte(pane.right + 1)
          expect(node.top).to.be.gte(pane.top - 1)
          expect(node.bottom).to.be.lte(pane.bottom + 1)
        })
      })
    })
  })
})
