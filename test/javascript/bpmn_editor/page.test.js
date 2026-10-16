import { test } from 'node:test'
import assert from 'node:assert/strict'
import { pageSize, pageFit, exportSize, sheetFor, LETTER, MIN_SCALE, PAGE_MARGIN, PX_PER_INCH, lightThemeOf } from '../../../app/components/bali/bpmn_editor/model/page.js'
import { doc, lanes, node } from './helpers.js'

test('legible means 11 px text at 6 pt or more: the diagram may shrink to about 0.73', () => {
  assert.ok(Math.abs(MIN_SCALE - 6 / 8.25) < 1e-9)
})

test('the sheet in CSS pixels, turned to its orientation', () => {
  assert.deepEqual(pageSize(LETTER), { width: 11 * PX_PER_INCH, height: 8.5 * PX_PER_INCH })
  assert.deepEqual(pageSize({ ...LETTER, orientation: 'portrait' }), { width: 8.5 * PX_PER_INCH, height: 11 * PX_PER_INCH })
  assert.deepEqual(pageSize({ width: 8.27, height: 11.69, orientation: 'portrait' }), { width: 8.27 * PX_PER_INCH, height: 11.69 * PX_PER_INCH })
})

// A pool `length` px long: what fits is decided by width here.
const wide = (length) => doc({ lanes: lanes('A'), pool: { x: 0, y: 0, length }, nodes: [node('t', 'task', 'l1', 200, 90)] })

test('a diagram fits while the scale it needs stays at or above the legible one', () => {
  const printable = 11 * PX_PER_INCH - PAGE_MARGIN * 2
  // The widest export that still prints legibly on landscape letter.
  const limit = Math.floor(printable / MIN_SCALE)
  const lengthFor = (exportWidth) => exportWidth - exportSize(wide(1000)).width + 1000
  assert.equal(pageFit(wide(lengthFor(limit - 10))).fits, true)
  assert.equal(pageFit(wide(lengthFor(limit + 10))).fits, false)
})

test('the scale is how much the export has to shrink to fit the printable area', () => {
  const fit = pageFit(wide(2000))
  const printable = { w: 11 * PX_PER_INCH - PAGE_MARGIN * 2, h: 8.5 * PX_PER_INCH - PAGE_MARGIN * 2 }
  assert.ok(Math.abs(fit.scale - Math.min(printable.w / fit.width, printable.h / fit.height)) < 1e-9)
  assert.equal(fit.minScale, MIN_SCALE)
})

test('an export that fits is drawn on a sheet of the page size, content centred inside the margins', () => {
  const content = { x0: -24, y0: -72, width: 1200, height: 500 }
  const fit = { scale: 0.8, page: pageSize(LETTER) }
  const sheet = sheetFor(fit, content)
  assert.deepEqual([sheet.width, sheet.height], [1056, 816])
  // Content scaled by 0.8 inside the sheet: the viewBox is the sheet / 0.8.
  assert.ok(Math.abs(sheet.w - 1056 / 0.8) < 1e-9 && Math.abs(sheet.h - 816 / 0.8) < 1e-9)
  assert.ok(Math.abs(sheet.x + sheet.w / 2 - (content.x0 + content.width / 2)) < 1e-9, 'centred')
  const scaled = (content.width / sheet.w) * sheet.width
  assert.ok(scaled <= sheet.width - PAGE_MARGIN * 2 + 1e-6, 'inside the margins')
  assert.equal(sheetFor({ scale: 2, page: pageSize(LETTER) }, content).w, 1056, 'a small diagram is not enlarged')
})

test('the outputs are drawn in the light theme of the pair in force', () => {
  assert.equal(lightThemeOf('afal-dark'), 'afal')
  assert.equal(lightThemeOf('costa-norte-dark'), 'costa-norte')
  assert.equal(lightThemeOf('dark'), 'light')
  assert.equal(lightThemeOf('afal'), 'afal')
  assert.equal(lightThemeOf(null), 'light')
})
