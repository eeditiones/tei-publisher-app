const { defineConfig } = require('cypress');
const glob = require('glob');

module.exports = defineConfig({
  e2e: {
    setupNodeEvents(on, config) {
      on('task', {
        findFiles({ pattern }) {
          // Use glob.sync to get the files synchronously
          return glob.sync(pattern, { nodir: true });
        }
      });
      return config;
    },
    baseUrl: 'http://localhost:8080/exist/apps/tei-publisher',
    viewportWidth: 1280,
    viewportHeight: 720,
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

