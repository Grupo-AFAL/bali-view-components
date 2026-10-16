// Whether the diagram fits a printed page at a legible size (AFAL VIS-02 and
// VIS-08: "legible on a letter-size sheet when its complexity allows").
//
// Legible means the canvas' smallest running text (element and connection
// names, 11 px) prints at 6 pt or more. 11 px at 0.75 pt/px is 8.25 pt, so the
// diagram may shrink to 6 / 8.25 ≈ 0.73 of its size and no further.
//
// Measured on what the image/print export draws: the content's bounds plus
// the export margin on every side and the title band on top.
import { contentBounds, layoutLanes } from './geometry.js'

// Mirrors Bali::BpmnEditor::Component::DEFAULT_PAGE (contract_test.rb).
export const LETTER = { width: 8.5, height: 11, orientation: 'landscape' }
export const MIN_TEXT_PT = 6
export const TEXT_PX = 11
export const MIN_SCALE = MIN_TEXT_PT / (TEXT_PX * 0.75)
export const EXPORT_MARGIN = 24
export const TITLE_HEIGHT = 48
// CSS pixels per inch, and the print margin (10 mm) on every side.
export const PX_PER_INCH = 96
export const PAGE_MARGIN = (10 / 25.4) * PX_PER_INCH

// The sheet in CSS pixels, turned to its orientation.
export function pageSize (page = LETTER) {
  const a = Number(page.width) * PX_PER_INCH
  const b = Number(page.height) * PX_PER_INCH
  const long = Math.max(a, b)
  const short = Math.min(a, b)
  return page.orientation === 'portrait' ? { width: short, height: long } : { width: long, height: short }
}

// What the export draws, in px: the content plus margins and the title band.
export function exportSize (doc, { title = true } = {}) {
  const bounds = contentBounds(doc, layoutLanes(doc))
  return {
    bounds,
    width: Math.ceil(bounds.w + EXPORT_MARGIN * 2),
    height: Math.ceil(bounds.h + EXPORT_MARGIN * 2 + (title ? TITLE_HEIGHT : 0))
  }
}

// { fits, scale, minScale, width, height, page } — `scale` is how much the
// diagram has to shrink to fit the printable area (above 1 when it would fit
// larger); it fits when that is no smaller than MIN_SCALE.
export function pageFit (doc, page = LETTER, { title = true } = {}) {
  const sheet = pageSize(page)
  const { width, height } = exportSize(doc, { title })
  const scale = Math.min((sheet.width - PAGE_MARGIN * 2) / width, (sheet.height - PAGE_MARGIN * 2) / height)
  return { fits: scale >= MIN_SCALE, scale, minScale: MIN_SCALE, width, height, page: sheet }
}

// The sheet around the content: page-sized in CSS pixels, the content
// centred and scaled to the printable area (never enlarged).
export function sheetFor (fit, content) {
  const scale = Math.min(1, fit.scale)
  const w = fit.page.width / scale
  const h = fit.page.height / scale
  const x = content.x0 + content.width / 2 - w / 2
  const y = content.y0 + content.height / 2 - h / 2
  return { width: Math.round(fit.page.width), height: Math.round(fit.page.height), x, y, w, h, viewBox: `${x} ${y} ${w} ${h}` }
}
