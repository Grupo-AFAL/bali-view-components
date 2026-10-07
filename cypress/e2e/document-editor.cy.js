import { paintedPixel } from '../support/painted_contrast'
import { hover, unhover } from '../support/tap'

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

// A resolved thread whose author is not in the preview's `users:` list -- what a host gets
// from anyone who left, and the normal case for anyone resolving through `users_url`.
// BlockNote reads the resolver synchronously while rendering the thread and THROWS when the
// id is not cached yet, and every path that fills that cache is async. The throw escapes into
// React's render, so what used to break was not the sidebar: it was the whole document.
describe('DocumentEditor with a comment from an unknown user', () => {
  const stranger = 'nobody-9'
  const timestamps = { created_at: '2026-08-02T17:43:55Z', updated_at: '2026-08-02T17:44:10Z' }

  beforeEach(() => {
    cy.intercept('GET', /\/block_editor_comments(\?|$)/, {
      body: [{
        id: 1,
        resolved: true,
        resolved_by: stranger,
        resolved_updated_at: timestamps.updated_at,
        metadata: {},
        ...timestamps,
        comments: [{
          id: 1,
          user_id: stranger,
          metadata: {},
          deleted_at: null,
          reactions: [],
          ...timestamps,
          body: [{
            id: 'stub-comment-1',
            type: 'paragraph',
            props: {},
            content: [{ type: 'text', text: 'Looks good to me', styles: {} }],
            children: []
          }]
        }]
      }]
    }).as('threads')

    cy.visit('/bali/document_editor/default')
    cy.wait('@threads')
  })

  it('still renders the document', () => {
    cy.get('[data-document-editor-target="editorArea"]:visible .bn-editor')
      .should('contain.text', 'Project Overview')
      .and('contain.text', 'Key Objectives')
  })

  it('names the unknown user with the translated placeholder', () => {
    cy.get('[data-action*="document-editor#toggleComments"]:visible').first().click()
    cy.get('[data-document-editor-target="commentsList"]:visible')
      .should('contain.text', 'Looks good to me')
      .and('contain.text', `User ${stranger}`)
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

// The preview saves to its own `document_url`, "/lookbook", with `auto_save: false`: the
// Save button is the only thing that sends the PATCH, so each test decides when it goes out.
describe('DocumentEditor save status', () => {
  const editor = () => cy.get('[data-document-editor-target="editorArea"]:visible .bn-editor')
  const saveStatus = () => cy.get('[data-document-editor-target="saveStatus"]')
  const saveButton = () => cy.get('[data-document-editor-target="saveButton"]')
  const edit = text => editor().find('.bn-inline-content').last().click().type(text)

  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/document_editor/default')
    editor().should('contain.text', 'Key Objectives')
    edit(' edited')
    saveStatus().should('have.text', 'Unsaved changes')
  })

  it('says the save failed when the server refuses it', () => {
    cy.intercept('PATCH', /\/lookbook$/, { statusCode: 500, body: {} }).as('save')

    saveButton().click()
    cy.wait('@save')

    saveStatus().should('have.text', 'Save failed').and('have.class', 'text-soft-error')
    saveButton().should('be.enabled')
    // Past the 500ms after the last keystroke in which the BlockEditor writes its hidden
    // input: that write's `input` must not come back and cover the failure.
    cy.wait(600)
    saveStatus().should('have.text', 'Save failed')
  })

  // Saved within that same window, with the write still pending when the request leaves.
  it('says the save went through when it leaves before the content sync', () => {
    cy.intercept('PATCH', /\/lookbook$/, { statusCode: 200, body: {}, delay: 1000 }).as('save')

    saveButton().click()
    cy.wait('@save')

    saveStatus().should('contain.text', 'Saved at')
    saveButton().should('be.disabled')
  })

  // The preview has comments on, which pins `format: :prosemirror`. The save used to serialize
  // on its own and sent BlockNote's block Array until the document held a comment mark.
  it('sends the content in the format the editor is pinned to', () => {
    cy.intercept('PATCH', /\/lookbook$/, { statusCode: 200, body: {} }).as('save')

    saveButton().click()

    cy.wait('@save').its('request.body.document.content').then((content) => {
      expect(JSON.parse(content)).to.have.property('type', 'doc')
    })
  })

  // The delay outlasts the BlockEditor's 500ms content sync, whose `input` would otherwise
  // land after the response and flag the edit again by itself.
  it('keeps an edit made while the save was in flight unsaved', () => {
    cy.intercept('PATCH', /\/lookbook$/, { statusCode: 200, body: {}, delay: 3000 }).as('save')

    saveButton().click()
    saveStatus().should('have.text', 'Saving...')
    edit(' again')
    cy.wait('@save')

    saveStatus().should('have.text', 'Unsaved changes')
    saveButton().should('be.enabled')
  })
})

// A read-only viewer renders neither the title input nor the content input, and Ctrl/Cmd+S
// reaches every DocumentEditor on the page: its save has nothing to send.
describe('DocumentEditor save with nothing to send', () => {
  it('leaves the status at rest', () => {
    cy.visit('/bali/document_editor/default?editable=false')
    cy.get('[data-document-editor-target="editorArea"]:visible .bn-editor')
      .should('contain.text', 'Project Overview')

    cy.get('body').type('{ctrl}s')

    cy.get('[data-document-editor-target="saveStatus"]').should('have.text', '')
  })
})

// The "…" menu of a comment in the side panel hangs outside every `.bn-root`, where BlockNote's
// --bn-border-radius-medium is undefined: its corners were 0 against the 8px of every other menu
// on the preview's light theme.
describe('DocumentEditor comment menu', () => {
  const timestamps = { created_at: '2026-08-02T17:43:55Z', updated_at: '2026-08-02T17:44:10Z' }

  beforeEach(() => {
    cy.intercept('GET', /\/block_editor_comments(\?|$)/, {
      body: [{
        id: 1,
        resolved: false,
        metadata: {},
        ...timestamps,
        comments: [{
          id: 1,
          user_id: 'user-2',
          metadata: {},
          deleted_at: null,
          reactions: [],
          ...timestamps,
          body: [{
            id: 'stub-comment-1',
            type: 'paragraph',
            props: {},
            content: [{ type: 'text', text: 'Looks good to me', styles: {} }],
            children: []
          }]
        }]
      }]
    }).as('threads')

    cy.viewport(1280, 900)
    cy.visit('/bali/document_editor/default')
    cy.wait('@threads')
  })

  afterEach(() => { unhover() })

  it('rounds its corners like every other menu', () => {
    cy.get('[data-document-editor-target="commentsToggle"]').click()
    cy.get('.document-editor-panel .bn-thread-comment').first().then(hover)
    cy.get('.document-editor-panel .bn-action-toolbar button').last().click()

    cy.get('.document-editor-panel .mantine-Menu-dropdown')
      .should('contain.text', 'Delete comment')
      .and('have.css', 'border-top-left-radius', '8px')
  })
})

describe('DocumentEditor on a phone', () => {
  const editor = () => cy.get('[data-document-editor-target="editorArea"]:visible .bn-editor')
  const edit = text => editor().find('.bn-inline-content').last().click().type(text)
  const rect = $el => $el[0].getBoundingClientRect()

  // Side by side at 390px, the open table of contents left the document a 70px column and broke
  // its title letter by letter.
  it('stacks the open table of contents above a full-width editor', () => {
    cy.viewport(390, 844)
    cy.visit('/bali/document_editor/default')
    cy.get('[data-document-editor-target="tocPanel"]').should('be.visible')

    cy.get('[data-document-editor-target="editorArea"]').should(($area) => {
      expect($area[0].getBoundingClientRect().width, 'editor area width').to.equal(390)
    })
  })

  // Beside the editor, a panel's w-80 left it 70px at 390px. Over it, the panel has to paint a
  // ground of its own, or the document shows through, and cover BlockNote's floating UI: the
  // block handle still follows the pointer through the panel, and its z-index 20 drew it on top.
  ;['comments', 'history'].forEach((panel) => {
    it(`lays the ${panel} panel over the whole editor`, () => {
      cy.viewport(390, 844)
      cy.visit('/bali/document_editor/default')
      editor().should('contain.text', 'Key Objectives')
      cy.get(`[data-document-editor-target="${panel}Toggle"]`).click()

      cy.get(`[data-document-editor-target="${panel}Panel"]`).should(($panel) => {
        expect([rect($panel).left, rect($panel).width], 'panel left and width').to.deep.equal([0, 390])

        const background = getComputedStyle($panel[0]).backgroundColor
        expect(() => paintedPixel($panel[0].ownerDocument, background), 'panel background is opaque')
          .not.to.throw()
      })

      editor().find('[data-content-type="paragraph"]').first().then(($block) => {
        const { top, height } = rect($block)
        cy.document().trigger('mousemove', { clientX: 20, clientY: top + height / 2 })
      })
      cy.get('.bn-side-menu').should(($handle) => {
        const { left, top, width, height } = rect($handle)
        const hit = $handle[0].ownerDocument.elementFromPoint(left + width / 2, top + height / 2)
        expect(hit.closest('[data-document-editor-target$="Panel"]'), 'what the handle point shows')
          .to.equal($handle[0].ownerDocument.querySelector(`[data-document-editor-target="${panel}Panel"]`))
      })
    })
  })

  // With "Unsaved changes" the bar ran off the screen: at 390px the close button ended at x=407
  // and the title had 26px.
  ;[320, 390].forEach((width) => {
    it(`keeps the close button and the title on screen at ${width}px`, () => {
      cy.viewport(width, 844)
      cy.visit('/bali/document_editor/default')
      editor().should('contain.text', 'Key Objectives')
      edit(' edited')
      cy.get('[data-document-editor-target="saveStatus"]').should('have.text', 'Unsaved changes')

      cy.get('[data-action="document-editor#close"]').should(($close) => {
        expect(rect($close).right, 'close button right edge').to.be.at.most(width)
      })
      cy.get('[data-document-editor-target="titleInput"]').should(($title) => {
        expect(rect($title).width, 'title width').to.be.at.least(80)
      })
    })
  })

  // Below `sm` the status text leaves the bar: the dot on Save is what says something is
  // unsaved, and only a failure is still spelled out — the one text that can crowd the close
  // button, so it is measured at 320px in the longest locale that ships, `es`.
  it('marks unsaved changes with a dot and spells out a failed save', () => {
    const failed = 'Error al guardar'

    cy.viewport(320, 844)
    cy.visit('/bali/document_editor/default')
    editor().should('contain.text', 'Key Objectives')
    cy.get('[data-controller="document-editor"]').invoke('attr', 'data-document-editor-status-failed-value', failed)
    cy.get('.document-editor-unsaved-dot').should('not.be.visible')

    edit(' edited')
    cy.get('.document-editor-unsaved-dot').should('be.visible')

    cy.intercept('PATCH', /\/lookbook$/, { statusCode: 500, body: {} }).as('save')
    cy.get('[data-document-editor-target="saveButton"]').click()
    cy.wait('@save')

    cy.get('[data-document-editor-target="saveStatus"]').should(($status) => {
      expect($status.text()).to.equal(failed)
      expect(rect($status).width, 'status width').to.be.above(1)
    })
    cy.get('[data-action="document-editor#close"]').should(($close) => {
      expect(rect($close).right, 'close button right edge').to.be.at.most(320)
    })
  })
})
