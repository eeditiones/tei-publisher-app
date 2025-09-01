// StandardJS, should-style assertions

describe('/api/odd/{odd} [authenticated]', () => {
  beforeEach(() => {
    cy.login()
  })

  it('creates new odd', () => {
    cy.getCookies().then(cookies => {
      const cookieHeader = cookies.map(c => `${c.name}=${c.value}`).join('; ')
      cy.api({
        method: 'POST',
        url: '/api/odd/testme',
        qs: { title: 'My test' },
        headers: { Cookie: cookieHeader }
      })
        .its('status').should('eq', 201)

      cy.api({
        method: 'POST',
        url: '/api/odd/testme',
        qs: { title: 'My test' },
        headers: { Cookie: cookieHeader }
      })
        .its('body.path').should('eq', '/db/apps/tei-publisher/odd/testme.odd')
    })
  })

  it('retrieves odd as xml', () => {
    cy.request({
      method: 'GET',
      url: '/api/odd/testme.odd',
      headers: { Accept: 'application/xml' }
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/odd/testme.odd',
      headers: { Accept: 'application/xml' }
    })
      .its('body').should('match', /schemaSpec/)
  })

  it('loads odd as json', () => {
    cy.request({
      method: 'GET',
      url: '/api/odd/testme.odd',
      headers: { Accept: 'application/json' }
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/odd/testme.odd',
      headers: { Accept: 'application/json' }
    })
      .its('headers["content-type"]').should('include', 'application/json')

    cy.request({
      method: 'GET',
      url: '/api/odd/testme.odd',
      headers: { Accept: 'application/json' }
    })
      .its('body.title').should('eq', 'My test')
  })

  it('loads elementSpec as json', () => {
    cy.request({
      method: 'GET',
      url: '/api/odd/docbook.odd',
      qs: { ident: 'code' }
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/odd/docbook.odd',
      qs: { ident: 'code' }
    })
      .its('headers["content-type"]').should('include', 'application/json')

    cy.request({
      method: 'GET',
      url: '/api/odd/docbook.odd',
      qs: { ident: 'code' }
    })
      .its('body.status').should('eq', 'found')

    cy.request({
      method: 'GET',
      url: '/api/odd/docbook.odd',
      qs: { ident: 'code' }
    })
      .its('body.models.length').should('be.gte', 1)
  })

  it('deletes odd', () => {
    cy.getCookies().then(cookies => {
      const cookieHeader = cookies.map(c => `${c.name}=${c.value}`).join('; ')
      cy.api({
        method: 'DELETE',
        url: '/api/odd/testme.odd',
        headers: { Cookie: cookieHeader },
        failOnStatusCode: false
      })
        .its('status').should('eq', 410)
    })
  })

  after(() => {
    cy.logout()
  })
})

describe('/api/odd/{odd} [not authenticated]', () => {
  before(() => {
    cy.logout()
  })

  it('tries to delete odd', () => {
    cy.request({
      method: 'DELETE',
      url: '/api/odd/teipublisher.odd',
      failOnStatusCode: false
    })
      .its('status').should('eq', 401)
  })

  it('tries to create new odd', () => {
    cy.request({
      method: 'POST',
      url: '/api/odd/testme',
      qs: { title: 'My test' },
      failOnStatusCode: false
    })
      .its('status').should('eq', 401)
  })
})

describe('/api/odd [authenticated]', () => {
  beforeEach(() => {
    cy.login()
  })

  it('retrieves a list of odds', () => {
    cy.request('/api/odd')
      .its('status').should('eq', 200)

    cy.request('/api/odd')
      .its('body').should('be.an', 'array')

    const publisherOdd = [{
      path: '/db/apps/tei-publisher/odd/teipublisher.odd',
      name: 'teipublisher',
      canWrite: true,
      label: 'TEI Publisher Base',
      description: 'Base ODD from which all other ODDs inherit'
    }]

    cy.request('/api/odd')
      .its('body').should('deep.include.members', publisherOdd)

    cy.request('/api/odd')
      .then(({ body }) => {
        cy.wrap(body[1]).should('have.property', 'name')
        cy.wrap(body[1]).should('have.property', 'path')
      })
  })

  it('regenerates dta odd', () => {
    cy.getCookies().then(cookies => {
      const cookieHeader = cookies.map(c => `${c.name}=${c.value}`).join('; ')
      cy.api({
        method: 'POST',
        url: '/api/odd',
        qs: { odd: 'dta.odd', check: true },
        headers: { Cookie: cookieHeader }
      }).then(({ status, body }) => {
        cy.wrap(status).should('eq', 200)
        cy.wrap(body)
          .should('include', 'dta-web.xql: OK')
          .and('include', 'dta-print.xql: OK')
          .and('include', 'dta-latex.xql: OK')
          .and('include', 'dta-epub.xql: OK')
          .and('not.include', 'teipublisher-web.xql: OK')
          .and('not.include', 'Error for output mode')
      })
    })
  })

  after(() => {
    cy.logout()
  })
})

describe('/api/odd [not authenticated]', () => {
  it('tries to regenerate dta odd without authorization', () => {
    cy.request({
      method: 'POST',
      url: '/api/odd',
      qs: { odd: 'dta.odd', check: true },
      failOnStatusCode: false
    })
      .its('status').should('eq', 401)
  })
})
