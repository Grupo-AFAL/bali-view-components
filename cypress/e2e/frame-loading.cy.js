// El swap de Bali::Frame es CSS puro sobre [busy] (`:has(> turbo-frame[busy])`).
// Hay que MEDIRLO en un navegador de verdad: un @import roto o un selector mal
// escrito pasarían los tests de render del componente (que solo miran el markup
// del server, sin CSS ni Turbo). Aquí se togglea [busy] como lo hace Turbo en
// cada carga y se asserta la visibilidad COMPUTADA.
describe('Bali::Frame: swap de carga con [busy]', () => {
  const frame = 'turbo-frame#frame-preview-default'

  it('sin [busy]: se ve el frame, se oculta el placeholder', () => {
    cy.visit('/bali/frame/default')
    cy.get(frame).should('be.visible')
    cy.get('.frame-loading').should('not.be.visible')
  })

  it('con [busy]: se oculta el frame y aparece el placeholder', () => {
    cy.visit('/bali/frame/default')
    cy.get(frame).invoke('attr', 'busy', '')
    cy.get('.frame-loading').should('be.visible')
    cy.get(frame).should('not.be.visible')
  })

  it('quitar [busy] (carga terminada) devuelve el frame y oculta el placeholder', () => {
    cy.visit('/bali/frame/default')
    cy.get(frame).invoke('attr', 'busy', '')
    cy.get('.frame-loading').should('be.visible')
    cy.get(frame).invoke('removeAttr', 'busy')
    cy.get(frame).should('be.visible')
    cy.get('.frame-loading').should('not.be.visible')
  })
})
