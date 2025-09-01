// StandardJS, should-style assertions

describe('/{doc}', () => {
  it('Should retrieve matching view template', () => {
    cy.request('/test%2Forlik_to_serafin.xml')
      .its('status').should('eq', 200)

    cy.request('/test%2Forlik_to_serafin.xml').then(({ body }) => {
      const doc = new DOMParser().parseFromString(body, 'text/html')
      const meta = doc.querySelector('meta[name="description"]')
      cy.wrap(!!meta).should('eq', true)
      cy.wrap(meta.getAttribute('content')).should('eq', 'Serafin Letter')
      const pbDocument = doc.querySelector('pb-document')
      cy.wrap(!!pbDocument).should('eq', true)
      cy.wrap(pbDocument.getAttribute('path')).should('eq', 'test/orlik_to_serafin.xml')
      cy.wrap(pbDocument.getAttribute('odd')).should('eq', 'serafin')
    })
  })

  it('fails to load template for non-existing document', () => {
    cy.request({ url: '/foo.xml', failOnStatusCode: false })
      .its('status').should('eq', 404)

    cy.request({ url: '/foo.xml', failOnStatusCode: false }).then(({ body }) => {
      const doc = new DOMParser().parseFromString(body, 'text/html')
      const msg = doc.querySelector('pre.error')
      cy.wrap(msg && msg.innerHTML).should('match', /not found/)
    })
  })
})

describe('/{file}.html', () => {
  it('Should retrieve HTML file', () => {
    cy.request('/index.html')
      .its('status').should('eq', 200)

    cy.request('/index.html').then(({ body }) => {
      const doc = new DOMParser().parseFromString(body, 'text/html')
      const search = doc.querySelector('#search-form')
      cy.wrap(!!search).should('eq', true)
      cy.wrap(search.getAttribute('value') || '').should('not.include', '${query}')
    })
  })

  it('fails to load HTML file', () => {
    cy.request({ url: '/foo.html', failOnStatusCode: false })
      .its('status').should('eq', 404)

    cy.request({ url: '/foo.html', failOnStatusCode: false }).then(({ body }) => {
      const doc = new DOMParser().parseFromString(body, 'text/html')
      const msg = doc.querySelector('pre.error')
      cy.wrap(msg && msg.innerHTML).should('match', /not found/)
    })
  })
})

