// #1091 — the editor persists in one of two JSON shapes, and with `format: :json` which one
// you got was not the host's decision: BlockNote strips the comment marks from
// `editor.document`, so the editor switches to the ProseMirror shape on its own to keep them.
// The first user to leave a comment rewrote the column in the other schema, and with
// auto-save that happened without anyone asking for it.
//
// The preview's three editors load THE SAME document —one that already carries marks— and
// differ only in `format:`. The assertion is on the hidden input's VALUE, which is what the
// host ends up saving; the `data-content-format` next to it is what saves the host from
// guessing it from the structure.
//
// The DOCUMENT's editor and not just any `.bn-editor`: with comments on, every sidebar
// comment mounts its own, so the loose selector returns four. The top-level one is the direct
// child of the `.bn-container` of `.bn-with-comments`, the same scope
// block-editor-comments.cy.js uses.
const editorFor = section =>
  cy.get(`[data-test="${section}"] .bn-with-comments > .bn-container > .bn-editor`)
const inputFor = section =>
  cy.get(`[data-test="${section}"] input[data-block-editor-target="output"]`)

const typeIn = section => {
  editorFor(section).should('exist')
  editorFor(section).find('.bn-block-content').should('have.length.at.least', 1)
  editorFor(section).type('{moveToEnd} done', { delay: 0 })
}

// It waits for the TYPED TEXT and not for the input to stop being empty: the server renders
// it already holding the original content, so "not empty" is true before the editor has
// written a single time — and in this preview that original content is ProseMirror, which
// would make two of the three cases pass without having measured anything. The write is
// debounced 500ms.
const valueFor = section =>
  inputFor(section).should($input => expect($input.val()).to.include('done'))
    .then($input => JSON.parse($input.val()))

describe('BlockEditor: shape of the persisted content', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_pinned_format')
  })

  it('with :json and comment marks it writes the ProseMirror shape, as always', () => {
    typeIn('adaptive')

    valueFor('adaptive').should(content => {
      expect(content.type, 'the root').to.equal('doc')
    })
    inputFor('adaptive').should('have.attr', 'data-content-format', 'prosemirror')
  })

  it('with :blocks it stays on the Array of blocks even when there are marks', () => {
    typeIn('pinned-blocks')

    valueFor('pinned-blocks').should(content => {
      expect(Array.isArray(content), 'the root is an Array of blocks').to.equal(true)
      expect(content.length).to.be.greaterThan(0)
      // The shape the host reads on the Rails side: props, not attrs.
      expect(content[0]).to.have.property('props')
    })
    inputFor('pinned-blocks').should('have.attr', 'data-content-format', 'blocks')
  })

  it('with :prosemirror it writes the ProseMirror shape even when it was not needed', () => {
    typeIn('pinned-prosemirror')

    valueFor('pinned-prosemirror').should(content => {
      expect(content.type).to.equal('doc')
    })
    inputFor('pinned-prosemirror').should('have.attr', 'data-content-format', 'prosemirror')
  })

  // Losing a thread's anchor is a trade-off the host may want; losing it silently is what
  // this `format:` exists to prevent.
  it('warns on the console when :blocks drops a comment mark', () => {
    cy.window().then(win => cy.spy(win.console, 'warn').as('warn'))

    typeIn('pinned-blocks')
    valueFor('pinned-blocks')

    cy.get('@warn').should('have.been.calledWithMatch', /does not persist comment marks/)
  })
})
