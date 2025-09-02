// StandardJS, should-style assertions

describe('/api/search/autocomplete', () => {
  it('retrieves suggestions for default field', () => {
    const konigsberg = [{ text: 'koͤnigsberg', value: 'koͤnigsberg' }]
    const bogactwa = [{ text: 'bogactwa', value: 'bogactwa' }]
    cy.request({ method: 'GET', url: '/api/search/autocomplete', qs: { query: 'koͤnig' } }).then(({ status, body }) => {
      expect(status).to.eq(200)
      expect(body).to.be.an('array')
      expect(body).to.deep.include.members(konigsberg)
      expect(body).to.not.deep.include.members(bogactwa)
      expect(body[0]).to.have.property('text')
      expect(body[0]).to.have.property('value')
    })
  })

  it('retrieves suggestions for author field', () => {
    const kant = [{ text: 'kant', value: 'kant' }]
    const konigsberg = [{ text: 'koͤnigsberg', value: 'koͤnigsberg' }]
    const purchas = [{ text: 'purchas', value: 'purchas' }]
    cy.request({ method: 'GET', url: '/api/search/autocomplete', qs: { query: 'k', field: 'author' } }).then(({ status, body }) => {
      expect(status).to.eq(200)
      expect(body).to.deep.include.members(kant)
      expect(body).to.not.deep.include.members(konigsberg)
      expect(body).to.not.deep.include.members(purchas)
    })
  })
})

describe('/api/search', () => {
  it('runs a search', () => {
    cy.request({ method: 'GET', url: '/api/search', qs: { query: 'power' } }).then(({ status, headers }) => {
      expect(status).to.eq(200)
      expect(headers['pb-total']).to.eq('89')
    })
  })

  it('retrieves next page', () => {
    cy.request({ method: 'GET', url: '/api/search', qs: { query: 'power', start: 10 } }).then(({ status, headers, body }) => {
      expect(status).to.eq(200)
      expect(headers['pb-total']).to.eq('89')
      expect(headers['pb-start']).to.eq('10')
      expect(body).to.include('<div class="count">10</div>')
    })
  })
})

describe('/api/search/facets', () => {
  let cookieHeader

  it('runs a search and retrieves facet counts for search results', () => {
    cy.api({ method: 'GET', url: '/api/search', qs: { query: 'konwenanse' } }).then(({ status, headers, body }) => {
      expect(status).to.eq(200)
      expect(headers['pb-total']).to.eq('1')
      expect(body).to.include('<div class="count">1</div>')
      const setCookie = headers['set-cookie']
      if (Array.isArray(setCookie) && setCookie.length) {
        cookieHeader = setCookie[0].split(';')[0]
      }
    })
  })

  it('get facets', () => {
    // Seed the session with a search so facets can read hits from session
    cy.api({ method: 'GET', url: '/api/search', qs: { query: 'konwenanse' } })
      .then(({ headers }) => {
        const setCookie = headers['set-cookie']
        if (Array.isArray(setCookie) && setCookie.length) {
          const first = setCookie[0].split(';')[0]
          const idx = first.indexOf('=')
          const name = first.substring(0, idx)
          const value = first.substring(idx + 1)
          cy.setCookie(name, value)
        }
      })
      .then(() => cy.api({ method: 'GET', url: '/api/search/facets' }))
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        expect(body).to.include('Spanish')
      })
  })
})
