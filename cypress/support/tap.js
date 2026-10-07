// Touch and mouse input through Chromium's own pipeline, sent over CDP. For a tap the
// browser fires touchstart, touchend and then the compatibility mouseover, mousedown,
// focusin, mouseup and click a phone fires — the same order Playwright's `isMobile` tap
// measured. `.trigger('touchstart')` would fire only the event it names, so the spec
// would be deciding the order instead of the browser.
//
// After a failed test's screenshot, a later `touchStart` in the run can wait forever
// and surface as "promise never resolved": read the first failure, or rerun with
// `CYPRESS_screenshotOnRunFailure=false`. A `mouseMoved` still resolves, but slowly:
// measured after one, each took ~1 s instead of ~10 ms, and a theme's transitions
// took 3.7–3.9 s of the 4 s retry to settle.
const touch = (type, touchPoints) =>
  Cypress.automation('remote:debugger:protocol', {
    command: 'Input.dispatchTouchEvent',
    params: { type, touchPoints }
  })

// CDP takes coordinates in the runner's top-level page; the app runs in an iframe that
// Cypress scales to fit its panel (0.74 at 390px under `cypress run`).
const inRunner = (x, y) => {
  const frame = window.top.document.querySelector('.aut-iframe')
  const rect = frame.getBoundingClientRect()
  const scale = rect.width / frame.offsetWidth

  return { x: rect.left + x * scale, y: rect.top + y * scale }
}

const centreOf = ($el) => {
  const el = $el[0]
  el.scrollIntoView({ block: 'center' })
  const r = el.getBoundingClientRect()

  return [r.left + r.width / 2, r.top + r.height / 2]
}

export const tap = ($el) => {
  const [x, y] = centreOf($el)

  return touch('touchStart', [inRunner(x, y)]).then(() => touch('touchEnd', []))
}

// Starts on the element and moves `dy` pixels down and `dx` across: unless the element
// says otherwise (`touch-action`), the browser reads it as a scroll and fires no click.
// The first move reaches the page before the browser decides it is a scroll, so a
// single one passes for a drag either way; in `steps`, the page loses the rest (measured
// on the Gantt splitter: 20 to 25 of 60 px in 12 steps, all 60 in one).
export const drag = ($el, dy, { dx = 0, steps = 1 } = {}) => {
  const [x, y] = centreOf($el)
  const moves = Array.from({ length: steps }, (_, i) => inRunner(x + (dx * (i + 1)) / steps, y + (dy * (i + 1)) / steps))

  return moves
    .reduce((sent, point) => sent.then(() => touch('touchMove', [point])), touch('touchStart', [inRunner(x, y)]))
    .then(() => touch('touchEnd', []))
}

const moveMouse = (point) =>
  Cypress.automation('remote:debugger:protocol', {
    command: 'Input.dispatchMouseEvent',
    params: { type: 'mouseMoved', ...point }
  })

// A mouse resting on the element, through the same pipeline, so the browser itself
// matches `:hover`. `.trigger('mouseover')` dispatches the event and nothing else: no
// rule a stylesheet scopes to `:hover` ever applies. A browser that reports
// `(hover: none)` matches `:hover` all the same but applies no `hover:` utility, so a spec
// measures the element at rest and passes wherever that colour already does (four of the
// five themes did in CI); it fails here instead (cypress/plugins/index.cjs).
export const hover = ($el) => {
  if (!$el[0].ownerDocument.defaultView.matchMedia('(hover: hover)').matches) {
    throw new Error('hover: the browser reports (hover: none), so no hover: utility applies')
  }

  const [x, y] = centreOf($el)

  return moveMouse(inRunner(x, y))
}

// The pointer stays where the last test left it, over whatever the next page draws
// there. The runner's corner is outside the app.
export const unhover = () => moveMouse({ x: 0, y: 0 })

const mouseButton = (type, point) =>
  Cypress.automation('remote:debugger:protocol', {
    command: 'Input.dispatchMouseEvent',
    params: { type, button: 'left', clickCount: 1, ...point }
  })

// The left button held down on the element and let go, through the same pipeline: what a
// drag library such as SortableJS sees before the pointer moves.
export const press = ($el) => mouseButton('mousePressed', inRunner(...centreOf($el)))
export const release = ($el) => mouseButton('mouseReleased', inRunner(...centreOf($el)))
