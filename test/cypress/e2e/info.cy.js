// StandardJS, should-style assertions

describe('/api/version', () => {
  it('queries version information', () => {
    cy.api('/api/version')
      .its('status').should('eq', 200)

    cy.api('/api/version').then(({ body }) => {
      cy.wrap(body).should('have.property', 'api')
      cy.wrap(body).should('have.property', 'app')
      cy.wrap(body.app && body.app.name).should('eq', 'tei-publisher')
    })
  })
})

