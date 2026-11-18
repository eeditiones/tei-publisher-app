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

const isPbLoginProbeError = (err) => {
  if (/\buser\b/i.test(err.message) && /\bnull\b/i.test(err.message)) {
    return true
  }
  if (!err.stack?.includes('pb-components')) {
    return false
  }
  return err.stack.includes('_handleResponse') && /\buser\b/i.test(err.message)
}

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
  if (err.message.includes("L is not defined")) {
    // Leaflet may be unavailable in test runtime; this should not fail unrelated specs
    return false
  }
  if (isPbLoginProbeError(err)) {
    return false
  }
  // Let other errors fail the test
  return true
})

// Universal intercepts for all GUI tests
// These stubs prevent hanging on API calls that aren't relevant to most tests
const loginProbeReply = {
  statusCode: 200,
  headers: { 'content-type': 'application/json' },
  body: { user: null, authenticated: false },
}

const isLoginAttempt = (req) => {
  if (req.query?.logout === 'true' || req.query?.logout === true) return false
  const body = req.body
  if (typeof body === 'string') {
    const params = new URLSearchParams(body)
    return Boolean(params.get('user') || params.get('password'))
  }
  if (body && typeof body === 'object') {
    return Boolean(body.user || body.password)
  }
  return false
}

const stubLoginProbe = (req) => {
  if (req.method === 'GET' || !isLoginAttempt(req)) {
    req.reply(loginProbeReply)
  } else {
    req.continue()
  }
}

beforeEach(() => {
  // API specs exercise real auth behavior against the server (Roaster session probe).
  if (!Cypress.spec.relative.includes('/api/')) {
    // pb-login probes the session on page load (GET or empty POST); stub unless logging in.
    cy.intercept({ method: /GET|POST/, url: '**/api/login**' }, stubLoginProbe).as('loginStub')
  }

  // Stub timeline API to prevent hanging when timeline component tries to load
  cy.intercept('GET', '/api/timeline/**', { statusCode: 200, body: { timeline: [] } }).as('timelineStub')
})
