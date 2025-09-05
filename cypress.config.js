const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    setupNodeEvents (on, config) { return config },
    baseUrl: 'http://localhost:8080/exist/apps/tei-publisher', 
    trashAssetsBeforeRuns: true,
    includeShadowDom: true,
    supportFile: 'test/cypress/support/e2e.js', 
    specPattern: 'test/cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
    screenshotsFolder: 'test/cypress/screenshots',
    videosFolder: 'test/cypress/videos',
    fixturesFolder: 'test/cypress/fixtures',
    downloadsFolder: 'test/cypress/downloads'
  },
});
