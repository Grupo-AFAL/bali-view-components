// BlockEditor comments broke because of the scope of two selectors, not because of an
// interaction, so this drives the cascade instead of the interaction: it mounts the markup
// BlockNote emits inside the real container and reads what the shipped stylesheets paint.
// Same approach document-editor.cy.js takes for the tooltip, and for the same reason — the
// floating composer is only mounted by a real click on a real selection, and nothing tested
// here depends on how the card appeared.
//
// What it reproduces, measured on /lookbook/preview/bali/block_editor/with_comments before
// the fix:
//   - each comment's nested `.bn-container` measured 163px and its `.bn-editor` 0px,
//     because `.bn-with-comments .bn-container > .bn-editor` reached it with
//     `flex: 1; min-width: 0`. One letter per line.
//   - the floating card had no width of its own: 165px with three letters, 966px with a
//     long line. `.bn-floating-composer` / `.bn-floating-thread`, the selectors the sheet
//     used to constrain it, do not exist in the DOM (0 elements).

const LONG_TEXT =
  'este es otro comentario con un texto que se expande conforme voy escribiendo y ' +
  'quiero ver hasta donde me limita asdfkjasldkfj alksdjflajsdlkfjasldkfj alksdjflkajsdf'

const commentCard = text => `
  <div data-floating-ui-portal>
    <div tabindex="-1" data-floating-ui-focusable style="position:absolute;top:0;left:0">
      <div class="bn-thread mantine-Card-root mantine-Paper-root">
        <div class="bn-root bn-container bn-mantine bn-comment-editor">
          <div class="tiptap ProseMirror bn-editor bn-default-styles">
            <p class="bn-inline-content">${text}</p>
          </div>
        </div>
      </div>
    </div>
  </div>`

describe('BlockEditor: comments', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_comments')
    cy.get('.bn-with-comments > .bn-container > .bn-editor').should('contain.text', 'Keyboard shortcuts')

    cy.get('.bn-with-comments > .bn-container').then($container => {
      const doc = $container[0].ownerDocument
      const host = doc.createElement('div')
      host.dataset.test = 'sondas'
      host.innerHTML = commentCard('est') + commentCard(LONG_TEXT)
      $container[0].appendChild(host)
    })
  })

  const cards = () => cy.get('[data-test="sondas"] .bn-thread')

  it('leaves the nested editor at the width of its card, not at zero', () => {
    cy.get('[data-test="sondas"] .bn-comment-editor').each($nested => {
      const styles = window.getComputedStyle($nested[0])
      const editor = $nested[0].querySelector('.bn-editor')

      // The two-column rule belongs to the top-level container and to nobody else.
      expect(styles.display, 'the nested container is not a flex row').to.not.equal('flex')
      expect(editor.getBoundingClientRect().width, 'the editor measures something').to.be.greaterThan(100)
    })
  })

  // There is no third case measuring the paragraph's lines. It was written and it passed
  // just the same with the old sheet: in this probe the floating container is
  // `position: absolute` with no width, that is shrink-to-fit over max-content, and there
  // the text fits on one line even when `.bn-editor` measures zero. One letter per line
  // needs the width Floating UI writes onto the real box. The two cases above DO fail
  // without the fix — verified by reverting index.css and rebuilding — and they are the
  // ones that describe the cause.

  it('the floating bubble measures the same with three letters as with a paragraph', () => {
    cards().should('have.length', 2)
    cards().then($cards => {
      const widths = [...$cards].map(el => Math.round(el.getBoundingClientRect().width))

      expect(widths[0], 'short and long measure the same').to.equal(widths[1])
      expect(widths[0], 'and that width is the declared one').to.equal(320)
    })
  })
})

// The preview is called `with_comments` and carried none (#863). Not cosmetic: it is what
// made #832 invisible — reproducing the thread overflow meant creating a comment by hand
// through the UI, and the preview sweep counted the page as 200.
//
// A comment lives in TWO places and needs both to be a real one: the thread in the store,
// and the `comment` mark over the text it anchors to. Seeding only the store leaves the
// threads in the sidebar but labeled "Original content deleted" — measured.
describe('BlockEditor: the comments preview opens with comments', () => {
  beforeEach(() => {
    cy.viewport(1280, 900)
    cy.visit('/bali/block_editor/with_comments')
    // The sidebar is populated from the store when the editor mounts.
    cy.get('.bn-threads-sidebar .bn-thread', { timeout: 20000 }).should('have.length', 2)
  })

  it('anchors the threads to the text, no orphans', () => {
    // The mark is the half the block JSON cannot carry: it travels in the ProseMirror form
    // of `initial_content`. Without it the sidebar paints threads that point at nothing.
    cy.get('.bn-editor .bn-thread-mark').should('have.length', 2)
    cy.get('.bn-threads-sidebar').should('not.contain.text', 'Original content deleted')
  })

  it('keeps the sidebar width with a long URL that has no break points', () => {
    // The #832 case, now exercised by the preview instead of by hand: a thread whose
    // comment carries a URL with nowhere to break. It measures the container's real
    // overflow, not the classes.
    cy.get('.bn-threads-sidebar').should($sidebar => {
      const el = $sidebar[0]
      expect(el.scrollWidth, 'the sidebar does not overflow horizontally').to.equal(el.clientWidth)
    })
  })
})
