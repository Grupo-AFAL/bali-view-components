// Image, SVG and print outputs. The diagram is rendered once, off screen,
// by ExportDiagram into a detached node (react-dom is already in this
// bundle, so no server renderer is pulled in) and serialised.
import { createElement } from 'react'
import { flushSync } from 'react-dom'
import { createRoot } from 'react-dom/client'
import ExportDiagram from './ExportDiagram.jsx'
import { LIVE_PAINT } from '../shapes.jsx'
import { LETTER, pageSize, PX_PER_INCH, lightThemeOf } from '../model/page.js'

// Turns the canvas' CSS colours (daisyUI variables, color-mix) into concrete
// values. Always in the LIGHT theme of the page's pair: an image, an SVG or a
// printout leaves the screen, and lands on white paper or a light document
// whatever theme the viewer had on.
export function resolveColors (scope) {
  const probe = document.createElement('span')
  probe.style.display = 'none'
  const themed = scope && scope.closest ? scope.closest('[data-theme]') : null
  probe.setAttribute('data-theme', lightThemeOf(themed && themed.getAttribute('data-theme')))
  ;(scope || document.body).appendChild(probe)
  const resolve = (value) => {
    probe.style.color = ''
    probe.style.color = value
    return getComputedStyle(probe).color
  }
  const paint = {}
  for (const [key, value] of Object.entries(LIVE_PAINT)) {
    paint[key] = typeof value === 'string' ? resolve(value) : { fill: resolve(value.fill), stroke: resolve(value.stroke) }
  }
  const colors = {
    background: resolve('var(--color-base-100)'),
    header: resolve('var(--color-base-200)'),
    border: resolve('var(--color-base-300)'),
    text: resolve('var(--color-base-content)'),
    muted: resolve('color-mix(in oklab, var(--color-base-content) 65%, var(--color-base-100))'),
    line: resolve('color-mix(in oklab, var(--color-base-content) 72%, var(--color-base-100))'),
    externalLane: resolve('color-mix(in oklab, var(--color-base-content) 7%, var(--color-base-100))'),
    externalHeader: resolve('color-mix(in oklab, var(--color-base-content) 13%, var(--color-base-100))'),
    primary: resolve('var(--color-primary)'),
    watermark: resolve('var(--color-error)')
  }
  probe.remove()
  return { paint, colors }
}

export function renderSvg (props) {
  const container = document.createElement('div')
  const root = createRoot(container)
  flushSync(() => root.render(createElement(ExportDiagram, props)))
  const markup = container.innerHTML
  root.unmount()
  return `<?xml version="1.0" encoding="UTF-8"?>\n${markup}`
}

export function download (fileName, content, type) {
  const blob = content instanceof Blob ? content : new Blob([content], { type })
  const anchor = document.createElement('a')
  anchor.href = URL.createObjectURL(blob)
  anchor.download = fileName
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
  setTimeout(() => URL.revokeObjectURL(anchor.href), 2000)
}

function svgSize (svg) {
  const width = Number((svg.match(/<svg[^>]*\swidth="(\d+)/) || [])[1]) || 1200
  const height = Number((svg.match(/<svg[^>]*\sheight="(\d+)/) || [])[1]) || 800
  return { width, height }
}

// PNG at 2× for legibility; canvases above ~16k px per side fail, so very
// large diagrams drop to 1×.
export function downloadPng (fileName, svg) {
  return new Promise((resolve, reject) => {
    const { width, height } = svgSize(svg)
    const scale = Math.max(width, height) * 2 > 16000 ? 1 : 2
    const image = new window.Image()
    image.onload = () => {
      const canvas = document.createElement('canvas')
      canvas.width = width * scale
      canvas.height = height * scale
      const context = canvas.getContext('2d')
      context.scale(scale, scale)
      context.drawImage(image, 0, 0)
      canvas.toBlob((blob) => { download(fileName, blob); resolve() }, 'image/png')
    }
    image.onerror = reject
    image.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`
  })
}

// Prints the full diagram on its own page, scaled to the sheet, through a
// hidden iframe: the page around the editor is not part of the printout.
// The sheet is `paper` (letter by default, model/page.js); a drawing already
// laid on that sheet (data-sheet) brings its own margins.
export function printSvg (svg, title, paper = LETTER) {
  const sheet = pageSize(paper)
  const onSheet = /<svg[^>]*\sdata-sheet="true"/.test(svg)
  const size = `${sheet.width / PX_PER_INCH}in ${sheet.height / PX_PER_INCH}in`
  const frame = document.createElement('iframe')
  frame.setAttribute('aria-hidden', 'true')
  frame.style.position = 'fixed'
  frame.style.width = '0'
  frame.style.height = '0'
  frame.style.border = '0'
  document.body.appendChild(frame)
  const page = frame.contentDocument
  page.open()
  page.write(`<!doctype html><html><head><meta charset="utf-8"><title>${escapeHtml(title || '')}</title><style>
    @page { size: ${size}; margin: ${onSheet ? 0 : '10mm'}; }
    html, body { margin: 0; }
    svg { width: 100%; height: auto; max-height: 100vh; }
  </style></head><body>${svg.replace(/^<\?xml[^>]*>\s*/, '')}</body></html>`)
  page.close()
  const run = () => {
    frame.contentWindow.focus()
    frame.contentWindow.print()
    setTimeout(() => frame.remove(), 1000)
  }
  if (page.readyState === 'complete') setTimeout(run, 50)
  else frame.onload = run
}

const escapeHtml = (text) => String(text).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]))

export const fileName = (name, extension) => `${String(name || 'diagram').trim().replace(/[^\p{L}\p{N}]+/gu, '-').replace(/^-|-$/g, '').toLowerCase() || 'diagram'}.${extension}`
