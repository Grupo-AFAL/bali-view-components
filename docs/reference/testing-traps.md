# Testing traps

Ways a test in this repo goes green without testing anything. Each one shipped, or nearly did,
in the batch #1216–#1227. When a new one turns up, it goes here.

## Cypress

- **CSS transitions.** After switching `data-theme`, or a class on anything with
  `transition-colors`, the computed colour is a frame of the transition: the previous state's. A
  `should` callback passes on its first try if the previous state already passes, so a contrast
  guard could go green on all five themes having measured only `light`. Make the first assertion of the callback
  `expect($el[0].getAnimations({ subtree: true })).to.have.length(0)`.
- **Turbo Streams apply on the next frame** (after `nextRepaint()`). Asserting right after
  `Turbo.renderStreamMessage` reads the node being replaced. Put a marker on the streamed markup
  (`data-streamed`) and wait for `[data-…][data-streamed]` before asserting.
- **`should('be.enabled')` / `should('be.disabled')` on several elements passes if any one
  matches** — chai-jQuery runs `$el.is(…)`. Assert each: `.each($f => expect($f).to.be.enabled)`.
- **An uncaught error only fails the test if it reaches the window.** React 19 reports errors in
  unmount through `reportError`, so Cypress sees them; an error `root.unmount()` throws is caught
  by `react-island.js`. Assert the DOM contract the fix restores instead of the absence of an
  error.
- **Contrast.** `getComputedStyle().color` carries the colour's alpha but not the element's
  `opacity`. Measure with `paintedContrast` from `cypress/support/painted_contrast.js`, which
  composites both over the opaque background.
- **`.scrollIntoView()` ignores `scroll-margin`.** Cypress computes its own offsets. Call the
  native method inside a `then` and measure in the same block.

## Stimulus

- **`[name]TargetConnected` runs for the targets present before `connect()`.** It already is the
  initial render; evaluating again in `connect` does the work twice.

## ERB

- **`tag.attributes(data: { key: nil })` omits the attribute.** No `<% if %>` in the middle of a
  tag.

## Hooks

- **`.claude/hooks/pr-closes-keyword.sh` reads the command text.** A Bash command that contains a
  Spanish closing verb followed by `#N` and a `gh api … pulls` call — writing that hook's own
  tests, for instance — is blocked. Put such edits in a script file and run the file.
