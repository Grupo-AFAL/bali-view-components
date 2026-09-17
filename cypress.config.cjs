const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    // We've imported your old cypress plugins here.
    // You may want to clean this up later by importing these.
    setupNodeEvents (on, config) {
      return require('./cypress/plugins/index.cjs')(on, config)
    },
    baseUrl: 'http://localhost:3001/lookbook/preview',
    // Prevent Electron renderer crashes. `experimentalMemoryManagement: true` used to
    // sit here; Cypress 16 removed it in favour of `manageBrowserMemory`, which is on
    // by default, so only the second half of the pair is still spelled out.
    numTestsKeptInMemory: 0
  }
})
