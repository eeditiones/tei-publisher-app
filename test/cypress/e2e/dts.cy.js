// StandardJS, should-style assertions

describe('/api/dts', () => {
  it('queries entry point', () => {
    cy.api('/api/dts')
      .its('status').should('eq', 200)

    cy.api('/api/dts').then(({ body }) => {
      cy.wrap(body['@type']).should('eq', 'EntryPoint')
    })
  })
})

let downloadLink

describe('/api/dts/collection', () => {
  it('gets default collection', () => {
    cy.api('/api/dts/collection')
      .its('status').should('eq', 200)

    cy.api('/api/dts/collection').then(({ body }) => {
      cy.wrap(body['@type']).should('eq', 'Collection')
      cy.wrap((body.member || []).length).should('be.greaterThan', 1)
    })
  })

  it('navigates to child collection', () => {
    cy.api({
      method: 'GET',
      url: '/api/dts/collection',
      qs: { id: 'https://teipublisher.com/dts/demo', nav: 'children', 'per-page': 50 }
    }).then(({ status, body }) => {
      cy.wrap(status).should('eq', 200)
      cy.wrap(body['@type']).should('eq', 'Collection')
      cy.wrap((body.member || []).length).should('be.greaterThan', 1)
      const member = (body.member || []).find(m => m['@id'] === 'https://teipublisher.com/dts/demo/let695.xml')
      cy.wrap(!!member).should('eq', true)
      cy.wrap(member).should('have.property', 'dts:passage')
      downloadLink = new URL(member['dts:passage'], 'http://localhost:8080').toString()
    })
  })
})

describe('/api/dts/document', () => {
  beforeEach(() => {
    cy.login()
  })

  it('retrieves resource', () => {
    cy.wrap(null).then(() => {
      // Use cy.request on absolute URL
      return cy.request(downloadLink)
    }).then(({ status, headers }) => {
      cy.wrap(status).should('eq', 200)
      cy.wrap(headers['content-type']).should('include', 'application/xml')
    })
  })

  it('imports resource', () => {
    cy.api({
      method: 'GET',
      url: '/api/dts/import',
      qs: { uri: downloadLink, temp: 'true' }
    }).then(({ status, headers, body }) => {
      cy.wrap(status).should('eq', 201)
      cy.wrap(headers['content-type']).should('include', 'application/json')
      cy.wrap(body).should('have.property', 'path')
    })
  })
})

