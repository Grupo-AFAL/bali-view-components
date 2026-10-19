import { test } from 'node:test'
import assert from 'node:assert/strict'
import { appearanceOf, BADGE_MAX } from '../../../app/components/bali/bpmn_editor/model/appearance.js'
import { forSave, normalize } from '../../../app/components/bali/bpmn_editor/model/document.js'
import { doc, lanes, node } from './helpers.js'

test('appearanceOf keeps what can be drawn and drops the rest', () => {
  assert.equal(appearanceOf(node('t', 'task', 'l1', 100, 100)), null)
  assert.deepEqual(appearanceOf({ appearance: { color: '#E9A23B', dimmed: true, badge: ' In progress ' } }), { color: '#E9A23B', dimmed: true, badge: 'In progress' })
  assert.deepEqual(appearanceOf({ appearance: { color: 'orange', dimmed: 'yes', badge: 'x'.repeat(40) } }), { color: null, dimmed: false, badge: 'x'.repeat(BADGE_MAX) })
  assert.equal(appearanceOf({ appearance: { color: 'var(--x)' } }), null)
})

test('the save request never carries appearance: it is the server’s', () => {
  const d = normalize(doc({ lanes: lanes('A'), nodes: [node('t', 'task', 'l1', 100, 90, { appearance: { color: '#16a34a', badge: 'Done' } })] }))
  const body = forSave(d)
  assert.equal('appearance' in body.nodes[0], false)
  assert.equal(body.nodes[0].name, 't', 'the rest of the node travels')
  assert.ok(d.nodes[0].appearance, 'the document on screen keeps it')
})

// The outputs drawing it (ExportDiagram.jsx) is checked in the browser:
// cypress/e2e/bpmn-editor.cy.js, «the exported SVG carries the app's colours».

test('the .bpmn export carries the colour, and only the colour', async () => {
  const { toBpmnXml, COLOR_NAMESPACES } = await import('../../../app/components/bali/bpmn_editor/model/bpmnXml.js')
  const plain = normalize(doc({ lanes: lanes('A'), nodes: [node('t', 'task', 'l1', 100, 90), node('u', 'task', 'l1', 300, 90)] }))
  const badged = { ...plain, nodes: plain.nodes.map((n) => (n.id === 'u' ? { ...n, appearance: { badge: 'Done', dimmed: true } } : n)) }
  assert.equal(toBpmnXml(badged), toBpmnXml(plain), 'badge and dimmed are not interchange')
  const coloured = { ...plain, nodes: plain.nodes.map((n) => (n.id === 't' ? { ...n, appearance: { color: '#2563EB' } } : n)) }
  const xml = toBpmnXml(coloured)
  assert.match(xml, new RegExp(`xmlns:bioc="${COLOR_NAMESPACES.bioc}" xmlns:color="${COLOR_NAMESPACES.color}"`))
  assert.match(xml, /bpmnElement="t" bioc:stroke="#2563eb" bioc:fill="#dce6fc" color:border-color="#2563eb" color:background-color="#dce6fc">/)
  assert.doesNotMatch(xml, /bpmnElement="u"[^>]*bioc/)
})
