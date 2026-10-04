// The Word export colours text with the palette it is handed, not with the stylesheet, and is
// read on white paper: with BlockNote's own colours yellow text left at 2.11:1. It has to carry
// the same colour the light themes paint, which is what this compares.

// A .docx is a zip; the runs and their colours are in word/document.xml, deflated.
const documentXml = async (blob) => {
  const bytes = new Uint8Array(await blob.arrayBuffer())
  const view = new DataView(bytes.buffer)
  let at = 0
  while (view.getUint32(at, true) === 0x04034b50) {
    const method = view.getUint16(at + 8, true)
    const size = view.getUint32(at + 18, true)
    const nameLength = view.getUint16(at + 26, true)
    const start = at + 30 + nameLength + view.getUint16(at + 28, true)
    const name = new TextDecoder().decode(bytes.subarray(at + 30, at + 30 + nameLength))
    const data = bytes.subarray(start, start + size)
    if (name === 'word/document.xml') {
      if (method === 0) return new TextDecoder().decode(data)
      return new Response(new Blob([data]).stream().pipeThrough(new DecompressionStream('deflate-raw'))).text()
    }
    at = start + size
  }
  throw new Error('word/document.xml not found')
}

const hex = rgb => rgb.match(/\d+/g).slice(0, 3).map(v => Number(v).toString(16).padStart(2, '0')).join('')

describe('BlockEditor Word export', () => {
  it('colours yellow text the way the light theme paints it', () => {
    cy.visit('/bali/document_editor/default')

    const controller = $el => $el[0].ownerDocument.defaultView.Stimulus
      .getControllerForElementAndIdentifier($el[0], 'block-editor')
    cy.get('[data-controller~="block-editor"]').first().should(($el) => {
      expect(controller($el).blockNoteEditor, 'BlockNote editor').to.be.an('object')
    }).then(($el) => {
      const blockEditor = controller($el)
      const editor = blockEditor.blockNoteEditor
      editor.replaceBlocks(editor.document, [{
        type: 'paragraph',
        content: [{ type: 'text', text: 'Yellow text', styles: { textColor: 'yellow' } }]
      }])
      blockEditor._downloadBlob = (blob) => { blockEditor.exported = blob }
      blockEditor.exportDocx()
    })

    cy.get('.bn-editor [data-style-type="textColor"][data-value="yellow"]').then(($text) => {
      const painted = hex($text[0].ownerDocument.defaultView.getComputedStyle($text[0]).color)

      cy.get('[data-controller~="block-editor"]').first()
        .should(($el) => { expect(controller($el).exported, 'exported .docx').to.be.a('blob') })
        .then($el => documentXml(controller($el).exported))
        .should('match', new RegExp(`<w:color w:val="${painted}"/>`, 'i'))
    })
  })
})
