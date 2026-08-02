// Uses the Lookbook preview (no DB dependency): the default preview renders
// the editor overlay with versions_url "/lookbook", so both the versions
// index and each version payload are stubbed with cy.intercept.
const stubVersions = [1, 2].map(id => ({
  id,
  version_number: id,
  summary: `Change ${id}`,
  author_name: 'Demo User',
  created_at: '2026-07-01T12:00:00Z'
}))

describe('DocumentEditor version preview', () => {
  beforeEach(() => {
    cy.intercept('GET', /\/lookbook$/, {
      headers: { 'Content-Type': 'application/json' },
      body: stubVersions
    }).as('versionsIndex')

    cy.intercept('GET', /\/lookbook\/\d+$/, req => {
      const id = req.url.split('/').pop()
      req.reply({
        id: Number(id),
        version_number: Number(id),
        content: [
          {
            id: `stub-${id}`,
            type: 'paragraph',
            props: {},
            content: [{ type: 'text', text: `STUB VERSION ${id}`, styles: {} }],
            children: []
          }
        ]
      })
    }).as('showVersion')

    cy.visit('/bali/document_editor/default')
    editor().should('contain.text', 'Project Overview')
    cy.get('[data-action*="document-editor#toggleHistory"]:visible').first().click()
    cy.wait('@versionsIndex')
    cy.get('[data-action*="previewVersion"]:visible').should('have.length', 2)
  })

  const editor = () => cy.get('[data-document-editor-target="editorArea"]:visible .bn-editor')

  const previewVersion = id => {
    cy.get(`[data-action*="previewVersion"][data-version-id="${id}"]:visible`).click()
    cy.wait('@showVersion')
    editor().should('contain.text', `STUB VERSION ${id}`)
  }

  const backToCurrent = () => cy.get('[data-action*="exitPreview"]:visible').click()

  const assertBackOnCurrent = () => {
    editor().should('not.contain.text', 'STUB VERSION')
    editor().should('contain.text', 'Project Overview')
    editor().should('have.attr', 'contenteditable', 'true')
  }

  it('returns to the current version after a single preview', () => {
    previewVersion(1)
    backToCurrent()
    assertBackOnCurrent()
  })

  it('returns to the current version after previewing several versions in a row', () => {
    previewVersion(1)
    previewVersion(2)
    backToCurrent()
    assertBackOnCurrent()
  })
})

// BlockNote draws the tooltip card on `.bn-tooltip` and deliberately zeroes the Mantine box
// around it. Re-skinning that card is fine; giving the wrapper one of its own is not — it
// stacks a second border and shadow on every tooltip, and leaves an empty pill wherever a
// rule hides the inner label (the Save button of the comment composer does exactly that).
//
// Mantine mounts a tooltip only while the pointer is genuinely over its trigger, and no
// synthetic hover or focus opens it, so this drives the cascade instead of the interaction:
// it mounts the markup BlockNote emits inside the real editor container and reads back what
// the shipped stylesheets paint.
describe('DocumentEditor tooltip cascade', () => {
  const paints = style =>
    parseFloat(style.borderTopWidth) > 0 ||
    style.boxShadow !== 'none' ||
    !['rgba(0, 0, 0, 0)', 'transparent'].includes(style.backgroundColor)

  beforeEach(() => {
    cy.visit('/bali/document_editor/default')
    cy.get('[data-document-editor-target="editorArea"]:visible .bn-editor')
      .should('contain.text', 'Project Overview')

    cy.get('.bn-container.bn-mantine').first().then($container => {
      const doc = $container[0].ownerDocument
      const tooltip = doc.createElement('div')
      tooltip.className = 'mantine-Tooltip-tooltip'
      tooltip.dataset.test = 'tooltip-cascade'
      tooltip.innerHTML =
        '<div class="bn-tooltip mantine-Stack-root"><p>Bold</p><p>⌘+B</p></div>'
      $container[0].appendChild(tooltip)
    })
  })

  const wrapper = () => cy.get('[data-test="tooltip-cascade"]')
  const label = () => cy.get('[data-test="tooltip-cascade"] .bn-tooltip')

  it('paints the card on the label and nothing on the Mantine box', () => {
    label().then($label => {
      expect(paints(window.getComputedStyle($label[0])), 'label draws the card').to.equal(true)
    })

    wrapper().then($wrapper => {
      const style = window.getComputedStyle($wrapper[0])

      expect(paints(style), 'Mantine box draws nothing').to.equal(false)
      expect(style.padding, 'Mantine box adds no padding').to.equal('0px')
    })
  })

  it('leaves nothing behind when the label is hidden', () => {
    // What the Save button's rule does: hide the label. With the card on the wrapper this
    // used to leave a bordered 18x10 pill floating above the button.
    label().invoke('css', 'display', 'none')

    wrapper().then($wrapper => {
      expect($wrapper[0].getBoundingClientRect().height, 'no empty pill').to.equal(0)
    })
  })
})
