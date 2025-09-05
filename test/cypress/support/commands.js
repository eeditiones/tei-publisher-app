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

// Multipart XML upload helper
// Usage: cy.uploadXml('/api/upload/playground', 'file.xml', xmlString, { headers: {...}, failOnStatusCode: false })
Cypress.Commands.add('uploadXml', (url, filename, xml, opts = {}) => {
  const boundary = '----CYPRESSFORM' + Date.now()
  const body = [
    `--${boundary}\r\n` +
    `Content-Disposition: form-data; name="files[]"; filename="${filename}"\r\n` +
    'Content-Type: application/xml\r\n\r\n' +
    xml + '\r\n' +
    `--${boundary}--\r\n`
  ].join('')
  const headers = { 'Content-Type': `multipart/form-data; boundary=${boundary}`, Accept: 'application/json', ...(opts.headers || {}) }
  return cy.api({ method: 'POST', url, headers, body, failOnStatusCode: opts.failOnStatusCode })
})
