// StandardJS, should-style assertions

describe('/api/templates [authenticated]', () => {
  beforeEach(() => {
    cy.login()
  })

  it('retrieves a list of templates', () => {
    cy.api('/api/templates')
      .its('status').should('eq', 200)

    cy.api('/api/templates').then(({ body }) => {
      cy.wrap(body).should('be.an', 'array')
      cy.wrap(body).should('deep.include.members', [
        { name: 'documentation.html', title: 'Documentation' }
      ])
    })
  })
})

describe('/api/templates [not authenticated]', () => {
  beforeEach(() => {
    cy.logout()
  })

  it('retrieves a list of templates', () => {
    cy.api('/api/templates')
      .its('status').should('eq', 200)

    cy.api('/api/templates').then(({ body }) => {
      cy.wrap(body).should('be.an', 'array')
      cy.wrap(body).should('deep.include.members', [
        { name: 'documentation.html', title: 'Documentation' }
      ])
    })
  })
})

