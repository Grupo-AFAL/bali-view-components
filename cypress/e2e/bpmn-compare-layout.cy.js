// Bali::BpmnEditor: a `compare_with:` document without geometry is laid out
// as the editor's own document is on load — in its lanes, with the
// component's `layout:` and `page:`.

const FLOWS = '/bali/bpmn_editor/compare_flows'
const EDITOR = '#compare_flows_bpmn'
const pane = (side) => `${EDITOR} [data-testid="bpmn-compare-pane"][data-side="${side}"]`
const LOADED = { timeout: 10000 }

// The distinct rows (translate y) the pane's nodes sit on.
const rowsOf = ($nodes) => new Set($nodes.toArray().map((el) => Math.round(new window.DOMMatrix(el.style.transform).f))).size

describe('BPMN editor: comparing documents without geometry', () => {
  beforeEach(() => cy.viewport(1440, 1000))

  ;[0, 2].forEach((index) => {
    it(`lays out the compared document in its lanes (option ${index})`, () => {
      cy.visit(`${FLOWS}?chrome=minimal&compare_open=true&geometry=false&compare_index=${index}`)
      cy.get(`${pane('base')} .react-flow__node-bpmn`, LOADED).should('have.length.greaterThan', 5)
      cy.get(`${pane('base')} [data-testid="bpmn-lane"]`).should('have.length', 4)
      cy.get(`${pane('base')} .react-flow__node-bpmn`).should(($nodes) => expect(rowsOf($nodes)).to.be.greaterThan(1))
    })
  })

  // The customer and supplier onboarding flows have the same shape: laid out
  // with the same `layout:` (compact, the component's default) their pools
  // are equally long, 1320 px; with autoLayout's own default (straight) the
  // compared one was 1760 px.
  it('lays out the compared document with the component layout, as the editor own', () => {
    cy.visit(`${FLOWS}?chrome=minimal&compare_open=true&geometry=false&compare_index=0`)
    cy.get(`${pane('base')} .react-flow__node-bpmn`, LOADED).should('have.length.greaterThan', 5)
    const length = (side) => parseFloat(Cypress.$(`${pane(side)} .react-flow__node-lane`).first()[0].style.width)
    cy.get(`${pane('base')} .react-flow__node-lane`).should(() => expect(length('base')).to.equal(length('current')))
  })
})

// An app's two versions of one flow without geometry, a lane name repeated
// and lane ids shared with another meaning (test/fixtures/bpmn_editor/
// compare_shared_lane_ids.json), compared by name in `chrome: :minimal`.
// Laid out straight, the compared one was a 3140 × 480 pool, which its pane
// fits at 20 %: one row, 24 px lane bands. Compact, as the editor's own, it
// is 1420 × 720.
describe('BPMN editor: comparing an app document without geometry', () => {
  const EDITOR = '#shared_lane_ids_bpmn'
  const side = (name) => `${EDITOR} [data-testid="bpmn-compare-pane"][data-side="${name}"]`
  // The pool's proportions, whatever the zoom: the lane bands together.
  const proportions = ($lanes) => {
    const boxes = $lanes.toArray().map((el) => el.getBoundingClientRect())
    const height = Math.max(...boxes.map((b) => b.bottom)) - Math.min(...boxes.map((b) => b.top))
    return boxes[0].width / height
  }

  it('shows both versions in their four lanes, laid out as the editor lays out its own', () => {
    cy.viewport(1440, 900)
    cy.visit('/bali/bpmn_editor/compare_shared_lane_ids')
    cy.get(`${side('base')} .react-flow__node-bpmn`, LOADED).should('have.length', 13)
    cy.get(`${side('current')} .react-flow__node-bpmn`).should('have.length', 13)
    ;['base', 'current'].forEach((name) => {
      cy.get(`${side(name)} [data-testid="bpmn-lane"]`).should('have.length', 4)
        .should(($lanes) => expect(proportions($lanes), `${name} pool width / height`).to.be.below(3))
    })
    // Added, removed, changed: the repeated lane name pairs by its order.
    cy.get(`${EDITOR} [data-testid="bpmn-compare-summary"] summary`).invoke('text').should('match', /^3\D+5\D+0\D/)
  })
})
