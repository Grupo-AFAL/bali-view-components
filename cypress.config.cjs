const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    // We've imported your old cypress plugins here.
    // You may want to clean this up later by importing these.
    setupNodeEvents (on, config) {
      return require('./cypress/plugins/index.cjs')(on, config)
    },
    baseUrl: 'http://localhost:3001/lookbook/preview',
    // Prevent Electron renderer crashes
    experimentalMemoryManagement: true,
    numTestsKeptInMemory: 0
  }
})
