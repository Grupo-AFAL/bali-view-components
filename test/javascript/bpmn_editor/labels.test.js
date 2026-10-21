import { test } from 'node:test'
import assert from 'node:assert/strict'
import { boxesOverlap } from '../../../app/components/bali/bpmn_editor/model/geometry.js'
import { insideLabelBox, badgeTabBox, markerZone, taskMarkerAt, nodeLabelBox, badgeBox, wrap } from '../../../app/components/bali/bpmn_editor/model/labels.js'
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
