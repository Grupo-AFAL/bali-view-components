// `confirm_linked_delete:` — deleting a sub-process linked to an entity of
// the app asks first. Once deleted, the host's «To place» list offers that
// entity again (the dummy's stencil lists what no sub-process links).

const DIAGRAM = /\/diagram(\?.*)?$/
const PLAYGROUND = '/bali/bpmn_editor/playground'

// A sub-process from the palette, linked to the first «To place» entity as the
// host's drawer would link it; yields that entity's label.
const placeLinkedSubProcess = () => {
  cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
  cy.get('[data-palette-key="sub_process"]').click()
  cy.get('[data-testid="bpmn-lane"]').eq(1).then(($lane) => {
    const lane = $lane[0].getBoundingClientRect()
    const pane = $lane[0].closest('.react-flow').querySelector('.react-flow__pane')
    const box = pane.getBoundingClientRect()
    cy.wrap(pane).click(lane.left - box.left + lane.width * 0.85, lane.top - box.top + lane.height * 0.75)
  })
  return cy.get('[data-controller="bpmn-editor"]').then(($host) => {
    const reference = JSON.parse($host.attr('data-bpmn-editor-data-value')).stencil[0].reference
    cy.get('.react-flow__node-bpmn.selected [data-node-id]').invoke('attr', 'data-node-id').then((nodeId) => {
      $host[0].dispatchEvent(new CustomEvent('bali-bpmn:reference-created', { detail: { client_node_id: nodeId, reference } }))
    })
    cy.contains('.react-flow__node-bpmn', reference.label).should('exist')
    // Its last entity linked, «To place» goes away.
    cy.get('body').should(($body) => expect($body.find('[data-testid="bpmn-stencil"]').text()).not.to.contain(reference.label))
    return cy.wrap(reference.label)
  })
}

describe('deleting a linked sub-process', () => {
  beforeEach(() => cy.intercept('PUT', DIAGRAM).as('save'))

  it('asks first with confirm_linked_delete, and the entity returns to «To place»', () => {
    cy.visit(`${PLAYGROUND}?confirm_linked_delete=true`)
    placeLinkedSubProcess().then((label) => {
      cy.contains('button', 'Eliminar seleccionado').click()
      cy.get('[data-testid="bpmn-confirm-delete"]').should('be.visible').and('contain', label)
      cy.screenshot('bpmn-linked-delete/confirm')
      cy.contains('[data-testid="bpmn-confirm-delete"] button', 'Cancelar').click()
      cy.get('[data-testid="bpmn-confirm-delete"]').should('not.exist')
      cy.contains('.react-flow__node-bpmn', label).should('have.class', 'selected')

      cy.contains('button', 'Eliminar seleccionado').click()
      cy.get('[data-testid="bpmn-confirm-delete-accept"]').click()
      cy.contains('.react-flow__node-bpmn', label).should('not.exist')
      cy.get('[data-testid="bpmn-stencil"]', { timeout: 8000 }).should('contain', label)
    })
  })

  it('deletes an unlinked element at once, even with confirm_linked_delete', () => {
    cy.visit(`${PLAYGROUND}?confirm_linked_delete=true`)
    cy.get('[data-testid="bpmn-node"]').should('have.length.at.least', 9)
    cy.contains('.react-flow__node-bpmn', 'Registrar pago').click()
    cy.contains('button', 'Eliminar seleccionado').click()
    cy.get('[data-testid="bpmn-confirm-delete"]').should('not.exist')
    cy.contains('.react-flow__node-bpmn', 'Registrar pago').should('not.exist')
  })

  it('deletes a linked one at once without the option', () => {
    cy.visit(PLAYGROUND)
    placeLinkedSubProcess().then((label) => {
      cy.contains('button', 'Eliminar seleccionado').click()
      cy.get('[data-testid="bpmn-confirm-delete"]').should('not.exist')
      cy.contains('.react-flow__node-bpmn', label).should('not.exist')
    })
  })
})
