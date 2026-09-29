// Replying to a comment flagged the document as «Cambios sin guardar», and in a read-only
// viewer that notice was never cleared again.
//
// The `input` listener hangs off the CONTAINER of the editor area —BlockNote builds its
// ProseMirror client-side, so on connect there is nothing else to hang it on— and
// BlockNote's floating composer lives INSIDE that container. Its `input` bubbled,
// `contentChanged` called `scheduleSave` and `_dirty` stayed true. With
// `auto_save: false` there is no save to clear it: the notice stays forever over a
// document the reader cannot have changed and cannot save (#1111).
//
// The `default` preview is exactly the reported case: `auto_save: false` and comments
// on. `?editable=false` turns it into the viewer.
//
// Mounts the markup BlockNote emits for the composer and fires the real `input` that
// bubbles: the floating composer only opens on a click over a real anchor, and what is
// tested here is where the event came from, not how the card appeared.

const floatingComposer = `
  <div data-floating-ui-portal>
    <div tabindex="-1" data-floating-ui-focusable style="position:absolute;top:0;left:0">
      <div class="bn-thread mantine-Card-root mantine-Paper-root">
        <div class="bn-thread-composer">
          <div class="bn-root bn-container bn-mantine bn-comment-editor">
            <div class="tiptap ProseMirror bn-editor bn-default-styles" contenteditable="true">
              <p class="bn-inline-content" data-test="respuesta">Sí, de acuerdo</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>`

const editorArea = () => cy.get('[data-document-editor-target="editorArea"]:visible')
// No `:visible`: the status `<span>` starts out empty, and an empty inline measures 0×0, so
// Cypress would call it invisible in exactly the state this test needs to read.
const saveStatus = () => cy.get('[data-document-editor-target="saveStatus"]')

// The constructor comes from the AUT's window, not the runner's: the node lives in the
// app's iframe and an event built outside is not of the same realm.
const dispatchInput = node => {
  const win = node.ownerDocument.defaultView
  node.dispatchEvent(new win.Event('input', { bubbles: true, composed: true }))
}

const typeIn = selector => cy.get(selector).then($node => dispatchInput($node[0]))

const mountComposer = () =>
  editorArea().then($area => {
    const host = $area[0].ownerDocument.createElement('div')
    host.dataset.test = 'sonda-composer'
    host.innerHTML = floatingComposer
    $area[0].appendChild(host)
  })

const visitPreview = query => {
  cy.viewport(1280, 900)
  cy.visit(`/bali/document_editor/default${query}`)
  editorArea().find('.bn-editor').should('contain.text', 'Project Overview')
  saveStatus().should('have.text', '')
  mountComposer()
}

describe('DocumentEditor: read-only viewer', () => {
  beforeEach(() => visitPreview('?editable=false'))

  it('does not flag unsaved changes when typing a reply', () => {
    typeIn('[data-test="respuesta"]')

    saveStatus().should('have.text', '')
  })

  // The editor is not editable, so there is no legitimate `input` that could come from the
  // document: the notice cannot appear by any route.
  it('offers no save button that could clear it', () => {
    cy.get('[data-document-editor-target="saveButton"]').should('not.exist')
  })
})

// `contentChanged` filters on two BlockNote classes, and the markup above is
// synthetic on purpose —the floating composer only opens on a click over a real
// anchor—, so the fix hangs off an assumption nothing verifies: that BlockNote KEEPS
// emitting those classes. If a version bump renames `.bn-comment-editor`, the probe
// stays green and the #1111 defect comes back whole, silently, over the same case that
// was measured. This does not test behaviour; it fails the day the class stops existing.
//
// Here goes the half this preview reaches without data: the sidebar mounts with the panel,
// threads or no threads. `.bn-comment-editor` needs a thread, and this preview's threads
// come from the database (`commentable_id=1`), which the seeds do not fill — that is
// canaried in `block-editor-threads-sidebar.cy.js`, over the in-memory threads of its preview.
describe('DocumentEditor: the classes the filter depends on', () => {
  it('BlockNote still emits .bn-threads-sidebar in the real DOM', () => {
    cy.viewport(1280, 900)
    cy.visit('/bali/document_editor/default')
    editorArea().find('.bn-editor').should('contain.text', 'Project Overview')

    cy.get('[data-document-editor-target="commentsToggle"]').click()

    cy.get('[data-document-editor-target="commentsPanel"] .bn-threads-sidebar')
      .should('exist')
  })
})

describe('DocumentEditor: editor with auto_save off', () => {
  beforeEach(() => visitPreview(''))

  it('does not flag unsaved changes when typing a reply', () => {
    typeIn('[data-test="respuesta"]')

    saveStatus().should('have.text', '')
  })

  // The other half of the contract: the fix filters by where the event came from, it does
  // not turn the notice off. An `input` from the document's ProseMirror must still flag it.
  it('does flag it when the input comes from the document', () => {
    editorArea().find('.bn-editor').first().then($editor => dispatchInput($editor[0]))

    saveStatus().should('not.have.text', '')
  })
})
