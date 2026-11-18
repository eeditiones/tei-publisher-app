// ***********************************************
// This example commands.js shows you how to
// create various custom commands and overwrite
// existing commands.
//
// For more comprehensive examples of custom
// commands please read more here:
// https://on.cypress.io/custom-commands
// ***********************************************
//
import 'cypress-ajv-schema-validator'

// Simple, idiomatic auth helpers using Cypress patterns

// Cache the authenticated session across specs to speed up runs
// See: https://docs.cypress.io/api/commands/session
Cypress.Commands.add('login', (fixtureName = 'user') => {
  return cy.fixture(fixtureName).then(({ user, password }) => {
    const baseUrl = Cypress.config('baseUrl')
    const origin = baseUrl ? new URL(baseUrl).origin : null
    if (!origin) {
      throw new Error(
        'baseUrl must be configured in Cypress config. Set it in cypress.config.cjs',
      )
    }
    return cy
      .request({
        method: 'POST',
        url: '/api/login',
        form: true,
        body: { user, password },
        headers: { Origin: origin, Accept: 'application/json' },
      })
      .its('status')
      .should('eq', 200)
  })
})

Cypress.Commands.add('logout', () => {
  // Best-effort server logout, then clear client-side cookies
  cy.request({
    method: 'POST',
    url: '/api/login',
    qs: { logout: 'true' },
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    failOnStatusCode: false,
  })
  cy.clearCookies()
})

// Lightweight wrapper for API calls that need an Origin header
// Usage:
//  cy.api('/api/search')
//  cy.api({ method: 'POST', url: '/api/odd', qs: {...} })
Cypress.Commands.add('api', (opts) => {
  const options = typeof opts === 'string' ? { url: opts } : { ...opts }
  const baseUrl = Cypress.config('baseUrl')
  const origin = baseUrl ? new URL(baseUrl).origin : null
  if (!origin) {
    throw new Error(
      'baseUrl must be configured in Cypress config. Set it in cypress.config.cjs',
    )
  }
  options.headers = { Origin: origin, ...(options.headers || {}) }
  return cy.request(options)
})

// XML upload helper. Upload a fixture document
// Supports both signatures:
// 1) uploadXml(filename, xml, opts?)
// 2) uploadXml(endpoint, filename, xml, opts?) - legacy
Cypress.Commands.add('uploadXml', (target, arg2, arg3, arg4) => {
  const isLegacyCall = typeof arg3 === 'string'
  const options = (isLegacyCall ? arg4 : arg3) || {}

  const url = isLegacyCall
    ? `${target.replace(/\/$/, '')}/${encodeURIComponent(arg2)}`
    : `/api/document/${encodeURIComponent(target)}`
  const body = isLegacyCall ? arg3 : arg2

  return cy.api({
    ...options,
    method: 'PUT',
    url,
    body,
    // Fail by default, but allow tests to override this behavior.
    failOnStatusCode: options.failOnStatusCode ?? true,
    headers: {
      'content-type': 'application/xml',
      ...(options.headers || {}),
    },
  })
})

Cypress.Commands.add('findFiles', (pattern) => {
  return cy.task('findFiles', { pattern })
})

Cypress.Commands.add('validateJsonSchema', (ajv, schema, data, filePath) => {
  const valid = ajv.validate(schema, data)
  if (!valid) {
    const formattedErrors = ajv.errors.map((error) => {
      const path = error.instancePath.slice(1)
      const propertySchema = schema.properties?.[path]

      return {
        path: path || 'root',
        value: error.instancePath
          ? error.instancePath.split('/').reduce((obj, key) => obj?.[key], data)
          : data,
        message: error.message,
        keyword: error.keyword,
        expectedType: propertySchema?.type,
        format: propertySchema?.format,
        enum: propertySchema?.enum,
      }
    })

    const errorMessage = [
      `\n❌ Schema validation failed for: ${filePath}`,
      '-'.repeat(60),
      'Validation errors:',
      JSON.stringify(formattedErrors, null, 2),
      '-'.repeat(60),
      'Expected format:',
      schema.required ? `Required fields: ${schema.required.join(', ')}` : '',
      schema.properties
        ? Object.entries(schema.properties)
            .map(
              ([key, prop]) =>
                `- ${key}: ${prop.type}${prop.format ? ` (${prop.format})` : ''}${prop.enum ? ` [${prop.enum.join('|')}]` : ''}`,
            )
            .join('\n')
        : '',
    ]
      .filter(Boolean)
      .join('\n')

    expect(valid, errorMessage).to.be.true
  }
})

// Helper commands for feature-specific intercepts

/**
 * Setup intercepts for register API calls
 * @param {string[]} registers - Array of register names (default: ['people', 'places', 'bibliography'])
 * @example
 * cy.setupRegisterIntercepts(['people', 'places'])
 * cy.setupRegisterIntercepts() // uses defaults
 */
Cypress.Commands.add(
  'setupRegisterIntercepts',
  (registers = ['people', 'places', 'bibliography']) => {
    registers.forEach((register) => {
      // Intercept register API calls - match URLs like /api/places?search=&category=A
      // Use RouteMatcher with url pattern that matches query parameters
      // The ** pattern in minimatch matches any characters including query strings
      cy.intercept({
        method: 'GET',
        url: `**/api/${register}**`,
      }).as(`${register}Api`)
    })
  },
)

/**
 * Setup intercepts for search API calls
 * @example
 * cy.setupSearchIntercepts()
 */
Cypress.Commands.add('setupSearchIntercepts', () => {
  // Intercept search API calls - pb-search may trigger collection API or search API
  cy.intercept('GET', '/api/search**').as('searchApi')
  cy.intercept('GET', '/api/search/facets**').as('facetsApi')
  cy.intercept('GET', '/api/collection**').as('collectionApi')
})

/**
 * Wait for pb-paginate component to exist (may not be visible if there are 0 results)
 * This is a lightweight wait that doesn't validate attributes to avoid failing entire specs
 * @example
 * cy.waitForPaginate()
 * cy.waitForPaginate({ timeout: 15000 })
 */
Cypress.Commands.add('waitForPaginate', (options = {}) => {
  const timeout = options.timeout || 10000
  cy.get('pb-paginate', { timeout: timeout }).should('exist')
})

/**
 * Wait for pb-paginate to have valid attributes (total and per-page)
 * Use this in individual tests when you need to ensure attributes are populated
 * @example
 * cy.waitForPaginateAttributes()
 */
Cypress.Commands.add('waitForPaginateAttributes', (options = {}) => {
  const timeout = options.timeout || 10000
  cy.get('pb-paginate', { timeout: timeout })
    .should('exist')
    .then(($el) => {
      // Check total attribute exists and is valid (can be 0 for empty results)
      const total = $el.attr('total')
      expect(total).to.exist
      expect(total).to.not.be.empty
      const totalNum = parseInt(total, 10)
      expect(totalNum).to.be.at.least(0)

      // Check per-page attribute exists and is valid
      const perPage = $el.attr('per-page')
      expect(perPage).to.exist
      expect(perPage).to.not.be.empty
      const perPageNum = parseInt(perPage, 10)
      expect(perPageNum).to.be.greaterThan(0)

      // Return the element to preserve the chain
      return $el
    })
})

/**
 * Get pagination attributes (total, per-page) as aliases for use in tests
 * This also ensures attributes are valid before returning them
 * @example
 * cy.getPaginationAttrs()
 * cy.get('@total').then((total) => { ... })
 * cy.get('@perPage').then((perPage) => { ... })
 */
Cypress.Commands.add('getPaginationAttrs', () => {
  cy.waitForPaginateAttributes()
  cy.get('pb-paginate').invoke('attr', 'total').as('total')
  cy.get('pb-paginate').invoke('attr', 'per-page').as('perPage')
})

/**
 * Setup intercepts for document navigation API calls
 * @example
 * cy.setupNavigationIntercepts()
 */
Cypress.Commands.add('setupNavigationIntercepts', () => {
  cy.intercept('GET', /\/api\/parts\//).as('partsApi')
  cy.intercept('GET', /\/api\/view\//).as('viewApi')
})

/**
 * Setup intercepts for ODD editor API calls
 * @example
 * cy.setupOddIntercepts()
 */
Cypress.Commands.add('setupOddIntercepts', () => {
  cy.intercept('GET', '/api/odd**').as('oddApi')
  cy.intercept('POST', '/api/odd**').as('oddSaveApi')
})

/**
 * Setup register test fixtures - uploads test document and register data
 * This ensures register tests work in isolation without depending on demo data
 * @param {Object} options - Configuration options
 * @param {string} options.documentPath - Path where test document should be uploaded (default: 'test-register/test-document.xml')
 * @param {string} options.collection - Collection name for test document (default: 'test-register')
 * @example
 * cy.setupRegisterTestFixtures()
 * cy.setupRegisterTestFixtures({ documentPath: 'test-register/test-document.xml' })
 */
Cypress.Commands.add('setupRegisterTestFixtures', (options = {}) => {
  const documentPath = options.documentPath || 'test-register/test-document.xml'
  const collection = options.collection || 'test-register'

  // Login as admin so document uploads are authorized
  cy.login()

  // Upload test document
  cy.fixture('test-document.xml', 'utf8').then((docXml) => {
    cy.uploadXml(documentPath, docXml, {
      failOnStatusCode: false,
    })
  })

  // Upload test register persons
  cy.fixture('test-register-persons.xml', 'utf8').then((personsXml) => {
    cy.uploadXml(`${collection}/test-register-persons.xml`, personsXml, {
      failOnStatusCode: false,
    })
  })

  // Upload test register places
  cy.fixture('test-register-places.xml', 'utf8').then((placesXml) => {
    cy.uploadXml(`${collection}/test-register-places.xml`, placesXml, {
      failOnStatusCode: false,
    })
  })

  // Return the document path for use in tests
  return cy.wrap(documentPath)
})

/**
 * Setup timeline API intercept with test fixture data
 * This provides sample timeline data for timeline component tests
 * @param {Object} options - Configuration options
 * @param {string} options.fixturePath - Path to timeline fixture file (default: 'timeline-data.json')
 * @example
 * cy.setupTimelineFixture()
 * cy.setupTimelineFixture({ fixturePath: 'custom-timeline.json' })
 */
Cypress.Commands.add('setupTimelineFixture', (options = {}) => {
  const fixturePath = options.fixturePath || 'timeline-data.json'

  // Load timeline fixture and intercept API calls to return it
  cy.fixture(fixturePath).then((timelineData) => {
    // Intercept timeline API calls and return fixture data
    cy.intercept(
      {
        method: 'GET',
        url: '**/api/timeline**',
      },
      (req) => {
        // Return fixture data for any timeline API call
        req.reply({
          statusCode: 200,
          body: timelineData,
        })
      },
    ).as('timelineApi')
  })
})

//
// -- This is a child command --
// Cypress.Commands.add('drag', { prevSubject: 'element'}, (subject, options) => { ... })
//
//
// -- This is a dual command --
// Cypress.Commands.add('dismiss', { prevSubject: 'optional'}, (subject, options) => { ... })
//
//
// -- This will overwrite an existing command --
// Cypress.Commands.overwrite('visit', (originalFn, url, options) => { ... })
