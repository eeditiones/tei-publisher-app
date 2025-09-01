// Simple, idiomatic auth helpers using Cypress patterns

// Cache the authenticated session across specs to speed up runs
// See: https://docs.cypress.io/api/commands/session
Cypress.Commands.add('login', (fixtureName = 'user') => {
  return cy.fixture(fixtureName).then(({ user, password }) => {
    return cy.request({
      method: 'POST',
      url: '/api/login',
      form: true,
      body: { user, password },
      headers: { Origin: 'http://localhost:8080', Accept: 'application/json' }
    }).its('status').should('eq', 200)
  })
})

Cypress.Commands.add('logout', () => {
  // Best-effort server logout, then clear client-side cookies
  cy.request({
    method: 'POST',
    url: '/api/login',
    qs: { logout: 'true' },
    failOnStatusCode: false
  })
  cy.clearCookies()
})

// Lightweight wrapper for API calls that need an Origin header
// Usage:
//  cy.api('/api/search')
//  cy.api({ method: 'POST', url: '/api/odd', qs: {...} })
//  cy.api({ url: '/api/document/foo', headers: { Accept: 'application/xml' }})
Cypress.Commands.add('api', (opts) => {
  const options = typeof opts === 'string' ? { url: opts } : { ...opts }
  options.headers = { Origin: 'http://localhost:8080', ...(options.headers || {}) }
  return cy.request(options)
})
