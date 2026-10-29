// Bali::BpmnEditor's drawing asked for by the app: `bali-bpmn:export`
// { request_id, format, frame, font_family } answered by `bali-bpmn:exported`
// or `bali-bpmn:export-failed` with the same request_id — never a download.

const PAGE = '/bali/bpmn_editor/host_export'
const FLOW = '#export_flow_bpmn'
const COMPARED = '#export_compare_bpmn'
const LOADED = { timeout: 10000 }

// Every answer, from before the island mounts.
const visit = (onConnect) => cy.visit(PAGE, {
  onBeforeLoad (win) {
    win.answers = []
    win.events = []
    for (const name of ['bali-bpmn:exported', 'bali-bpmn:export-failed', 'bali-bpmn:ready']) {
      win.document.addEventListener(name, (event) => {
        win.events.push(`${event.target.id} ${name}`)
        if (name !== 'bali-bpmn:ready') win.answers.push({ name, editor: event.target.id, detail: event.detail })
      })
    }
    if (onConnect) onConnect(win)
  }
})
const ask = (editor, detail) => cy.get(editor).then(($editor) => {
  $editor[0].dispatchEvent(new CustomEvent('bali-bpmn:export', { detail }))
})
const answer = (requestId) => cy.window().its('answers').should((answers) => {
  expect(answers.map((a) => a.detail.request_id)).to.include(requestId)
}).then((answers) => answers.find((a) => a.detail.request_id === requestId))
const parse = (svg) => new window.DOMParser().parseFromString(svg, 'image/svg+xml').documentElement
const ready = () => cy.get(`${FLOW} .react-flow__node-bpmn`, LOADED).should('exist')

describe('BPMN editor: the drawing exported for the app', () => {
  beforeEach(() => cy.viewport(1300, 1000))

  it('answers a request sent before the island listens, with its request_id, once ready', () => {
    // The controller's connect adds the turbo-cache-control meta; the island's bundle is still loading.
    visit((win) => {
      const observer = new win.MutationObserver(() => {
        const editor = win.document.querySelector(FLOW)
        if (!editor || !win.document.querySelector('meta[name="turbo-cache-control"]')) return
        observer.disconnect()
        win.events.push('sent')
        editor.dispatchEvent(new CustomEvent('bali-bpmn:export', { detail: { request_id: 'early', frame: false } }))
      })
      observer.observe(win.document, { childList: true, subtree: true })
    })
    answer('early').then(({ name, editor, detail }) => {
      expect(name).to.eq('bali-bpmn:exported')
      expect(editor).to.eq('export_flow_bpmn')
      expect(detail.format).to.eq('svg')
      expect(detail.svg).to.match(/^<\?xml/)
    })
    cy.window().its('events').then((events) => {
      const mine = events.filter((e) => e === 'sent' || e.startsWith('export_flow_bpmn'))
      expect(mine).to.deep.eq(['sent', 'export_flow_bpmn bali-bpmn:ready', 'export_flow_bpmn bali-bpmn:exported'])
    })
  })

  it('frame: false is the drawing alone at its own size, in what prawn-svg reads', () => {
    visit()
    ready()
    ask(FLOW, { request_id: 1, frame: false })
    answer(1).then(({ detail }) => {
      const svg = parse(detail.svg)
      expect(detail.frame).to.eq(false)
      expect(svg.getAttribute('data-sheet')).to.eq(null)
      expect([Number(svg.getAttribute('width')), Number(svg.getAttribute('height'))]).to.deep.eq([detail.width, detail.height])
      expect(svg.getAttribute('viewBox').split(' ').slice(2).map(Number)).to.deep.eq([detail.width, detail.height])
      expect(detail.svg).not.to.include('Aprobación de facturas')
      expect(detail.svg).not.to.include('Borrador')
      // The app's colour and fading, as on the canvas.
      expect(svg.querySelector('[data-appearance="#E9A23B"]')).not.to.eq(null)
      expect(svg.querySelector('[opacity="0.45"]')).not.to.eq(null)
      expect(svg.querySelector('[data-badge-tab]')).not.to.eq(null)
      // prawn-svg: no dominant-baseline, no <tspan> anchored as one run, no
      // orient it does not read, no colour beyond hex and rgb().
      expect(detail.svg).not.to.match(/dominant-baseline|<tspan|foreignObject|auto-start-reverse/)
      const colours = [...detail.svg.matchAll(/(?:fill|stroke)(?:="|:\s*)([^";]+)/g)].map((m) => m[1].trim())
      expect(colours.filter((c) => c !== 'none' && !/^#[0-9a-f]{6}$/i.test(c) && !/^rgb\(\d+, \d+, \d+\)$/.test(c))).to.deep.eq([])
    })
  })

  it('frame: true keeps the title and the watermark; the font family is the app\'s to name', () => {
    visit()
    ready()
    ask(FLOW, { request_id: 'framed', font_family: 'Corporate Sans, sans-serif' })
    answer('framed').then(({ detail }) => {
      const svg = parse(detail.svg)
      expect(detail.frame).to.eq(true)
      expect(detail.svg).to.include('Aprobación de facturas').and.include('Borrador')
      expect(svg.getAttribute('font-family')).to.eq('Corporate Sans, sans-serif')
    })
  })

  it('follows the badges as shown', () => {
    visit()
    ready()
    cy.get(FLOW).then(($editor) => $editor[0].dispatchEvent(new CustomEvent('bali-bpmn:badges', { detail: { visible: false } })))
    ask(FLOW, { request_id: 'no-badges', frame: false })
    answer('no-badges').then(({ detail }) => {
      expect(parse(detail.svg).querySelector('[data-badge-tab]')).to.eq(null)
      expect(parse(detail.svg).querySelector('[data-appearance="#E9A23B"]')).not.to.eq(null)
    })
  })

  it('a PNG at 2x as a data URL', () => {
    visit()
    ready()
    ask(FLOW, { request_id: 'png', format: 'png', frame: false })
    answer('png').then(({ detail }) => {
      expect(detail.png).to.match(/^data:image\/png;base64,/)
      expect(detail.scale).to.eq(2)
      expect(detail.width).to.be.greaterThan(0)
      return new Cypress.Promise((resolve) => {
        const image = new window.Image()
        image.onload = () => resolve([image.naturalWidth, image.naturalHeight, detail.width * 2, detail.height * 2])
        image.src = detail.png
      })
    }).then(([width, height, expectedWidth, expectedHeight]) => {
      expect([width, height]).to.deep.eq([expectedWidth, expectedHeight])
    })
  })

  it('says what it cannot do with export-failed and the request_id', () => {
    visit()
    ready()
    ask(FLOW, { request_id: 'pdf', format: 'pdf' })
    answer('pdf').then(({ name, detail }) => {
      expect(name).to.eq('bali-bpmn:export-failed')
      expect(detail.message).to.include('pdf')
    })
  })

  it('with the comparison open: both sides with their marks, and the changes as data', () => {
    visit()
    cy.get(`${COMPARED} [data-testid="bpmn-compare-pane"] .react-flow__node-bpmn`, LOADED).should('exist')
    ask(COMPARED, { request_id: 'cmp', frame: false })
    answer('cmp').then(({ detail }) => {
      const { comparison } = detail
      expect(comparison.mode).to.eq('side_by_side')
      expect(comparison.label).to.eq('Versión 1')
      const before = parse(comparison.before.svg)
      const after = parse(comparison.after.svg)
      expect(before.querySelectorAll('[data-diff-mark="removed"]').length).to.be.greaterThan(0)
      expect(before.querySelectorAll('[data-diff-mark="added"]').length).to.eq(0)
      expect(after.querySelectorAll('[data-diff-mark="added"]').length).to.be.greaterThan(0)
      expect(comparison.after.width).to.be.greaterThan(0)
      // Not marked: the current document as it is.
      expect(parse(detail.svg).querySelector('[data-diff-mark]')).to.eq(null)
      expect(comparison.changes.map((c) => [c.state, c.kind, c.name, c.lane])).to.deep.include(['added', 'node', 'Validar datos fiscales', 'Compras'])
      cy.get(`${COMPARED} [data-testid="bpmn-compare-summary"] summary`).should('have.text', comparison.summary.text)
      cy.get(`${COMPARED} [data-testid="bpmn-compare-changes"] li`).should('have.length', comparison.changes.length)
    })
  })

  it('the preview shows what the app got back', () => {
    visit()
    ready()
    cy.get('[data-testid="bpmn-export-svg"]').click()
    cy.get('[data-testid="bpmn-export-result"] img').should('have.attr', 'src').and('match', /^data:image\/svg\+xml/)
    cy.get(`${COMPARED} [data-testid="bpmn-compare-pane"] .react-flow__node-bpmn`, LOADED).should('exist')
    cy.get('[data-testid="bpmn-export-comparison"]').click()
    cy.get('[data-testid="bpmn-export-comparison-result"] img').should('have.length', 3)
    cy.get('[data-testid="bpmn-export-summary"]').should('contain', '"changes"')
  })
})
