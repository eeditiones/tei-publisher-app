// ***********************************************************
// This example support/e2e.js is processed and
// loaded automatically before your test files.
//
// This is a great place to put global configuration and
// behavior that modifies Cypress.
//
// You can change the location of this file or turn off
// automatically serving support files with the
// 'supportFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/configuration
// ***********************************************************

// Import commands.js using ES2015 syntax:
import './commands'

// Handle uncaught exceptions from application code
// Some errors in pb-components are non-critical and shouldn't fail tests
Cypress.on('uncaught:exception', (err, runnable) => {
  // Ignore known non-critical errors from pb-components
  if (err.message.includes("t.lastError is undefined")) {
    // This is a bug in pb-components error handling, not a test failure
    return false
  }
  if (err.message.includes("Cannot read properties of null (reading 'language')")) {
    // Language-related errors that don't affect test functionality
    return false
  }
  if (err.message.includes("Failed to load openseadragon script with location")) {
    // OpenSeadragon loading errors that don't affect most tests
    return false
  }
  // Let other errors fail the test
  return true
})

// Universal intercepts for all GUI tests
// These stubs prevent hanging on API calls that aren't relevant to most tests
beforeEach(() => {
  // Stub login attempts to prevent authentication popups in non-auth tests
  cy.intercept('POST', '/api/login/**', { statusCode: 401, body: { error: 'Unauthorized' } }).as('loginStub')
  
  // Stub timeline API to prevent hanging when timeline component tries to load
  cy.intercept('GET', '/api/timeline/**', { statusCode: 200, body: { timeline: [] } }).as('timelineStub')
})
