// Bali::BpmnEditor (#1489): the island through the complete host circuit
// (loader, metas, entry, controller) and the main editing flow against the
// dummy's reference endpoints (Admin::ProcessFlows::*). The editable preview
// puts the sample flow back on every visit (its `fresh` param), so each test
// starts from it.

const EDITABLE = '/bali/bpmn_editor/playground'
// The playground's URLs carry the dummy's demo query (`?locale=…&server=…`).
const DIAGRAM = /\/diagram(\?.*)?$/

const nodeNamed = (name) => cy.contains('.react-flow__node-bpmn', name)

// A task from the palette into the first lane of the editor in `scope`.
const placeTask = (scope = 'body') => {
  cy.get(`${scope} [data-palette-key="task"]`).click()
  cy.get(`${scope} [data-testid="bpmn-lane"]`).first().then(($lane) => {
    const lane = $lane[0].getBoundingClientRect()
    const pane = $lane[0].closest('.react-flow').querySelector('.react-flow__pane')
    const box = pane.getBoundingClientRect()
    cy.wrap(pane).click(lane.left - box.left + lane.width * 0.7, lane.top - box.top + lane.height / 2)
  })
}

describe('BPMN editor island', () => {
  it('mounts read-only from the default preview, with lanes, nodes and connections', () => {
    cy.visit('/bali/bpmn_editor/default')
    cy.get('[data-controller="bpmn-editor"] .bpmn-editor').should('be.visible')
    cy.get('[data-testid="bpmn-lane"]').should('have.length', 3)
    cy.get('[data-testid="bpmn-node"]').should('have.length', 9)
    cy.get('.react-flow__edge').should('have.length', 8)
    cy.get('[data-testid="bpmn-save-status"]').should('not.exist')
    cy.get('.bali-bpmn-editor-skeleton').should('not.exist')
  })

  it('folds the legend when the diagram lies under it, and keeps it open when nothing does', () => {
    cy.visit('/bali/bpmn_editor/default')
    cy.get('[data-testid="bpmn-legend"]').should('be.visible')
    cy.visit('/bali/bpmn_editor/playground?sample=large')
    cy.get('.bpmn-legend button[aria-expanded="false"]').should('exist')
    cy.get('[data-testid="bpmn-legend"]').should('not.exist')
  })

  // Its first fit folds the legend (~690 ms at 1000×660); a fold check queued
  // for 400 ms after it mounted (~1000 ms) folded it again under a person who
  // had opened it in between — CI's failure in «hides the external participant
  // checkbox and its legend entries», which opens it at that moment.
  it('keeps open a legend the person opens right after it folded itself', () => {
    cy.viewport(1000, 660)
    cy.visit(`${EDITABLE}?external_lanes=false`)
    cy.get('.bpmn-legend button[aria-expanded="false"]').click()
    cy.wait(800)
    cy.get('[data-testid="bpmn-legend"]').should('contain', 'Actividad')
  })

  // An image or a printout lands on white paper: the outputs take the light
  // theme of the pair even while the page shows the dark one.
  it('exports in the light theme while the page is dark', () => {
    cy.visit('/bali/bpmn_editor/default')
    cy.get('[data-testid="bpmn-node"]').should('have.length', 9)
    cy.document().then((doc) => {
      doc.documentElement.setAttribute('data-theme', 'dark')
      const color = (theme) => {
        const probe = doc.createElement('span')
        probe.setAttribute('data-theme', theme)
        probe.style.color = 'var(--color-base-100)'
        doc.body.appendChild(probe)
        const value = getComputedStyle(probe).color
        probe.remove()
        return value
      }
      cy.wrap({ light: color('light'), dark: color('dark') }).as('base')
    })
    cy.get('button[aria-label="Descargar SVG"]').click()
    cy.get('@base').then(({ light, dark }) => {
      expect(light).not.to.eq(dark)
      // `should`: another test's diagram.svg may still be there when this reads.
      cy.readFile(`${Cypress.config('downloadsFolder')}/diagram.svg`).should((svg) => {
        expect(svg).to.contain(`fill="${light}"`)
        expect(svg).not.to.contain(`fill="${dark}"`)
      })
    })
  })

  // A read-only diagram in a long page: scrolling over it scrolls the page, it
  // does not zoom the canvas out to React Flow's 10 % floor.
  it('lets the page scroll over a read-only diagram', () => {
    cy.visit('/bali/bpmn_editor/catalog?locale=es')
    cy.get('.bpmn-editor [aria-live="polite"]').should('have.text', '40%')
    cy.get('.react-flow__pane').trigger('wheel', { deltaY: 600, bubbles: true })
    cy.get('.react-flow__pane').trigger('wheel', { deltaY: 600, bubbles: true })
    cy.wait(300)
    cy.get('.bpmn-editor [aria-live="polite"]').should('have.text', '40%')
  })

  // The playground's `server` parameter: the dummy answering like a host in
  // trouble (Admin::ProcessFlows::DemoServer).
  describe('playground server modes', () => {
    it('reloads the server version when the save meets a 409', () => {
      cy.visit(`${EDITABLE}?server=conflict`)
      cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
      placeTask()
      cy.get('[data-testid="bpmn-notice"]', { timeout: 8000 }).should('contain', 'Alguien más modificó este diagrama')
    })

    it('opens the pending panel with the issues a refused finalize brings', () => {
      cy.visit(`${EDITABLE}?sample=partners&server=reject_finalize`)
      cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 7)
      cy.get('[data-testid="bpmn-finalize"]').click()
      cy.get('[data-testid="bpmn-pending-panel"]').should('be.visible')
        .and('contain', 'Esta actividad no tiene responsable en la app')
    })
  })

  it('lists the events the editors send in the host console', () => {
    cy.visit('/bali/bpmn_editor/host_integration')
    cy.get('#host_first_bpmn [data-testid="bpmn-node"]').should('have.length.at.least', 9)
    placeTask('#host_first_bpmn')
    cy.get('[data-testid="bpmn-host-console"] [data-event="dirty-change"]').should('exist')
    cy.get('[data-testid="bpmn-host-console"] [data-event="saved"]', { timeout: 8000 }).should('contain', '#host_first_bpmn')
    cy.get('#tab-0 [data-unsaved]').should('have.attr', 'hidden')
  })

  // The minimap takes the theme: on a dark page it is no light grey box.
  it('paints the minimap from the dark theme', () => {
    cy.visit(`${EDITABLE}?sample=partners&theme=dark`)
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 7)
    cy.get('[data-theme="dark"] .react-flow__minimap svg').then(($svg) => {
      const probe = $svg[0].ownerDocument.createElement('span')
      probe.style.color = 'var(--color-base-100)'
      $svg[0].closest('[data-theme]').appendChild(probe)
      const base = getComputedStyle(probe).color
      probe.remove()
      expect(getComputedStyle($svg[0].closest('.react-flow__minimap')).backgroundColor).to.eq(base)
      expect(getComputedStyle($svg[0].querySelector('.react-flow__minimap-mask')).fill).not.to.eq('rgba(240, 240, 240, 0.6)')
      // React Flow's attribution, too: no white patch, no fixed #999.
      const attribution = $svg[0].closest('.react-flow').querySelector('.react-flow__attribution')
      expect(getComputedStyle(attribution).backgroundColor).not.to.eq('rgba(255, 255, 255, 0.5)')
      expect(getComputedStyle(attribution.querySelector('a')).color).not.to.eq('rgb(153, 153, 153)')
    })
  })

  // Several editors on one page used to end in Chrome's «ResizeObserver loop
  // completed with undelivered notifications»: React committed the second
  // editor inside the first one's React Flow node observer, and the observers
  // it created there went undelivered. React Flow now mounts a frame later
  // (BpmnEditor.jsx, canvasReady). Counted on the window, whatever Cypress
  // does with uncaught errors.
  ;['pair', 'split_view', 'host_integration'].forEach((preview) => {
    it(`reports no ResizeObserver loop with several editors on one page (${preview})`, () => {
      cy.visit(`/bali/bpmn_editor/${preview}`, {
        onBeforeLoad (win) {
          win.resizeObserverLoops = 0
          win.addEventListener('error', (event) => { if (String(event.message).includes('ResizeObserver loop')) win.resizeObserverLoops++ })
        }
      })
      cy.get('.react-flow__node-bpmn').should('have.length.greaterThan', 5)
      cy.wait(800)
      cy.window().its('resizeObserverLoops').should('eq', 0)
    })
  })

  // Two editors mint the same client ids: an event the host sends to one
  // must not change the other.
  it('delivers a host event to the editor it names and to no other', () => {
    cy.visit('/bali/bpmn_editor/pair')
    cy.get('#second_bpmn .react-flow__node-bpmn').should('contain', 'Procedimiento')
    cy.get('#first_bpmn').then(($el) => {
      $el[0].dispatchEvent(new CustomEvent('bali-bpmn:reference-created', {
        bubbles: true, detail: { client_node_id: 'sp', reference: { id: '7', label: 'Alta de proveedores' } }
      }))
    })
    cy.get('#first_bpmn .react-flow__node-bpmn').should('contain', 'Alta de proveedores')
    cy.wait(300)
    cy.get('#second_bpmn .react-flow__node-bpmn').should('contain', 'Procedimiento').and('not.contain', 'Alta de proveedores')
  })

  describe('editing', () => {
    beforeEach(() => {
      cy.intercept('PUT', DIAGRAM).as('save')
      cy.visit(EDITABLE)
      cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    })

    it('places an element from the palette and autosaves the whole document', () => {
      cy.get('[data-palette-key="task"]').click()
      // An empty spot of the first lane, in the pane's own coordinates: the
      // lane body lets the click through to the pane, which places the element.
      cy.get('[data-testid="bpmn-lane"]').first().then(($lane) => {
        const lane = $lane[0].getBoundingClientRect()
        const pane = $lane[0].ownerDocument.querySelector('.react-flow__pane').getBoundingClientRect()
        cy.get('.react-flow__pane').click(lane.left - pane.left + lane.width * 0.7, lane.top - pane.top + lane.height / 2)
      })
      cy.get('[data-testid="bpmn-node"]').should('have.length', 10)
      cy.wait('@save').then(({ request, response }) => {
        expect(request.body.diagram.nodes).to.have.length(10)
        expect(request.body).to.have.property('version')
        expect(response.statusCode).to.eq(200)
      })
      cy.get('[data-testid="bpmn-save-status"]').should('contain', 'Borrador guardado')
    })

    // The user's case: an activity that already has its way out, one more
    // element asked for to the right.
    it('turns a second way out of an activity into a split instead of refusing it', () => {
      nodeNamed('Registrar pago').click()
      cy.get('[data-testid="bpmn-quick-menu"] [aria-label="Derecha"]').click()
      cy.get('[data-testid="bpmn-quick-menu"] [data-quick="task"]').click()
      cy.get('[data-testid="bpmn-branch-with"]').should('contain', 'Bifurcar con')
        .find('[data-branch="binary_decision"]').should('contain', 'Decisión Sí/No').click()
      cy.get('[data-testid="bpmn-notice"]').should('not.exist')
      cy.get('[data-testid="bpmn-node"]').should('have.length', 11)
      cy.get('.react-flow__edge').should('have.length', 10)
      // The gateway, the new branch and the arrangement are one step.
      cy.get('body').type('{ctrl}z')
      cy.get('[data-testid="bpmn-node"]').should('have.length', 9)
    })

    it('offers the split on a connection the one-in, one-out rule refuses', () => {
      cy.get('[data-testid="bpmn-connect"]').click()
      nodeNamed('Programar transferencia').click()
      nodeNamed('Fin').click()
      cy.get('[data-testid="bpmn-notice"]').should('contain', 'regla de entradas y salidas')
      cy.get('[data-testid="bpmn-notice-action"]').should('contain', 'Agregar gateway').click()
      cy.get('[data-testid="bpmn-node"]').should('have.length', 10)
      cy.get('.react-flow__edge').should('have.length', 10)
    })

    // Rework (AFAL COM-22): the way back into an activity that already has its
    // way in goes through a merging XOR, offered on the spot.
    it('offers the merging XOR on a way back into an activity', () => {
      cy.get('[data-testid="bpmn-connect"]').click()
      nodeNamed('¿La factura es válida?').click({ position: 'center' })
      nodeNamed('Validar factura').click()
      cy.get('[data-testid="bpmn-notice-action"]').should('contain', 'Agregar XOR de unión').click()
      cy.get('[data-testid="bpmn-node"]').should('have.length', 10)
      cy.get('.react-flow__edge').should('have.length', 10)
    })

    it('disables a direction nothing can be added in, and says why', () => {
      nodeNamed('Factura recibida').click()
      cy.get('[data-testid="bpmn-quick-menu"] [aria-label="Izquierda"]')
        .should('have.attr', 'aria-disabled', 'true')
        .and('have.attr', 'title').and('contain', 'No fue posible')
    })

    // Someone else saved first: the 409 reloads their version and says so.
    it('reloads the server version on a 409 and says why', () => {
      cy.intercept('PUT', DIAGRAM, { statusCode: 409, body: { errors: ['stale'] } }).as('stale')
      cy.intercept('GET', DIAGRAM).as('fetch')
      cy.get('[data-palette-key="task"]').click()
      cy.get('[data-testid="bpmn-lane"]').first().then(($lane) => {
        const lane = $lane[0].getBoundingClientRect()
        const pane = $lane[0].ownerDocument.querySelector('.react-flow__pane').getBoundingClientRect()
        cy.get('.react-flow__pane').click(lane.left - pane.left + lane.width * 0.7, lane.top - pane.top + lane.height / 2)
      })
      cy.get('[data-testid="bpmn-node"]').should('have.length', 10)
      cy.get('[data-testid="bpmn-save-draft"], button').contains('Guardar borrador').click()
      cy.wait('@stale')
      cy.wait('@fetch')
      cy.get('[data-testid="bpmn-notice"]').should('contain', 'Alguien más modificó este diagrama')
      cy.get('[data-testid="bpmn-node"]').should('have.length', 9)
    })

    const placeSubProcess = () => {
      cy.get('[data-palette-key="sub_process"]').click()
      cy.get('[data-testid="bpmn-lane"]').eq(2).then(($lane) => {
        const lane = $lane[0].getBoundingClientRect()
        const pane = $lane[0].ownerDocument.querySelector('.react-flow__pane').getBoundingClientRect()
        cy.get('.react-flow__pane').click(lane.left - pane.left + 220, lane.top - pane.top + lane.height / 2)
      })
    }

    it('says the reference search failed instead of finding nothing', () => {
      cy.intercept('GET', /\/references(\?.*)?$/, { statusCode: 500, body: {} })
      placeSubProcess()
      cy.get('[data-testid="bpmn-search-failed"]').should('contain', 'La búsqueda falló')
    })

    it('opens a linked reference through a real link the host may take over', () => {
      placeSubProcess()
      cy.get('[data-testid="bpmn-properties"] .max-h-48 button').first().click()
      cy.get('[data-testid="bpmn-open-reference"]').should('have.attr', 'href').and('match', /^\//)
      cy.document().then((doc) => doc.addEventListener('bali-bpmn:open-reference', (event) => { event.preventDefault(); doc.body.dataset.opened = event.detail.reference.label }))
      cy.location('pathname').then((before) => {
        cy.get('[data-testid="bpmn-open-reference"]').click()
        cy.get('body').should('have.attr', 'data-opened')
        cy.location('pathname').should('eq', before)
      })
    })

    // The canvas position React Flow draws a node at (its transform).
    const positionOf = (name) => nodeNamed(name).closest('.react-flow__node').then(($n) => {
      const [, x, y] = $n[0].style.transform.match(/translate\(([-\d.]+)px, ([-\d.]+)px\)/)
      return { x: Number(x), y: Number(y) }
    })

    it('moves the selected element with the arrows: 10 px a press, 1 px with Shift, one undo step', () => {
      positionOf('Registrar pago').then((start) => {
        nodeNamed('Registrar pago').click()
        cy.get('body').type('{rightarrow}{rightarrow}{rightarrow}')
        positionOf('Registrar pago').should((now) => expect(now.x).to.eq(start.x + 30))
        cy.get('body').type('{shift}{downarrow}{downarrow}')
        positionOf('Registrar pago').should((now) => expect(now.y).to.eq(start.y + 2))
        cy.get('body').type('{ctrl}z')
        positionOf('Registrar pago').should((now) => expect(now.y).to.eq(start.y))
      })
    })

    // The palette explains each element: name, what it is, when to use it —
    // on hover and on keyboard focus, gone when the pointer or focus leaves.
    it('shows what a palette element is on hover and on focus', () => {
      cy.get('[data-palette-key="user_task"]').trigger('mouseover')
      cy.get('[data-testid="bpmn-hint"]').should('be.visible')
        .and('contain', 'Tarea de usuario')
        .and('contain', 'Trabajo que una persona hace con ayuda de una aplicación')
        .invoke('attr', 'id').then((id) => {
          cy.get('[data-palette-key="user_task"]').should('have.attr', 'aria-describedby', id)
        })
      cy.get('[data-palette-key="user_task"]').trigger('mouseout')
      cy.get('[data-testid="bpmn-hint"]').should('not.exist')
      cy.get('[data-palette-key="exclusive_gateway"]').focus()
      cy.get('[data-testid="bpmn-hint"]').should('contain', 'Gateway exclusivo')
      cy.get('[data-palette-key="exclusive_gateway"]').blur()
      cy.get('[data-testid="bpmn-hint"]').should('not.exist')
    })

    it('undoes and redoes with the keyboard', () => {
      nodeNamed('¿La factura es válida?').click()
      cy.get('[data-testid="bpmn-quick-menu"] [data-quick="end_event"]').click()
      cy.get('[data-testid="bpmn-node"]').should('have.length', 10)
      cy.get('body').type('{ctrl}z')
      cy.get('[data-testid="bpmn-node"]').should('have.length', 9)
      cy.get('body').type('{ctrl}y')
      cy.get('[data-testid="bpmn-node"]').should('have.length', 10)
    })

    it('does not finalize with errors: the pending panel opens instead', () => {
      cy.intercept('POST', /\/finalization(\?.*)?$/).as('finalize')
      cy.get('[data-testid="bpmn-pending-button"]').should('contain', 'pendiente')
      cy.get('[data-testid="bpmn-finalize"]').click()
      cy.get('[data-testid="bpmn-pending-panel"]').should('be.visible').find('[data-rule="R07"]').should('exist')
      cy.wait(300)
      cy.get('@finalize.all').should('have.length', 0)
      cy.get('[data-testid="bpmn-pending-panel"] [data-rule="R07"]').click()
      cy.get('[data-testid="bpmn-pending-panel"]').should('not.exist')
      cy.get('.react-flow__node-bpmn.selected').should('contain', 'Fin')
    })

    // BPMN 2.0 notation: an activity is a rectangle with rounded corners, not
    // a pill; a group a rounded rectangle; a collapsed sub-process carries its
    // [+] at the bottom centre.
    it('draws the palette icons as the BPMN shapes they create', () => {
      const shape = (key) => cy.get(`[data-palette-key="${key}"] svg rect`).first()
      const ratio = ($rect, attr) => Number($rect.attr('rx')) / Number($rect.attr(attr))
      shape('task').should(($rect) => expect(ratio($rect, 'height')).to.be.at.most(0.15))
      shape('group').should(($rect) => {
        expect(ratio($rect, 'height')).to.be.at.most(0.15)
        expect(Number($rect.attr('width')) / Number($rect.attr('height'))).to.be.greaterThan(1.2)
      })
      cy.get('[data-palette-key="sub_process"] svg rect').then(($rects) => {
        const [frame, marker] = [$rects[0], $rects[1]]
        expect(Number(marker.getAttribute('y'))).to.be.greaterThan(Number(frame.getAttribute('height')) / 2)
      })
    })

    it('marks an external lane grey and its activities white', () => {
      cy.get('[data-testid="bpmn-lane"].is-external').should('have.length', 1)
      // Same shape, different fill: the external activity is drawn on the
      // page colour, the internal one on the tinted activity colour.
      nodeNamed('Emitir factura').find('.bpmn-node-shape rect').first().then(($external) => {
        nodeNamed('Validar factura').find('.bpmn-node-shape rect').first().should(($internal) => {
          expect($external.css('fill')).not.to.eq($internal.css('fill'))
        })
      })
      cy.get('[data-testid="bpmn-legend"]').should('contain', 'participante externo')
      cy.get('[data-testid="bpmn-lane"]').eq(1).find('.bpmn-lane-header').click()
      cy.get('[data-testid="bpmn-lane-external"]').should('be.visible')
    })

    // `external_lanes: false`: an app without external participants offers no
    // checkbox for them, and its legend does not explain them.
    it('hides the external participant checkbox and its legend entries when the host turns them off', () => {
      cy.visit(`${EDITABLE}?external_lanes=false`)
      cy.get('[data-testid="bpmn-lane"]').eq(1).find('.bpmn-lane-header').click()
      cy.get('[data-testid="bpmn-properties"]').should('be.visible')
      cy.get('[data-testid="bpmn-lane-external"]').should('not.exist')
      // The legend folds itself over a diagram (it hides behind the open panel
      // anyway): its entries are what is checked here.
      cy.get('[data-testid="bpmn-properties"] button[aria-label="Cerrar"]').click()
      cy.get('.bpmn-legend button').then(($toggle) => { if ($toggle.attr('aria-expanded') === 'false') cy.wrap($toggle).click() })
      cy.get('[data-testid="bpmn-legend"]').should('contain', 'Actividad').and('not.contain', 'participante externo')
    })
  })
})

// The rules gallery preview: one rule at a time, its failing example listed in
// the pending-issues panel the preview opens on load, its passing one not.
describe('BPMN editor rules gallery', () => {
  it('rules gallery with example=failing shows the rule in the pending panel', () => {
    cy.visit('/bali/bpmn_editor/rules_gallery?rule=R06&example=failing')
    cy.get('[data-testid="bpmn-pending-panel"]').should('be.visible').find('[data-rule="R06"]').should('exist')
    cy.visit('/bali/bpmn_editor/rules_gallery?rule=R06&example=passing')
    cy.get('[data-testid="bpmn-pending-panel"]').should('be.visible').find('[data-rule="R06"]').should('not.exist')
  })
})

// A phone: the palette and «To place» start folded, the toolbars keep their
// icons, and a selection does not open the properties panel by itself — so
// «Connect» and the quick menu are not covered.
describe('BPMN editor on a narrow screen', () => {
  const inside = ($el, $canvas) => {
    const box = $el[0].getBoundingClientRect()
    const canvas = $canvas[0].getBoundingClientRect()
    expect(box.left, 'left').to.be.at.least(canvas.left - 1)
    expect(box.right, 'right').to.be.at.most(canvas.right + 1)
  }

  beforeEach(() => {
    cy.viewport(390, 844)
    cy.visit('/bali/bpmn_editor/playground')
    nodeNamed('Validar factura').should('be.visible')
  })

  it('starts with the palette, «To place» and the legend folded and reaches «Connect»', () => {
    cy.get('[data-testid="bpmn-palette"]').should('not.exist')
    cy.get('button[aria-label="Mostrar elementos"]').should('be.visible')
    cy.get('[data-testid="bpmn-stencil"] button[aria-expanded]').should('have.attr', 'aria-expanded', 'false')
    cy.get('.bpmn-legend button[aria-expanded]').should('have.attr', 'aria-expanded', 'false')
    cy.get('.react-flow__minimap').should('not.be.visible')
    // No `force`: a click on a covered button fails.
    cy.get('[data-testid="bpmn-add-lane"]').should('be.visible')
    cy.get('[data-testid="bpmn-auto-layout"]').should('be.visible').click()
    cy.get('[data-testid="bpmn-connect"]').should('be.visible').click()
    cy.get('[data-testid="bpmn-connect-banner"]').should('be.visible').then(($banner) => {
      cy.get('.bpmn-canvas').then(($canvas) => inside($banner, $canvas))
    })
    cy.get('[data-testid="bpmn-connect-banner"] button').click()
    cy.get('[data-testid="bpmn-connect-banner"]').should('not.exist')
  })

  it('opens the palette as a layer over the canvas, and folds it once an element is picked', () => {
    cy.get('button[aria-label="Mostrar elementos"]').click()
    cy.get('[data-testid="bpmn-palette"]').should('have.css', 'position', 'absolute')
    cy.get('.bpmn-canvas').invoke('outerWidth').should('be.greaterThan', 250)
    cy.get('button[aria-label="Ocultar elementos"]').should('be.visible').click()
    cy.get('[data-testid="bpmn-palette"]').should('not.exist')
    cy.get('button[aria-label="Mostrar elementos"]').click()
    cy.get('[data-testid="bpmn-palette"] [data-palette-key="task"]').click()
    cy.get('[data-testid="bpmn-palette"]').should('not.exist')
    cy.get('.bpmn-canvas').should('have.class', 'is-placing')
  })

  it('keeps the quick menu inside the canvas and opens the panel only when asked', () => {
    cy.get('.react-flow__node-bpmn').its('length').then((before) => {
      nodeNamed('Validar factura').click()
      cy.get('[data-testid="bpmn-properties"]').should('not.exist')
      cy.get('[data-testid="bpmn-quick-menu"]').should('be.visible').then(($menu) => {
        cy.get('.bpmn-canvas').then(($canvas) => inside($menu, $canvas))
      })
      cy.get('.bpmn-legend').should('not.be.visible')
      cy.get('[data-testid="bpmn-quick-menu"] [data-quick="task"]').click()
      cy.get('.react-flow__node-bpmn').should('have.length', before + 1)
    })
    cy.get('[data-testid="bpmn-properties-toggle"]').click()
    cy.get('[data-testid="bpmn-properties"]').should('be.visible')
  })
})
