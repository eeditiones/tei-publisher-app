// StandardJS, should-style assertions

describe('/api/document/{id}', () => {
  it('retrieves as xml', () => {
    cy.request('/api/document/test%2Fgraves6.xml').then(({ status, headers, body }) => {
      expect(status).to.eq(200)
      expect(headers['content-type']).to.eq('application/xml')
      expect(body).to.include('<date when="1957-11-15">November 15, 1957</date>')
    })
  })

  it('retrieves as markdown', () => {
    cy.request('/api/document/about.md').then(({ status, headers, body }) => {
      expect(status).to.eq(200)
      expect(headers['content-type']).to.eq('text/markdown')
      expect(body).to.include('# Markdown')
    })
  })
})

describe('/api/document/{id}/html', () => {
  it('retrieves as html', () => {
    cy.request({ method: 'GET', url: '/api/document/test%2Fcortes_to_dantiscus.xml/html', qs: { base: 'http://foo.com' } })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        expect(body).to.include('<title')
        expect(body).to.include('base href="http://foo.com"')
      })
  })

  it('retrieves part identified by xml:id as html', () => {
    cy.request({ method: 'GET', url: '/api/document/doc%2Fdocumentation.xml/html', qs: { id: 'unix-installation' } })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        expect(body).to.match(/Unix installation/)
      })
  })

  it('tries to retrieve non-existing document', () => {
    cy.request({
      method: 'GET',
      url: '/api/document/foo%2Fbaz.xml/html',
      failOnStatusCode: false
    })
      .its('status').should('eq', 404)
  })
})

describe('/api/document/{id}/print', () => {
  it('retrieves as HTML optimized for print', () => {
    cy.request({
      method: 'GET',
      url: '/api/document/test%2Forlik_to_serafin.xml/print',
      qs: {
        odd: 'serafin.odd',
        base: '%2Fexist%2Fapps%2Ftei-publisher%2Ftest',
        style: ['resources%2Ffonts%2Ffont.css', 'resources%2Fcss%2Fprint.css']
      }
    }).then(({ status, body }) => {
      expect(status).to.eq(200)
      // allow additional classes before/after doc-title
      expect(/class="[^"]*\bdoc-title\b[^"]*"/.test(body)).to.be.true
      expect(body).to.include('class="register"')
    })
  })
})

describe('/api/document/{id}/tex', () => {
  beforeEach(() => {
    // Some setups require authentication to access LaTeX transformation
    cy.login()
  })
  it('retrieves as LaTeX', () => {
    cy.api({
      method: 'GET',
      url: '/api/document/test%2Fcortes_to_dantiscus.xml/tex',
      qs: { source: 'true' },
      headers: { Accept: 'application/x-latex' }
    })
      .its('status').should('eq', 200)

    cy.api({
      method: 'GET',
      url: '/api/document/test%2Fcortes_to_dantiscus.xml/tex',
      qs: { source: 'true' },
      headers: { Accept: 'application/x-latex' }
    }).then(({ headers }) => {
      expect(headers['content-type']).to.eq('application/x-latex')
    })
  })
  after(() => {
    cy.logout()
  })
})

describe('/api/document/{id}/pdf', () => {
  it('retrieves as PDF transformed via FO', () => {
    const token = new Date().toISOString()
    cy.request({
      method: 'GET',
      url: '/api/document/test%2Fgraves6.xml/pdf',
      qs: { token },
      encoding: 'binary'
    }).then(({ status, headers, body }) => {
      expect(status).to.eq(200)
      expect(headers['content-type']).to.include('media-type=application/pdf')
      expect(headers['set-cookie']).to.include(`simple.token=${token}`)
      expect((body || '').length).to.be.gt(0)
    })
  })

  it('retrieves FO output', () => {
    cy.request({
      method: 'GET',
      url: '/api/document/test%2Fgraves6.xml/pdf',
      qs: { source: true }
    }).then(({ status, headers }) => {
      expect(status).to.eq(200)
      expect(headers['content-type']).to.include('application/xml')
    })
  })
})

describe('/api/document/{id}/epub', () => {
  it('retrieves as EPub', () => {
    const token = new Date().toISOString()
    cy.request({ method: 'GET', url: '/api/document/test%2Fcortes_to_dantiscus.xml/epub', qs: { token }, encoding: 'binary' })
      .then(({ status, headers, body }) => {
        expect(status).to.eq(200)
        expect(headers['content-type']).to.eq('application/epub+zip')
        expect(headers['set-cookie']).to.include(`simple.token=${token}`)
        expect((body || '').length).to.be.gt(0)
      })
  })

  it('tries to retrieve non-existing document', () => {
    cy.request({
      method: 'GET',
      url: '/api/document/foo%2Fbaz.xml/epub',
      failOnStatusCode: false
    })
      .its('status').should('eq', 404)
  })
})

describe('/api/document/{id}/contents', () => {
  it('retrieves table of content', () => {
    cy.request({ method: 'GET', url: '/api/document/doc%2Fdocumentation.xml/contents', qs: { view: 'div' } })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        expect(body).to.match(/<pb-link.*>Introduction<\/pb-link>/)
      })
  })

  it('tries to get toc of non-existing document', () => {
    cy.request({
      method: 'GET',
      url: '/api/document/foo%2Fbaz.xml/contents',
      failOnStatusCode: false
    })
      .its('status').should('eq', 404)
  })
})

describe('/api/parts/{id}/json', () => {
  it('retrieves document part as json', () => {
    cy.request({ method: 'GET', url: '/api/parts/test%2Fcortes_to_dantiscus.xml/json', qs: { view: 'div' } })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        expect(body.odd).to.eq('dantiscus.odd')
      })
  })

  it('retrieves part identified by xpath as json', () => {
    cy.request({ method: 'GET', url: '/api/parts/test%2Fcortes_to_dantiscus.xml/json', qs: { view: 'single', xpath: '//front' } })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        expect(body.doc).to.eq('cortes_to_dantiscus.xml')
        expect(body.content).to.match(/<front .*>/)
      })
  })

  it('tries to retrieve non-existing document', () => {
    cy.request({
      method: 'GET',
      url: '/api/parts/foo%2Fbaz.xml/json',
      failOnStatusCode: false
    })
      .its('status').should('eq', 404)
  })
})
