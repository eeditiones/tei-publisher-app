// StandardJS, should-style assertions

describe('/api/document/{id}', () => {
  it('retrieves as xml', () => {
    cy.request('/api/document/test%2Fgraves6.xml')
      .its('status').should('eq', 200)

    cy.request('/api/document/test%2Fgraves6.xml')
      .its('headers["content-type"]').should('include', 'application/xml')

    cy.request('/api/document/test%2Fgraves6.xml')
      .its('body').should('include', '<date when="1957-11-15">November 15, 1957</date>')
  })

  it('retrieves as markdown', () => {
    cy.request('/api/document/about.md')
      .its('status').should('eq', 200)

    cy.request('/api/document/about.md')
      .its('headers["content-type"]').should('include', 'text/markdown')

    cy.request('/api/document/about.md')
      .its('body').should('include', '# Markdown')
  })
})

describe('/api/document/{id}/html', () => {
  it('retrieves as html', () => {
    cy.request({
      method: 'GET',
      url: '/api/document/test%2Fcortes_to_dantiscus.xml/html',
      qs: { base: 'http://foo.com' }
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/document/test%2Fcortes_to_dantiscus.xml/html',
      qs: { base: 'http://foo.com' }
    })
      .its('body').should('include', '<title')

    cy.request({
      method: 'GET',
      url: '/api/document/test%2Fcortes_to_dantiscus.xml/html',
      qs: { base: 'http://foo.com' }
    })
      .its('body').should('include', 'base href="http://foo.com"')
  })

  it('retrieves part identified by xml:id as html', () => {
    cy.request({
      method: 'GET',
      url: '/api/document/doc%2Fdocumentation.xml/html',
      qs: { id: 'unix-installation' }
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/document/doc%2Fdocumentation.xml/html',
      qs: { id: 'unix-installation' }
    })
      .its('body').should('match', /Unix installation/)
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
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/document/test%2Forlik_to_serafin.xml/print',
      qs: {
        odd: 'serafin.odd',
        base: '%2Fexist%2Fapps%2Ftei-publisher%2Ftest',
        style: ['resources%2Ffonts%2Ffont.css', 'resources%2Fcss%2Fprint.css']
      }
    })
      .its('body').should(($html) => {
        // allow additional classes before/after doc-title
        expect(/class="[^"]*\bdoc-title\b[^"]*"/.test($html)).to.be.true
      })

    cy.request({
      method: 'GET',
      url: '/api/document/test%2Forlik_to_serafin.xml/print',
      qs: {
        odd: 'serafin.odd',
        base: '%2Fexist%2Fapps%2Ftei-publisher%2Ftest',
        style: ['resources%2Ffonts%2Ffont.css', 'resources%2Fcss%2Fprint.css']
      }
    })
      .its('body').should('include', 'class="register"')
  })
})

describe.skip('/api/document/{id}/tex', () => {
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
    })
      .its('headers["content-type"]').should('include', 'application/x-latex')
  })
  after(() => {
    cy.logout()
  })
})

// Skipped: PDF endpoints migrated but not enabled
describe.skip('/api/document/{id}/pdf', () => {
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
    cy.request({
      method: 'GET',
      url: '/api/document/test%2Fcortes_to_dantiscus.xml/epub',
      qs: { token },
      encoding: 'binary'
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/document/test%2Fcortes_to_dantiscus.xml/epub',
      qs: { token },
      encoding: 'binary'
    })
      .its('headers["content-type"]').should('include', 'application/epub+zip')

    cy.request({
      method: 'GET',
      url: '/api/document/test%2Fcortes_to_dantiscus.xml/epub',
      qs: { token },
      encoding: 'binary'
    })
      .then(({ headers, body }) => {
        cy.wrap(headers['set-cookie']).should('include', `simple.token=${token}`)
        cy.wrap(body.length).should('be.gt', 0)
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
    cy.request({
      method: 'GET',
      url: '/api/document/doc%2Fdocumentation.xml/contents',
      qs: { view: 'div' }
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/document/doc%2Fdocumentation.xml/contents',
      qs: { view: 'div' }
    })
      .its('body').should('match', /<pb-link.*>Introduction<\/pb-link>/)
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
    cy.request({
      method: 'GET',
      url: '/api/parts/test%2Fcortes_to_dantiscus.xml/json',
      qs: { view: 'div' }
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/parts/test%2Fcortes_to_dantiscus.xml/json',
      qs: { view: 'div' }
    })
      .its('body.odd').should('eq', 'dantiscus.odd')
  })

  it('retrieves part identified by xpath as json', () => {
    cy.request({
      method: 'GET',
      url: '/api/parts/test%2Fcortes_to_dantiscus.xml/json',
      qs: { view: 'single', xpath: '//front' }
    })
      .its('status').should('eq', 200)

    cy.request({
      method: 'GET',
      url: '/api/parts/test%2Fcortes_to_dantiscus.xml/json',
      qs: { view: 'single', xpath: '//front' }
    })
      .its('body.doc').should('eq', 'cortes_to_dantiscus.xml')

    cy.request({
      method: 'GET',
      url: '/api/parts/test%2Fcortes_to_dantiscus.xml/json',
      qs: { view: 'single', xpath: '//front' }
    })
      .its('body.content').should('match', /<front .*>/)
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
