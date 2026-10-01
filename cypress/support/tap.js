// Touch input through Chromium's own pipeline, sent over CDP. For a tap the browser
// fires touchstart, touchend and then the compatibility mouseover, mousedown, focusin,
// mouseup and click a phone fires — the same order Playwright's `isMobile` tap
// measured. `.trigger('touchstart')` would fire only the event it names, so the spec
// would be deciding the order instead of the browser.
//
// After a failed test's screenshot, a later `touchStart` in the run can wait forever
// and surface as "promise never resolved": read the first failure, or rerun with
// `CYPRESS_screenshotOnRunFailure=false`.
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

// Starts on the element and moves `dy` pixels: the browser reads it as a scroll and
// fires no click.
export const drag = ($el, dy) => {
  const [x, y] = centreOf($el)

  return touch('touchStart', [inRunner(x, y)])
    .then(() => touch('touchMove', [inRunner(x, y + dy)]))
    .then(() => touch('touchEnd', []))
}
