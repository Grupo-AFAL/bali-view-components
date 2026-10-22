// Bali::BpmnEditor's comparison opened by the app: `compare_open:` /
// `compare_index:` on load, `bali-bpmn:compare` to open, switch and close it,
// and `bali-bpmn:compare-change` for whatever opened, switched or closed it —
// with `chrome: :minimal`, which has no «Compare» button.

const FLOWS = '/bali/bpmn_editor/compare_flows'
const EDITOR = '#compare_flows_bpmn'
const COMPARE = '[data-testid="bpmn-compare"]'
const PANES = '[data-testid="bpmn-compare-pane"]'

// Records every compare-change from before the island mounts.
const visit = (url) => cy.visit(url, {
  onBeforeLoad (win) {
    win.compareChanges = []
    win.document.addEventListener('bali-bpmn:compare-change', (event) => win.compareChanges.push(event.detail))
  }
})
const changes = () => cy.window().its('compareChanges')
// The island's bundle loads on the first visit.
const LOADED = { timeout: 10000 }
const send = (detail) => cy.get(EDITOR).then(($editor) => {
  $editor[0].dispatchEvent(new CustomEvent('bali-bpmn:compare', { detail }))
})

describe('BPMN editor: the comparison opened by the app', () => {
  beforeEach(() => cy.viewport(1440, 1000))

  it('opens on load with chrome: :minimal, filling the container, and says so once', () => {
    visit(`${FLOWS}?chrome=minimal&compare_open=true`)
    cy.get(PANES, LOADED).should('have.length', 2).find('.react-flow__node-bpmn').should('exist')
    cy.get('[data-testid="bpmn-compare-button"]').should('not.exist')
    cy.get(`${COMPARE} [data-testid="bpmn-compare-exit"]`).should('be.visible')
    cy.get(`${COMPARE} [data-testid="bpmn-compare-summary"]`).should('be.visible')
    cy.get(`${EDITOR} .bpmn-editor`).then(($editor) => {
      const editor = $editor[0].getBoundingClientRect()
      const compare = $editor[0].querySelector(COMPARE).getBoundingClientRect()
      expect(compare.bottom, 'the comparison reaches the bottom of the container').to.be.closeTo(editor.bottom, 2)
    })
    changes().should('deep.equal', [{ open: true, index: 0, mode: 'side_by_side' }])
  })

  it('emits nothing on load when nothing opens', () => {
    visit(`${FLOWS}?chrome=minimal`)
    cy.get(`${EDITOR} .react-flow__node-bpmn`, LOADED).should('exist')
    cy.wait(300)
    cy.get(COMPARE).should('not.exist')
    changes().should('have.length', 0)
  })

  it('opens, switches the option, switches the view and closes with bali-bpmn:compare', () => {
    visit(`${FLOWS}?chrome=minimal`)
    cy.get(`${EDITOR} .react-flow__node-bpmn`, LOADED).should('exist')
    send({ index: 1 })
    cy.get(`${COMPARE} [data-testid="bpmn-compare-pick"]`).should('have.value', '1')
    cy.get(PANES).should('have.length', 2)
    send({ index: 2 })
    cy.get(`${COMPARE} [data-testid="bpmn-compare-pick"]`).should('have.value', '2')
    send({ mode: 'overlay' })
    cy.get(PANES).should('have.length', 1).and('have.attr', 'data-side', 'overlay')
    send({ mode: null })
    cy.get(COMPARE).should('not.exist')
    cy.get(`${EDITOR} .react-flow__node-bpmn:visible`).should('have.length.at.least', 1)
    changes().should('deep.equal', [
      { open: true, index: 1, mode: 'side_by_side' },
      { open: true, index: 2, mode: 'side_by_side' },
      { open: true, index: 2, mode: 'overlay' },
      { open: false, index: 2, mode: null }
    ])
  })

  it('draws side by side, and says so, when the overlay is asked for two different processes', () => {
    visit(`${FLOWS}?chrome=minimal&compare_open=overlay&compare_index=0`)
    cy.get(PANES, LOADED).should('have.length', 2)
    changes().should('deep.equal', [{ open: true, index: 0, mode: 'side_by_side' }])
  })

  it('reports what the person does in the comparison bar, «×» included, and the app menu follows', () => {
    visit(`${FLOWS}?chrome=minimal&compare_open=true&compare_index=2`)
    cy.get(PANES, LOADED).should('have.length', 2)
    cy.get('[data-testid="bpmn-compare-menu-option"]').should('have.value', '2')
    cy.contains(`${COMPARE} [data-testid="bpmn-compare-modes"] button`, 'Superpuesto').click()
    cy.get('[data-testid="bpmn-compare-menu-view"]').should('have.value', 'overlay')
    cy.get(`${COMPARE} [data-testid="bpmn-compare-pick"]`).select('Alta de empleado')
    cy.get('[data-testid="bpmn-compare-menu-option"]').should('have.value', '1')
    cy.get(`${COMPARE} [data-testid="bpmn-compare-exit"]`).click()
    cy.get(COMPARE).should('not.exist')
    cy.get('[data-testid="bpmn-compare-menu-option"]').should('have.value', '')
    changes().should('deep.equal', [
      { open: true, index: 2, mode: 'side_by_side' },
      { open: true, index: 2, mode: 'overlay' },
      { open: true, index: 1, mode: 'side_by_side' },
      { open: false, index: 1, mode: null }
    ])
  })

  it('keeps the top bar’s «Compare» in step with the event', () => {
    visit(`${FLOWS}?compare_open=true&compare_index=1`)
    cy.get(PANES, LOADED).should('have.length', 2)
    cy.get('[data-testid="bpmn-compare-button"]').should('have.attr', 'aria-pressed', 'true')
    send({ mode: null })
    cy.get('[data-testid="bpmn-compare-button"]').should('have.attr', 'aria-pressed', 'false')
    cy.get(COMPARE).should('not.exist')
  })

  // An app sends its request whenever its own code runs: while the island is
  // still loading, or in the moment between the island's first commit and the
  // effect that starts listening (where a CI run lost a `{ mode: null }`).
  it('applies a request the app sent before the island listened', () => {
    cy.visit(`${FLOWS}?chrome=minimal`, {
      onBeforeLoad (win) {
        win.compareChanges = []
        win.document.addEventListener('bali-bpmn:compare-change', (event) => win.compareChanges.push(event.detail))
        // The React root's own node, prepended to the mount before React renders into it.
        const observer = new win.MutationObserver((mutations) => {
          const root = mutations.flatMap((m) => [...m.addedNodes]).find((node) => node.nodeType === 1 && node.parentElement?.matches('.bali-bpmn-editor-mount') && !node.className)
          if (!root) return
          observer.disconnect()
          win.document.querySelector(EDITOR).dispatchEvent(new CustomEvent('bali-bpmn:compare', { detail: { index: 2, mode: 'overlay' } }))
        })
        observer.observe(win.document, { childList: true, subtree: true })
      }
    })
    cy.get(PANES, LOADED).should('have.length', 1).and('have.attr', 'data-side', 'overlay')
    changes().should('deep.equal', [{ open: true, index: 2, mode: 'overlay' }])
  })

  it('says bali-bpmn:ready once it listens', () => {
    cy.visit(`${FLOWS}?chrome=minimal`, {
      onBeforeLoad (win) {
        win.readies = 0
        win.document.addEventListener('bali-bpmn:ready', (event) => {
          win.readies++
          event.target.dispatchEvent(new CustomEvent('bali-bpmn:compare', { detail: { index: 1 } }))
        })
      }
    })
    cy.get(PANES, LOADED).should('have.length', 2)
    cy.get(`${COMPARE} [data-testid="bpmn-compare-pick"]`).should('have.value', '1')
    cy.window().its('readies').should('eq', 1)
  })

  it('applies a request the app sent as soon as the island drew itself', () => {
    cy.visit(`${FLOWS}?compare_open=true`, {
      onBeforeLoad (win) {
        const observer = new win.MutationObserver(() => {
          const editor = win.document.querySelector(EDITOR)
          if (!editor || !editor.querySelector(COMPARE)) return
          observer.disconnect()
          editor.dispatchEvent(new CustomEvent('bali-bpmn:compare', { detail: { mode: null } }))
        })
        observer.observe(win.document, { childList: true, subtree: true })
      }
    })
    cy.get(`${EDITOR} .react-flow__node-bpmn`, LOADED).should('exist')
    cy.get('[data-testid="bpmn-compare-button"]').should('have.attr', 'aria-pressed', 'false')
    cy.get(COMPARE).should('not.exist')
  })

  it('opens the split view’s flow comparing and fits the flow when the comparison closes', () => {
    visit('/bali/bpmn_editor/split_view?selected=b3&compare_open=true')
    const flow = '[data-testid="bpmn-split-flow"]'
    cy.get(`${flow} ${PANES}`, LOADED).should('have.length', 2).find('.react-flow__node-bpmn').should('exist')
    cy.get('[data-testid="bpmn-compare-menu-option"]').should('have.value', '0')
    cy.get(`${flow} [data-testid="bpmn-compare-exit"]`).click()
    cy.get('[data-testid="bpmn-compare-menu-option"]').should('have.value', '')
    cy.wait(400)
    cy.get(`${flow} .bpmn-editor .react-flow`).then(($canvas) => {
      const canvas = $canvas[0].getBoundingClientRect()
      const nodes = [...$canvas[0].querySelectorAll('.react-flow__node-bpmn')].map((node) => node.getBoundingClientRect())
      expect(nodes.length).to.be.greaterThan(0)
      nodes.forEach((node) => {
        expect(node.left).to.be.gte(canvas.left - 1)
        expect(node.right).to.be.lte(canvas.right + 1)
        expect(node.top).to.be.gte(canvas.top - 1)
        expect(node.bottom).to.be.lte(canvas.bottom + 1)
      })
      expect(Math.max(...nodes.map((n) => n.right)) - Math.min(...nodes.map((n) => n.left)), 'the flow is fitted, not a speck').to.be.greaterThan(canvas.width / 2)
    })
  })
})
