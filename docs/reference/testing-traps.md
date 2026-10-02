# Testing traps

Ways a test in this repo goes green without testing what it names. When a new one turns up, it
goes here.

## Cypress

- **CSS transitions.** After switching `data-theme`, or a class on anything with
  `transition-colors`, the computed colour is a frame of the transition: the previous state's. A
  `should` callback passes on its first try if the previous state already passes, and a `then`
  never retries, so a contrast guard could go green on every theme having measured only `light`.
  Make the first assertion of the callback `expect(doc.getAnimations()).to.have.length(0)`. Under
  `AppLayout` — the dummy app's own pages — the document never goes still: unless `drawer: false`,
  its closed drawer holds a `Skeleton` that animates forever. There, wait on
  `el.getAnimations({ subtree: true })` for an `el` that holds both the text and the ground it is
  measured over.
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
  background between the text and that ground. It still misses a pseudo-element's background,
  and the `opacity` of the node that carries a tint is not applied to that tint.
- **`should('not.be.visible')` passes on a dropdown that is open.** daisyUI fades the panel in
  from `opacity: 0` through `@starting-style`, and Cypress counts opacity: measured in #1231, a
  "stays closed" assertion went green on a menu at `display: flex`. Assert `display` from
  `getComputedStyle` instead (`expectClosed` in `dropdown-controller.cy.js`).
- **Hidden text is still text.** Assert visibility or state, not `textContent` — hidden notices
  are always in the DOM.
- **"No request happened"** needs a bounded `cy.wait(…)` before asserting
  `cy.get('@alias.all').should('have.length', 0)`; without it the assertion runs before the
  request could have left.
- **After `yarn build`, restart the dummy server.** Digested assets are served with immutable
  caching, so the browser keeps running the old bundle and the spec tests the code from before.
- **`.scrollIntoView()` ignores `scroll-margin`.** Cypress computes its own offsets. Call the
  native method inside a `then` and measure in the same block.
