// StandardJS, should-style assertions

const uploadFootnotes = () => {
  const xml = `
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
    <teiHeader>
        <fileDesc>
            <titleStmt>
                <title>Nested Footnotes Test</title>
            </titleStmt>
            <publicationStmt>
                <p/>
            </publicationStmt>
            <sourceDesc>
                <p/>
            </sourceDesc>
        </fileDesc>
    </teiHeader>
    <text>
        <body>
            <p>Lorem aliquip proident et amet<note>Ea cupidatat dolor cupidatat officia aliqua exercitation in 
            cillum sint esse aute et nulla aute. Culpa eiusmod cupidatat id excepteur officia aliqua velit irure 
            consequat tempor. Nisi ad reprehenderit in cupidatat labore magna in nisi velit. Enim sit fugiat 
            do ex veniam enim amet sint quis<note>Veniam eu occaecat laborum eu enim.</note>.</note>.</p>
        </body>
    </text>
  </TEI>
  `
  return cy.uploadXml('/api/upload/playground', 'footnotes.xml', xml)
}

describe('Footnotes rendering', () => {
  beforeEach(() => {
    cy.login()
  })

  it('uploads a test document to playground collection', () => {
    uploadFootnotes().then(({ status, body }) => {
      expect(status).to.eq(200)
      expect(body).to.have.length(1)
      expect(body[0].name).to.eq('/db/apps/tei-publisher/data/playground/footnotes.xml')
    })
  })

  it('checks for correct footnotes using /api/part', () => {
    cy.api({
      method: 'GET',
      url: '/api/parts/playground%2Ffootnotes.xml/json',
      qs: { view: 'single', xpath: '//body' }
    }).then(({ status, body }) => {
      cy.wrap(status).should('eq', 200)
      cy.wrap(body.footnotes).should('exist')
      cy.wrap(body.content).should('exist')

      const fnFragment = new DOMParser().parseFromString(body.footnotes, 'text/html')
      const footnotes = fnFragment.querySelectorAll('div > dl.footnote')
      cy.wrap(footnotes.length).should('eq', 2)
      cy.wrap(!!fnFragment.querySelector('div > dl.footnote a.note')).should('eq', true)
      cy.wrap(fnFragment.querySelector('dl.footnote dl.footnote')).should('eq', null)

      const fragment = new DOMParser().parseFromString(body.content, 'text/html')
      cy.wrap(fragment.querySelectorAll('pb-popover.footnote').length).should('eq', 2)
      cy.wrap(fragment.querySelector('pb-popover dl.footnote')).should('eq', null)
    })
  })

  it('checks for correct footnotes using /api/document', () => {
    cy.api('/api/document/playground%2Ffootnotes.xml/html')
      .its('status').should('eq', 200)

    cy.api('/api/document/playground%2Ffootnotes.xml/html').then(({ body }) => {
      const fragment = new DOMParser().parseFromString(body, 'text/html')
      const footnotes = fragment.querySelectorAll('.footnotes > dl.footnote')
      cy.wrap(footnotes.length).should('eq', 2)
      cy.wrap(!!fragment.querySelector('.footnotes > dl.footnote a.note')).should('eq', true)
      cy.wrap(fragment.querySelector('dl.footnote dl.footnote')).should('eq', null)
    })
  })

  it('deletes the uploaded document', () => {
    cy.api({ method: 'DELETE', url: '/api/document/playground%2Ffootnotes.xml', failOnStatusCode: false })
      .its('status').should('eq', 204)
  })
})
