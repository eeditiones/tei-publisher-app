// StandardJS, should-style assertions

// Uploads are handled via cy.uploadXml in support/commands

describe('/api/collection', () => {
  it('retrieves document list for default data collection', () => {
    cy.api('/api/collection')
      .its('status').should('eq', 200)

    cy.api('/api/collection')
      .its('body').should('include', 'TEI Publisher Demo Collection')

    cy.api('/api/collection')
      .its('body').should('include', 'Playground')
  })

  it('retrieves document list for test collection', () => {
    cy.api('/api/collection/test')
      .its('status').should('eq', 200)

    cy.api('/api/collection/test')
      .its('body').should('include', 'Up')

    cy.api('/api/collection/test')
      .its('body').should('include', 'Bogactwa mowy polskiej')
  })
})

describe('/api/upload [authenticated]', () => {
  beforeEach(() => {
    cy.login()
  })

  it('uploads a document to playground collection', () => {
    cy.readFile('data/test/graves6.xml', 'utf8').then(xml => {
      cy.uploadXml('/api/upload/playground', 'graves6.xml', xml)
        .then(({ status, body }) => {
          expect(status).to.eq(200)
          expect(body).to.have.length(1)
          expect(body[0].name).to.eq('/db/apps/tei-publisher/data/playground/graves6.xml')
        })
    })
  })

  it('deletes the uploaded document', () => {
    cy.api({ method: 'DELETE', url: '/api/document/playground%2Fgraves6.xml', failOnStatusCode: false })
      .its('status').should('eq', 204)
  })

  it('uploads a document to the root collection of the app', () => {
    cy.readFile('data/test/let695.xml', 'utf8').then(xml => {
      cy.uploadXml('/api/upload', 'let695.xml', xml)
        .then(({ status, body }) => {
          expect(status).to.eq(200)
          expect(body).to.have.length(1)
          expect(body[0].name).to.eq('/db/apps/tei-publisher/data/let695.xml')
        })
    })
  })

  it('deletes the uploaded document from root collection', () => {
    cy.api({ method: 'DELETE', url: '/api/document/let695.xml', failOnStatusCode: false })
      .its('status').should('eq', 204)
  })
})

describe('/api/upload [unauthorized]', () => {
  beforeEach(() => {
    cy.logout()
    cy.clearCookies()
    cy.clearLocalStorage()
  })

  it('tries to upload a document to playground collection', () => {
    cy.readFile('data/test/graves6.xml', 'utf8').then(xml => {
      cy.uploadXml('/api/upload/playground', 'graves6.xml', xml, { headers: { Cookie: '' }, failOnStatusCode: false })
        .its('status').should('eq', 401)
    })
  })
})
