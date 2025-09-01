// StandardJS, should-style assertions

describe('/api/search/autocomplete', () => {
  it('retrieves suggestions for default field', () => {
    cy.request({
      method: 'GET',
      url: '/api/search/autocomplete',
      qs: { query: 'koͤnig' }
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/search/autocomplete',
      qs: { query: 'koͤnig' }
    })
      .its('body').should('be.an', 'array')

    const konigsberg = [{ text: 'koͤnigsberg', value: 'koͤnigsberg' }]
    const bogactwa = [{ text: 'bogactwa', value: 'bogactwa' }]

    cy.request({
      method: 'GET',
      url: '/api/search/autocomplete',
      qs: { query: 'koͤnig' }
    })
      .its('body').should('deep.include.members', konigsberg)

    cy.request({
      method: 'GET',
      url: '/api/search/autocomplete',
      qs: { query: 'koͤnig' }
    })
      .its('body').should('not.deep.include.members', bogactwa)

    cy.request({
      method: 'GET',
      url: '/api/search/autocomplete',
      qs: { query: 'koͤnig' }
    })
      .then(({ body }) => {
        cy.wrap(body[0]).should('have.property', 'text')
        cy.wrap(body[0]).should('have.property', 'value')
      })
  })

  it('retrieves suggestions for author field', () => {
    cy.request({
      method: 'GET',
      url: '/api/search/autocomplete',
      qs: { query: 'k', field: 'author' }
    })
      .its('status').should('eq', 200)

    const kant = [{ text: 'kant', value: 'kant' }]
    const konigsberg = [{ text: 'koͤnigsberg', value: 'koͤnigsberg' }]
    const purchas = [{ text: 'purchas', value: 'purchas' }]

    cy.request({
      method: 'GET',
      url: '/api/search/autocomplete',
      qs: { query: 'k', field: 'author' }
    })
      .its('body').should('deep.include.members', kant)

    cy.request({
      method: 'GET',
      url: '/api/search/autocomplete',
      qs: { query: 'k', field: 'author' }
    })
      .its('body').should('not.deep.include.members', konigsberg)

    cy.request({
      method: 'GET',
      url: '/api/search/autocomplete',
      qs: { query: 'k', field: 'author' }
    })
      .its('body').should('not.deep.include.members', purchas)
  })
})

describe('/api/search', () => {
  it('runs a search', () => {
    cy.request({
      method: 'GET',
      url: '/api/search',
      qs: { query: 'power' }
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/search',
      qs: { query: 'power' }
    }).then(({ headers }) => {
      cy.wrap(headers['pb-total']).should('eq', '89')
    })
  })

  it('retrieves next page', () => {
    cy.request({
      method: 'GET',
      url: '/api/search',
      qs: { query: 'power', start: 10 }
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/search',
      qs: { query: 'power', start: 10 }
    }).then(({ headers }) => {
      cy.wrap(headers['pb-total']).should('eq', '89')
    })

    cy.request({
      method: 'GET',
      url: '/api/search',
      qs: { query: 'power', start: 10 }
    }).then(({ headers }) => {
      cy.wrap(headers['pb-start']).should('eq', '10')
    })

    cy.request({
      method: 'GET',
      url: '/api/search',
      qs: { query: 'power', start: 10 }
    })
      .its('body').should('include', '<div class="count">10</div>')
  })
})

describe.only('/api/search/facets', () => {
  let cookieHeader

  it('runs a search and retrieves facet counts for search results', () => {
    cy.api({
      method: 'GET',
      url: '/api/search',
      qs: { query: 'konwenanse' }
    })
      .its('status').should('eq', 200)

    cy.api({
      method: 'GET',
      url: '/api/search',
      qs: { query: 'konwenanse' }
    }).then(({ headers }) => {
      cy.wrap(headers['pb-total']).should('eq', '1')
    })

    cy.api({
      method: 'GET',
      url: '/api/search',
      qs: { query: 'konwenanse' }
    })
      .its('body').should('include', '<div class="count">1</div>')

    cy.api({
      method: 'GET',
      url: '/api/search',
      qs: { query: 'konwenanse' }
    }).then(({ headers }) => {
      const setCookie = headers['set-cookie']
      if (Array.isArray(setCookie) && setCookie.length) {
        // Extract only the cookie name=value pair, ignore attributes like Path, HttpOnly
        const first = setCookie[0]
        cookieHeader = first.split(';')[0]
      }
    })
  })

  it('get facets', () => {
    // Seed the session with a search so facets can read hits from session
    cy.api({ method: 'GET', url: '/api/search', qs: { query: 'konwenanse' } })
      .its('status').should('eq', 200)

    cy.api({ method: 'GET', url: '/api/search' , qs: { query: 'konwenanse' } })
      .then(({ headers }) => {
        const setCookie = headers['set-cookie']
        if (Array.isArray(setCookie) && setCookie.length) {
          cookieHeader = setCookie[0].split(';')[0]
        }
      })

    cy.api({ method: 'GET', url: '/api/search/facets', headers: cookieHeader ? { Cookie: cookieHeader } : {} })
      .its('status').should('eq', 200)

    cy.api({ method: 'GET', url: '/api/search/facets', headers: cookieHeader ? { Cookie: cookieHeader } : {} })
      .its('body').should('include', 'Spanish')
  })
})
