import { cdp, frameAt } from '../support/accessibility_tree'

// #1336 — with six actions the Topbar's search slot is left 42px at 360 and 72px at 390,
// where the Command trigger's label truncated to "Se…". Below 6rem of slot the trigger
// folds to a square around its icon. Its name is read from Chromium's accessibility tree,
// which is what a screen reader is handed: the label is still there, only visually hidden.
describe('Topbar search collapse', () => {
  const trigger = '.bali-topbar .bali-command-trigger'
  const label = `${trigger} > span:not(.icon-component)`

  const triggerName = () =>
    cy.url().then((url) =>
      cdp('Page.getFrameTree')
        .then(({ frameTree }) => cdp('DOM.getFrameOwner', { frameId: frameAt(frameTree, url).id }))
        .then(({ backendNodeId }) => cdp('DOM.describeNode', { backendNodeId, depth: 1, pierce: true }))
        .then(({ node }) => cdp('DOM.resolveNode', { backendNodeId: node.contentDocument.backendNodeId }))
        .then(({ object }) =>
          cdp('Runtime.callFunctionOn', {
            objectId: object.objectId,
            functionDeclaration: `function () { return this.querySelector('${trigger}') }`
          })
        )
        .then(({ result }) => cdp('Accessibility.getPartialAXTree', { objectId: result.objectId, fetchRelatives: false }))
        .then(({ nodes }) => `${nodes[0].role.value} «${nodes[0].name?.value ?? ''}»`)
    )

  ;[360, 390].forEach((width) => {
    it(`folds the trigger to its icon at ${width}px, keeping its name`, () => {
      cy.viewport(width, 640)
      cy.visit('/bali/topbar/six_actions')

      cy.get(trigger).should(($t) => {
        const { width: w, height: h } = $t[0].getBoundingClientRect()
        expect(w, 'trigger width').to.equal(32)
        expect(h, 'trigger height').to.equal(32)
      })
      cy.get(label).should(($l) => {
        expect($l[0].getBoundingClientRect().width, 'label painted width').to.be.at.most(1)
      })
      triggerName().should('equal', 'button «Search…»')

      cy.get(trigger).click()
      cy.get('[data-command-target="panel"]').should('not.have.class', 'hidden')
    })
  })

  it('keeps the whole well on a desktop', () => {
    cy.viewport(1280, 720)
    cy.visit('/bali/topbar/six_actions')

    cy.get(trigger).should(($t) => {
      expect($t[0].getBoundingClientRect().width, 'trigger width').to.equal(448)
    })
    cy.get(label).should(($l) => {
      expect($l[0].getBoundingClientRect().width, 'label painted width').to.be.greaterThan(40)
    })
  })
})
