// A lane's `appearance` (colour, dimmed, badge): the app's, like a node's —
// drawn on the canvas and in the outputs, never sent back in a save, taken
// fresh from every 200. And a lane's assignee, removed, leaves its name.

const DIAGRAM = /\/diagram(\?.*)?$/
const SHOTS = 'bpmn-lane-appearance'
const laneNamed = (name) => cy.contains('[data-testid="bpmn-lane"]', name)
const rect = (el) => el.getBoundingClientRect()
const overlap = (a, b) => a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom

describe('a lane’s appearance on a read-only diagram', () => {
  beforeEach(() => cy.visit('/bali/bpmn_editor/default?appearance=true'))

  it('tints the header, badges it with legible text and says it in the legend', () => {
    laneNamed('Tesorería').should('have.class', 'has-color').within(() => {
      cy.get('[data-testid="bpmn-lane-badge"]').should('have.text', 'Sin responsable')
        .and('have.css', 'color', 'rgb(255, 255, 255)')
    })
    laneNamed('Cuentas por pagar').should('not.have.class', 'has-color').find('[data-testid="bpmn-lane-badge"]').should('not.exist')
    cy.contains('[data-testid="bpmn-legend"] li', 'Sin responsable').should('exist')
    cy.screenshot(`${SHOTS}/read-only-horizontal`)
  })

  it('keeps the rotated name, the badge and each other apart', () => {
    laneNamed('Tesorería').find('.bpmn-lane-header').then(($header) => {
      const header = rect($header[0])
      const title = rect($header[0].querySelector('.bpmn-lane-title'))
      const badge = rect($header[0].querySelector('[data-testid="bpmn-lane-badge"]'))
      expect(overlap(title, badge), 'badge over the name').to.equal(false)
      for (const part of [title, badge]) {
        expect(part.left, 'inside the header').to.be.at.least(header.left - 0.5)
        expect(part.right, 'inside the header').to.be.at.most(header.right + 0.5)
      }
      expect(badge.right, 'on the outer side').to.be.at.most(title.left + 0.5)
    })
  })

  it('hides the lane’s badge with «Show badges», and keeps the colour', () => {
    cy.get('[data-testid="bpmn-badge-toggle"]').click()
    laneNamed('Tesorería').should('have.class', 'has-color').find('[data-testid="bpmn-lane-badge"]').should('not.exist')
  })

  it('carries the colour and the badge into the exported SVG', () => {
    cy.get('[data-testid="bpmn-lane-badge"]').should('have.length', 1)
    cy.get('button[aria-label="Descargar SVG"]').click()
    cy.readFile(`${Cypress.config('downloadsFolder')}/diagram.svg`).should((svg) => {
      expect(svg).to.contain('data-appearance="#dc2626"')
      expect(svg).to.contain('>Sin responsable</text>')
    })
  })
})

// The dummy sends no lane appearance while editing: each 200 gets one here,
// as an app's server would add it — while `looks.on` says so.
describe('a lane’s appearance while editing', () => {
  const looks = { on: true }
  beforeEach(() => { looks.on = true })
  const answerWithLooks = () => {
    cy.intercept('PUT', DIAGRAM, (request) => {
      request.continue((response) => {
        if (!looks.on || response.statusCode !== 200) return
        response.body.lanes = response.body.lanes.map((lane, i) => ({
          ...lane, appearance: i === 0 ? { color: '#dc2626', badge: 'Sin responsable' } : { dimmed: true }
        }))
      })
    }).as('save')
  }
  const addLanes = (...names) => names.forEach((name) => {
    cy.get('[data-testid="bpmn-add-lane"]').click()
    cy.get('input.bpmn-rename').type(`${name}{enter}`)
  })

  for (const orientation of ['horizontal', 'vertical']) {
    it(`draws what each 200 brings, never sends it back, and drops it when a 200 stops bringing it (${orientation})`, () => {
      answerWithLooks()
      cy.visit(`/bali/bpmn_editor/playground?sample=empty&orientation=${orientation}`)
      addLanes('Solicitante', 'Compras')
      laneNamed('Solicitante').find('[data-testid="bpmn-lane-badge"]', { timeout: 8000 }).should('have.text', 'Sin responsable')
      laneNamed('Compras').should('have.class', 'is-dimmed').find('.sr-only').should('contain', 'atenuado')
      // Empty lanes are pending: the marker, the badge and the name share the header.
      laneNamed('Solicitante').find('.bpmn-lane-header').then(($header) => {
        const parts = ['.bpmn-lane-title', '[data-testid="bpmn-lane-badge"]', '.bpmn-lane-issue'].map((s) => rect($header[0].querySelector(s)))
        for (let a = 0; a < parts.length; a++) for (let b = a + 1; b < parts.length; b++) expect(overlap(parts[a], parts[b]), `parts ${a} and ${b} overlap`).to.equal(false)
      })
      cy.screenshot(`${SHOTS}/editing-${orientation}`)

      cy.then(() => { looks.on = false })
      cy.intercept('PUT', DIAGRAM).as('rename')
      laneNamed('Solicitante').find('.bpmn-lane-header').dblclick()
      cy.get('input.bpmn-rename').clear().type('Solicitante interno{enter}')
      cy.wait('@rename').its('request.body.diagram.lanes').should((lanes) => {
        expect(lanes.map((lane) => lane.name)).to.deep.equal(['Solicitante interno', 'Compras'])
        expect(lanes.filter((lane) => 'appearance' in lane), 'appearance sent back').to.have.length(0)
      })
      cy.get('[data-testid="bpmn-lane-badge"]').should('not.exist')
      laneNamed('Compras').should('not.have.class', 'is-dimmed')
    })
  }
})

describe('a lane’s assignee', () => {
  it('removed, leaves the lane its name', () => {
    cy.intercept('PUT', DIAGRAM).as('save')
    cy.visit('/bali/bpmn_editor/playground')
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    cy.get('[data-controller="bpmn-editor"]').then(($host) => {
      $host[0].dispatchEvent(new CustomEvent('bali-bpmn:lane-assignee-created', {
        detail: { client_lane_id: 'l2', assignee: { id: '9', label: 'Equipo de pagos' } }
      }))
    })
    cy.wait('@save').its('request.body.diagram.lanes').should((lanes) => {
      const lane = lanes.find((l) => l.id === 'l2')
      expect(lane.assignee.label).to.equal('Equipo de pagos')
      expect(lane.name).to.equal('Cuentas por pagar')
    })
    laneNamed('Cuentas por pagar').find('.bpmn-lane-header').click()
    cy.contains('button', 'Desvincular').click()
    cy.contains('Equipo de pagos').should('not.exist')
    laneNamed('Cuentas por pagar').should('exist')
    cy.wait('@save').its('request.body.diagram.lanes').should((lanes) => {
      const lane = lanes.find((l) => l.id === 'l2')
      expect(lane.assignee).to.equal(null)
      expect(lane.name).to.equal('Cuentas por pagar')
    })
  })
})
