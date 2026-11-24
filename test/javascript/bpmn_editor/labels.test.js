import { test } from 'node:test'
import assert from 'node:assert/strict'
import { boxesOverlap } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { insideLabelBox, badgeTabBox, markerZone, taskMarkerAt, nodeLabelBox, labelSide, badgeBox, wrap, fitBadge } from '../../../app/components/bali/bpmn_editor/model/labels.js'
import { node } from './helpers.js'

const NAME = 'Manage insurance and claims for company fixed assets'
const LINE = 14
// The export's average glyph of its 11 px name (ExportDiagram.jsx).
const EXPORT_CHAR = 6.8

const plusBox = (n) => {
  const zone = markerZone(64)
  return { x: n.x + n.width / 2 - zone.size / 2, y: n.y + 64 - zone.height, w: zone.size, h: zone.size }
}
// flow.css .bpmn-node-link (`top: 3px; right: 6px`, 12 px): the ↗ measured
// 10 × 18 in Chromium, 15 to 5 px from the right edge.
const linkBox = (n) => ({ x: n.x + n.width - 16, y: n.y + 3, w: 11, h: 18 })
const taskMarkerBox = (n, badge) => {
  const m = taskMarkerAt(64, badge)
  return { x: n.x + m.x, y: n.y + m.y, w: m.size, h: m.size }
}

// Where the canvas may draw the name: its first line between the corners,
// the rest across the whole box.
const regions = (area) => [
  { x: area.x + area.corner, y: area.y, w: area.w - area.corner * 2, h: LINE },
  { x: area.x, y: area.y + LINE, w: area.w, h: area.h - LINE }
]

// What the export prints: each wrapped line, 14 px apart, the block centred on the area.
function exportLines (area, text) {
  const lines = wrap(text, Math.floor(area.w / EXPORT_CHAR), area.lines, Math.floor((area.w - area.corner * 2) / EXPORT_CHAR))
  const top = area.y + (area.h - lines.length * LINE) / 2
  return lines.map((line, i) => {
    const w = line.length * EXPORT_CHAR
    return { text: line, x: area.x + (area.w - w) / 2, y: top + i * LINE, w, h: LINE }
  })
}

const sized = (width, n) => ({ ...n, width, x: 200 - width / 2 })

for (const width of [110, 150]) {
  test(`a ${width} px long-named linked sub-process with a badge: name, [+], link and tab never overlap`, () => {
    const sub = sized(width, node('s', 'sub_process', 'l1', 200, 100, { name: NAME, reference: { url: '/processes/1' }, appearance: { badge: 'Completo' } }))
    const area = insideLabelBox(sub, { badge: true, link: true })
    const tab = badgeTabBox(sub, 'Completo', { topRight: true })
    for (const region of regions(area)) {
      assert.equal(boxesOverlap(region, plusBox(sub)), false, 'name over the [+]')
      assert.equal(boxesOverlap(region, linkBox(sub)), false, 'name under the link arrow')
      assert.equal(boxesOverlap(region, tab), false, 'name under the badge tab')
    }
    assert.equal(boxesOverlap(tab, plusBox(sub)), false, 'tab over the [+]')
    assert.equal(boxesOverlap(tab, linkBox(sub)), false, 'tab over the link arrow')
    assert.equal(boxesOverlap(tab, badgeBox(sub)), false, 'tab over the pending marker')
    assert.equal(area.lines, 2)
  })

  test(`a ${width} px task: its marker and the tab keep out of each other and of the name`, () => {
    const task = sized(width, node('t', 'user_task', 'l1', 200, 100, { name: NAME }))
    for (const badge of [true, false]) {
      const marker = taskMarkerBox(task, badge)
      for (const region of regions(insideLabelBox(task, { badge }))) assert.equal(boxesOverlap(region, marker), false, `name over the marker (badge: ${badge})`)
    }
    assert.equal(boxesOverlap(taskMarkerBox(task, true), badgeTabBox(task, 'Completo')), false, 'marker under the tab')
  })

  test(`a ${width} px export: the name keeps out of the same marks and ends in an ellipsis when cut`, () => {
    const sub = sized(width, node('s', 'sub_process', 'l1', 200, 100, { name: NAME, reference: { url: '/processes/1' } }))
    for (const badge of [true, false]) {
      const area = insideLabelBox(sub, { badge, link: true })
      const lines = exportLines(area, NAME)
      assert.ok(lines.length <= area.lines, `${lines.length} lines in room for ${area.lines}`)
      for (const line of lines) {
        assert.ok(line.x >= area.x && line.x + line.w <= area.x + area.w, `«${line.text}» as wide as the area`)
        assert.ok(line.y >= area.y && line.y + line.h <= area.y + area.h, `«${line.text}» inside the area`)
        assert.equal(boxesOverlap(line, plusBox(sub)), false, `«${line.text}» over the [+]`)
        assert.equal(boxesOverlap(line, linkBox(sub)), false, `«${line.text}» under the link arrow`)
        if (badge) assert.equal(boxesOverlap(line, badgeTabBox(sub, 'Completo', { topRight: true })), false, `«${line.text}» under the tab`)
      }
      assert.match(lines[lines.length - 1].text, /…$/)
    }
  })
}

test('the tab sits across the top edge, flush left, no wider than the box and ellipsed', () => {
  const sub = node('s', 'sub_process', 'l1', 200, 100)
  const tab = badgeTabBox(sub, 'Completo')
  assert.deepEqual([tab.x, tab.y, tab.h, tab.radius], [sub.x, sub.y - 8, 16, 6.4])
  const long = badgeTabBox(sub, 'A badge far longer than the box itself')
  assert.equal(long.w, 150)
  assert.match(long.text, /…$/)
  assert.ok(badgeTabBox(sub, 'A badge far longer than the box itself', { topRight: true, note: true }).w <= 150 - 20 - 22)
})

test('a bare 64 px task keeps four lines, three under a badge; the [+] leaves two', () => {
  assert.equal(insideLabelBox(node('t', 'task', 'l1', 200, 100)).lines, 4)
  assert.equal(insideLabelBox(node('t', 'task', 'l1', 200, 100), { badge: true }).lines, 3)
  assert.equal(insideLabelBox(node('s', 'sub_process', 'l1', 200, 100)).lines, 2)
  assert.equal(insideLabelBox(node('s', 'sub_process', 'l1', 200, 100), { badge: true }).lines, 2)
})

test('wrap cuts a word longer than a line, as the canvas does, and narrows the first line', () => {
  assert.deepEqual(wrap('Supercalifragilistic', 8, 3), ['Supercal', 'ifragili', 'stic'])
  assert.deepEqual(wrap('Schedule the transfer', 14, 3, 9), ['Schedule', 'the transfer'])
})

test('a gateway’s name, above-left, clears its badge tab', () => {
  const gateway = node('g', 'exclusive_gateway', 'l1', 200, 100, { name: 'Approved by the committee?', appearance: { badge: 'Completo' } })
  assert.equal(boxesOverlap(nodeLabelBox(gateway), badgeTabBox(gateway, 'Completo')), false)
})

test('an emoji is never cut in half: whole characters, so the image export can encode the text', () => {
  const lines = wrap('Validar 🔴🔴🔴🔴🔴🔴🔴🔴', 9, 3)
  for (const line of lines) assert.doesNotThrow(() => encodeURIComponent(line), line)
  assert.doesNotThrow(() => encodeURIComponent(fitBadge('Pendiente 🔴🔴🔴🔴🔴🔴🔴🔴🔴', 40).text))
})

// Capitals measured in Chromium at the label's 11.5 px: «AND» 25.2 px, «WMS» 29.
test('a name all in capitals gets the width its glyphs take, so «AND» is not cut', () => {
  const widthOf = (name) => nodeLabelBox(node('g', 'parallel_gateway', 'l1', 100, 100, { name })).w
  assert.ok(widthOf('AND') >= 26, `AND got ${widthOf('AND')} px`)
  assert.ok(widthOf('WMS') >= 29, `WMS got ${widthOf('WMS')} px`)
  assert.equal(widthOf('Fin'), 24)
})

// #1694: `label_position`, optional. Where the editor put a name before is
// what a document without the key still gets.
const named = (type, extra = {}) => node('n', type, 'l1', 200, 100, { name: 'Invoice received', ...extra })
const below = (box, n) => box.y >= n.y + (n.height || (n.type.includes('gateway') ? 50 : 36))
const above = (box, n) => box.y + box.h <= n.y

test('without label_position every name sits where it always did', () => {
  for (const type of ['start_event', 'end_event', 'exclusive_gateway', 'data_object']) {
    const legacy = nodeLabelBox(named(type))
    assert.deepEqual(nodeLabelBox(named(type, { label_position: null })), legacy, type)
    assert.deepEqual(nodeLabelBox(named(type, { label_position: 'sideways' })), legacy, `${type}: a value it does not know is none`)
  }
  assert.equal(nodeLabelBox(named('start_event')).align, 'middle')
  assert.equal(nodeLabelBox(named('start_event'), 'vertical').align, 'start')
  assert.equal(nodeLabelBox(named('exclusive_gateway')).align, 'end')
  assert.equal(labelSide(named('start_event')), 'bottom')
  assert.equal(labelSide(named('start_event'), 'vertical'), 'right')
})

test('a name asked above an event goes left of its top port, clear of every port and of the pending badge', () => {
  const event = named('start_event', { label_position: 'top' })
  const box = nodeLabelBox(event)
  assert.ok(above(box, event))
  assert.ok(box.x + box.w < event.x + 18, 'left of the top port')
  assert.equal(boxesOverlap(box, badgeBox(event)), false)
  assert.equal(labelSide(event), null)
  assert.equal(labelSide(event, 'vertical'), null)
  assert.deepEqual(nodeLabelBox(event, 'vertical'), box, 'the same in vertical lanes')
  // Over the app's badge tab, as a gateway's.
  const badged = { ...event, appearance: { badge: 'Done' } }
  assert.equal(boxesOverlap(nodeLabelBox(badged), badgeTabBox(badged, 'Done')), false)
})

test('a name asked below: under an event, and left of a gateway’s bottom port', () => {
  const event = named('start_event', { label_position: 'bottom' })
  assert.deepEqual(nodeLabelBox(event, 'vertical'), nodeLabelBox(named('start_event')), 'an event: where horizontal lanes put it')
  assert.equal(labelSide(event, 'vertical'), 'bottom')
  const gateway = named('exclusive_gateway', { label_position: 'bottom' })
  const box = nodeLabelBox(gateway)
  assert.ok(below(box, gateway))
  assert.ok(box.x + box.w < gateway.x + 25, 'left of the bottom port')
  assert.equal(labelSide(gateway), null)
  assert.deepEqual(nodeLabelBox(named('exclusive_gateway', { label_position: 'top' })), nodeLabelBox(named('exclusive_gateway')), 'above is where a gateway’s already is')
})

test('label_position means nothing on an element that holds its own name', () => {
  assert.equal(nodeLabelBox(named('task', { label_position: 'top' })), null)
  assert.equal(labelSide(named('task', { label_position: 'top' })), null)
})
