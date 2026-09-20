// Two basic editor contracts that break silently, each one on its own.
//
// 1. Enter splits the block. It sounds like it needs no test, and that is exactly why it
//    was broken: it only takes the bundle loading TWO copies of `prosemirror-model` for
//    `Transaction.split` to throw `RangeError: Can not convert <> to a Fragment`, because
//    `Fragment.from` validates with an `instanceof` against its own copy. The editor
//    mounts, paints and lets you type; the only thing it does not do is break the line.
//    No Ruby suite can see that, and the duplicate is introduced by the lockfile, not by
//    the code: it only gets in when someone bumps `@blocknote/*` and yarn adds a new entry
//    instead of re-resolving the old one. See `resolutions` in spec/dummy/package.json.
//
// 2. The heading that opens the document carries no space above it. BlockNote gives 18px
//    to ALL headings; in the first block there is nothing to separate from and the field
//    starts with the text sunk, which reads as a misaligned input.
//
// The editor is React mounted by Stimulus: wait for the content, not the container, or
// you measure the empty div the server sent.
const editor = () => cy.get('.bn-editor.bn-default-styles')
const blocks = () => cy.get('.bn-block-content')

const openPreview = path => {
  cy.visit(path)
  editor().should('exist')
  blocks().should('have.length.at.least', 1)
}

const typeText = text => editor().type(text, { delay: 0 })

describe('BlockEditor: basic editing', () => {
  it('Enter splits the block instead of staying on the same line', () => {
    openPreview('bali/block_editor/default')

    typeText('Primera linea{enter}Segunda linea{enter}Tercera linea')

    blocks().should('have.length', 3)
    blocks().eq(0).should('contain.text', 'Primera linea')
    blocks().eq(1).should('contain.text', 'Segunda linea')
    blocks().eq(2).should('contain.text', 'Tercera linea')

    // And the line below did not stay glued to the one above, which is how the failure
    // looks from the outside when `split` blows up.
    blocks().eq(0).should('not.contain.text', 'Segunda linea')
  })

  // The `RangeError` does not break the render, so without this it goes unnoticed.
  it('throws no prosemirror exceptions when splitting a block', () => {
    cy.visit('bali/block_editor/default', {
      onBeforeLoad (win) {
        cy.spy(win.console, 'error').as('consoleError')
      }
    })
    editor().should('exist')

    typeText('Uno{enter}Dos')

    cy.get('@consoleError').should(spy => {
      const messages = spy.getCalls().map(c => String(c.args[0]))
      const prosemirror = messages.filter(m => /prosemirror|Fragment/i.test(m))
      expect(prosemirror, `console.error: ${prosemirror.join(' | ')}`).to.have.length(0)
    })
  })
})

describe('BlockEditor: the heading that opens the document', () => {
  const headings = () => cy.get('.bn-block-content[data-content-type="heading"]')

  it('carries no padding above, and the rest do', () => {
    openPreview('bali/block_editor/with_initial_content')

    headings().should('have.length.at.least', 2)

    headings().eq(0).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop), 'the first one').to.eq(0)
    })

    headings().eq(1).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop), 'the second one').to.eq(18)
    })
  })

  it('also when the heading is typed by hand in an empty editor', () => {
    openPreview('bali/block_editor/default')

    typeText('# Titulo{enter}Un parrafo.{enter}## Otro heading')

    headings().should('have.length', 2)

    headings().eq(0).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop), 'the opening one').to.eq(0)
    })

    headings().eq(1).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop), 'the one after a paragraph').to.eq(18)
    })
  })

  // The space above the other headings comes from the body size, not from BlockNote's
  // fixed 18px nor from the heading's own `em` (which on an h1 would give 54px).
  it('scales that space with `size:`', () => {
    openPreview('bali/block_editor/with_initial_content?size=xs')

    headings().eq(0).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop)).to.eq(0)
    })

    headings().eq(1).should($h => {
      expect(parseFloat(getComputedStyle($h[0]).paddingTop)).to.eq(13.5)
    })
  })
})
