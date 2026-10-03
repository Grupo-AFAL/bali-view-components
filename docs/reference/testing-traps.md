# Testing traps

Ways a test in this repo goes green without testing what it names. When a new one turns up, it
goes here.

## Cypress

- **CSS transitions.** After switching `data-theme`, or a class on anything with
  `transition-colors`, the computed colour is a frame of the transition: the previous state's. A
  `should` callback passes on its first try if the previous state already passes, and a `then`
  never retries, so a contrast guard could go green on every theme having measured only `light`.
  Make the first assertion of the callback `expect(doc.getAnimations()).to.have.length(0)`. Two
  things keep the document from ever emptying: a toast's `bali-toast-in` stays listed once it
  ends (`fill: both`), and while any daisyUI `.modal` is open — every open `Bali::Modal` — daisyUI
  runs `set-page-has-scroll` on `:root` against a scroll timeline. With either on the page, wait
  on `el.getAnimations({ subtree: true })` for an `el` that holds both the text and the ground it
  is measured over.
  A guard that spans many pages, or measures beside a spinner of its own (Frame's), waits on the
  document instead and leaves out what repeats forever, which no transition does:
  `animation.effect.getComputedTiming().iterations !== Infinity` (`muted-text-contrast.cy.js`).
- **Turbo Streams apply on the next frame** (after `nextRepaint()`). Asserting right after
  `Turbo.renderStreamMessage` reads the node being replaced. Put a marker on the streamed markup
  (`data-streamed`) and wait for `[data-…][data-streamed]` before asserting.
- **`should('be.enabled')` / `should('be.disabled')` on several elements passes if any one
  matches** — chai-jQuery runs `$el.is(…)`. Count the ones that miss, so `should` still retries:
  `.should($fs => expect($fs.filter(':disabled')).to.have.length(0))`, and `':enabled'` for the
  disabled case.
- **An uncaught error only fails the test if it reaches the window.** `react-island.js` catches
  whatever `beforeUnmount()` or `root.unmount()` throws — the first only reaches
  `console.error`, which is what hid #1212 for the main editor. An error React 19 hits while it
  commits the unmount (a ref or effect cleanup) goes out through `reportError` instead, and
  Cypress does see that one. Assert the DOM contract the fix restores, not the absence of an
  error.
- **Contrast.** `getComputedStyle().color` carries the colour's alpha but not the element's
  `opacity`. Measure with `paintedContrast` from `cypress/support/painted_contrast.js`, which
  composites both over the nearest opaque background, after painting every translucent
  background between the text and that ground. It still misses a `background-image` and a
  pseudo-element's background, which the caller hands over as `under`, and the `opacity` of the
  node that carries a tint is not applied to that tint. Nor does it see a `filter`, an inset
  `box-shadow`, an `opacity` above the ground, a pseudo-element drawn over the text or a
  `::first-line` or `::first-letter` colour, which a `<button>` honours in Chromium: rule them
  out, as `status-palette-contrast.cy.js` does by comparing the computed style of the hovered
  row, its ancestors and their pseudo-elements with the same elements at rest.
- **`should('not.be.visible')` passes on a dropdown that is open.** daisyUI fades the panel in
  from `opacity: 0` through `@starting-style`, and Cypress counts opacity: measured in #1231, a
  "stays closed" assertion went green on a menu at `display: flex`. Assert `display` from
  `getComputedStyle` instead (`expectClosed` in `dropdown-controller.cy.js`).
- **After a failure screenshot, Electron stops starting Mantine's fades.** Once a test in the
  run has failed and Cypress has taken its screenshot, a Mantine popover opened later in that
  Electron run never starts its fade-in: the `opacity` transition stays pending and the popover
  computes `opacity: 0` (Chrome finishes it). In a negative control that fails every theme, the
  first test fails on its own assertion and the rest time out on the fade, so the control looks
  as if it caught one theme. `theme-follow-contrast.cy.js` turns the transition off on the
  link popover it measures; to check a control, `CYPRESS_screenshotOnRunFailure=false` or Chrome.
- **A guard that switches `data-theme` right after the visit can pass on a lost update.** A
  React island that read the scheme with `useState` and subscribed with a `MutationObserver` in
  `useEffect` missed a switch landing between its first render and the effect, and stayed light
  on a dark page: 3 of 30 switches under Cypress, so the guard went green most runs. Treat such
  a flake as the bug. `useSyncExternalStore` reads the value again once it has subscribed
  (`usePageColorScheme` in `BlockNoteEditorWrapper.jsx`): 0 of 50.
- **Hidden text is still text.** Assert visibility or state, not `textContent` — hidden notices
  are always in the DOM.
- **"No request happened"** needs a bounded `cy.wait(…)` before asserting
  `cy.get('@alias.all').should('have.length', 0)`; without it the assertion runs before the
  request could have left.
- **After `yarn build`, restart the dummy server.** Digested assets are served with immutable
  caching, so the browser keeps running the old bundle and the spec tests the code from before.
- **`.scrollIntoView()` ignores `scroll-margin`.** Cypress computes its own offsets. Call the
  native method inside a `then` and measure in the same block.
- **A `hover:` utility needs a real pointer and `(hover: hover)`.** `.trigger('mouseover')`
  dispatches the event but never makes the element match `:hover`. And Tailwind 4 wraps every
  `hover:` utility in `@media (hover: hover)`, which headless Chrome without a mouse reports as
  false: `:hover` matches, no `hover:` style applies, and a contrast guard measures the element
  at rest — four of five themes passed that way in CI. Rest the pointer with `hover()` from
  `cypress/support/tap.js`, which fails if the browser reports `(hover: none)`
  (`cypress/plugins/index.cjs` gives Chrome a pointer that hovers). The pointer stays where the
  previous test left it: `unhover()` in an `afterEach`, and assert `!el.matches(':hover')`
  before measuring a resting state.
