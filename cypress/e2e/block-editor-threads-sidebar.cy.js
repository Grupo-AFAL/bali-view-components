// The threads sidebar was read-only through CSS and nothing else: three
// `display: none !important` rules hid the reply box, the reaction button and the action
// bar in EVERY sidebar, while ninety lines below the same file gave `.bn-thread-composer`
// a margin, a top border and a `min-height` —styling it like a box you expect to see— and
// the docs promised replies and reactions from there. Measured: the composer sat in the
// DOM with a 0×0 rect.
//
// What made it a defect rather than a preference: a thread whose anchor had been deleted
// («Contenido original eliminado») has no popover to open, so with the panel inert there
// was NO way left to answer it (#1111).
//
// Drives the cascade and not the interaction, same as block-editor-comments.cy.js: it
// mounts the markup BlockNote emits inside the real sidebar and reads what the shipped
// stylesheets paint. Mantine only mounts those controls on a real hover or click over a
// thread, and nothing tested here depends on how the card appeared.

const thread = `
  <div class="bn-thread mantine-Card-root mantine-Paper-root">
    <div class="bn-thread-comments">
      <div class="bn-thread-comment">
        <p>Este párrafo está de más</p>
        <div class="bn-comment-actions-wrapper">
          <div class="bn-action-toolbar"><button type="button">Resolver</button></div>
        </div>
        <button type="button" class="bn-comment-add-reaction">+</button>
      </div>
    </div>
    <div class="bn-thread-composer">
      <div class="bn-root bn-container bn-mantine bn-comment-editor">
        <div class="tiptap ProseMirror bn-editor bn-default-styles">
          <p class="bn-inline-content">Responder…</p>
        </div>
      </div>
      <div class="bn-action-toolbar"><button type="button">Guardar</button></div>
    </div>
  </div>`

const CONTROLS = [
  ['.bn-thread-composer', 'the reply box'],
  ['.bn-comment-add-reaction', 'the reaction button'],
  ['.bn-thread-composer .bn-action-toolbar', 'the composer action bar'],
  ['.bn-comment-actions-wrapper', 'the comment actions menu']
]

const mountThread = (root = '.bn-threads-sidebar') =>
  cy.get(root).first().then($sidebar => {
    const host = $sidebar[0].ownerDocument.createElement('div')
    host.dataset.test = 'thread-probe'
    host.innerHTML = thread
    $sidebar[0].appendChild(host)
  })

const probe = selector => cy.get(`[data-test="thread-probe"] ${selector}`)

// The markup above is synthetic on purpose —Mantine only mounts those controls on a real
// hover or click— but that leaves the fix hanging on an assumption nothing checks: that
// BlockNote KEEPS emitting these classes. If a version bump renames `.bn-thread-composer`,
// the probe stays green and the defect comes back whole and silent. This does not test
// behaviour; it fails the day the class stops existing, which is what was missing.
//
// It goes on its own and against the untouched DOM: the synthetic thread hangs off a real
// `.bn-threads-sidebar`, and BlockNote tracks the mouse over the whole document
// —`findClosestEditorElement` walks up from the node under the cursor— so a click with
// that markup mounted blows up inside its own handler.
describe('BlockEditor: the BlockNote classes the mode hangs on', () => {
  const CLASSES = ['.bn-thread-composer', '.bn-comment-editor', '.bn-comment-actions-wrapper']

  CLASSES.forEach(className => {
    it(`BlockNote still emits ${className} in the real DOM`, () => {
      cy.viewport(1280, 900)
      cy.visit('/bali/block_editor/with_comments')
      cy.get('.bn-with-comments > .bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')
      cy.get('.bn-threads-sidebar .bn-thread').first().click()

      cy.get(`.bn-threads-sidebar ${className}`).should('exist')
    })
  })
})

describe('BlockEditor: interactive threads sidebar (default)', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_comments')
    cy.get('.bn-with-comments > .bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')
    mountThread()
  })

  it('does not mark the sidebar as read-only', () => {
    cy.get('.block-editor-component').should('not.have.attr', 'data-comments-sidebar')
  })

  CONTROLS.forEach(([selector, label]) => {
    it(`shows ${label}`, () => {
      probe(selector).then($control => {
        const style = window.getComputedStyle($control[0])
        const rect = $control[0].getBoundingClientRect()

        expect(style.display, `${label} is not hidden`).to.not.equal('none')
        expect(rect.height, `${label} takes up height`).to.be.greaterThan(0)
        expect(rect.width, `${label} takes up width`).to.be.greaterThan(0)
      })
    })
  })
})

describe('BlockEditor: threads sidebar with `sidebar: :read_only`', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_read_only_comments_sidebar')
    cy.get('.bn-with-comments > .bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')
    mountThread()
  })

  it('marks the sidebar as read-only', () => {
    cy.get('.block-editor-component').should('have.attr', 'data-comments-sidebar', 'read-only')
  })

  CONTROLS.forEach(([selector, label]) => {
    it(`hides ${label}`, () => {
      probe(selector).then($control => {
        expect(window.getComputedStyle($control[0]).display, `${label} is hidden`)
          .to.equal('none')
      })
    })
  })

  it('still shows the whole thread, which the mode does not take away', () => {
    probe('.bn-thread-comment').should('be.visible')
  })
})

// The mode used to end at the editor's root: the flag the CSS reads sat on
// `.block-editor-component`, and `comments_container_id:` —a public, documented option—
// portals the sidebar out of there. `sidebar: :read_only` then rendered a fully
// interactive panel, with no error and no warning: one thing was asked for and the
// opposite happened (#1113). The flag now travels with the portal, set by the React
// wrapper on the host container, because Rails does not render what is inside it.
describe('BlockEditor: portaled threads sidebar with `sidebar: :read_only`', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_portaled_read_only_comments_sidebar')
    cy.get('.bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')
    cy.get('#panel-de-hilos .bn-threads-sidebar').should('exist')
    mountThread('#panel-de-hilos .bn-threads-sidebar')
  })

  it('marks the host container, which Rails does not render inside of', () => {
    cy.get('#panel-de-hilos').should('have.attr', 'data-comments-sidebar', 'read-only')
  })

  // The container is neither `.block-editor-component` nor `.document-editor-panel`, which
  // is exactly what the previous selector demanded.
  CONTROLS.forEach(([selector, label]) => {
    it(`hides ${label}`, () => {
      probe(selector).then($control => {
        expect(window.getComputedStyle($control[0]).display, `${label} is hidden`)
          .to.equal('none')
      })
    })
  })
})

// The other half of the mode: the panel stops being where you write, and the anchor keeps
// being it. A thread with no popover to open is what made the inert panel a defect.
// On its own, and without the synthetic thread mounted, for the same reason as the canary.
describe('BlockEditor: the anchor is still where you write', () => {
  it('opens a composer with real height in the popover', () => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_portaled_read_only_comments_sidebar')
    cy.get('.bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')
    cy.get('#panel-de-hilos .bn-thread').first().click()

    cy.get('[data-floating-ui-portal] .bn-thread-composer').should($composer => {
      expect(window.getComputedStyle($composer[0]).display).to.not.equal('none')
      expect($composer[0].getBoundingClientRect().height).to.be.greaterThan(0)
    })
  })
})
