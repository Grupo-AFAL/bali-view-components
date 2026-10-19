/// <reference types="cypress" />

// Tailwind 4 wraps every `hover:` utility in `@media (hover: hover)`, and headless Chrome on
// a machine with no mouse reports `(hover: none)` (measured with Chrome for Testing 151):
// `:hover` still matches, but no `hover:` style applies. These Blink settings make Chrome
// report a fine pointer that hovers, like the laptops the apps are used on. Electron under
// xvfb already reports the X server's pointer, so it needs nothing.
const DESKTOP_POINTER =
  '--blink-settings=primaryHoverType=2,availableHoverTypes=2,primaryPointerType=4,availablePointerTypes=4'

const { execFileSync } = require('node:child_process')
const path = require('node:path')

/** @type {Cypress.PluginConfig} */
module.exports = (on) => {
  // Data a spec needs and no preview can make, written to the dummy's database through
  // `bin/rails runner` (Cypress 16 removed `cy.exec`). Returns null: a task must return something.
  on('task', {
    railsRunner (code) {
      execFileSync('bin/rails', ['runner', code], { cwd: path.join(__dirname, '../../test/dummy'), stdio: 'inherit' })
      return null
    }
  })

  on('before:browser:launch', (browser, launchOptions) => {
    if (browser.family === 'chromium' && browser.name !== 'electron') launchOptions.args.push(DESKTOP_POINTER)

    return launchOptions
  })
}
