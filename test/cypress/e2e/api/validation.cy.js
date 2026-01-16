/// <reference types="cypress" />

const Ajv4 = require('ajv-draft-04')
const addFormats = require('ajv-formats')

const ajv4 = new Ajv4({ allErrors: true, strict: false })
addFormats(ajv4)

describe('OpenAPI Schema Validation', () => {
  const openApiSchema = 'test/cypress/schemas/openapi-3.0.json'
  const apiDefinition = 'modules/lib/api.json'

  before(() => {
    // Load and register OpenAPI schema
    cy.readFile(openApiSchema).then(schema => {
      ajv4.addSchema(schema, 'https://spec.openapis.org/oas/3.0/schema/2021-09-28')
    })
  })

  it('API definition should validate against OpenAPI 3.0.3 schema', () => {
    cy.readFile(apiDefinition).then(data => {
      const schema = ajv4.getSchema('https://spec.openapis.org/oas/3.0/schema/2021-09-28').schema
      if (!schema) {
        throw new Error('OpenAPI schema not found')
      }
      cy.validateJsonSchema(ajv4, schema, data, apiDefinition)
    })
  })
})

