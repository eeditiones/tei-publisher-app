// StandardJS, should-style assertions

const { toU8, toTextMap } = require('../support/zip')

const uploadTitle = () => {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
  <TEI xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader>
    <fileDesc>
      <titleStmt>
        <title>EPUB Title Test</title>
      </titleStmt>
      <publicationStmt><p/></publicationStmt>
      <sourceDesc><p/></sourceDesc>
    </fileDesc>
  </teiHeader>
  <text><body>
    <div type="document" n="1" xml:id="d1" subtype="document"><head>Document</head></div>
  </body></text>
  </TEI>`
  return cy.uploadXml('/api/upload/playground', 'title.xml', xml)
}

const getPages = (u8) => toTextMap(u8)

describe('/api/document/{document}/epub?skip-title=true', () => {
  before(() => {
    return cy.login().then(() => uploadTitle())
  })

  it('include title page', () => {
    cy.api({ method: 'GET', url: '/api/document/playground%2Ftitle.xml/epub', encoding: 'binary' })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        const u8 = toU8(body)
        const pages = getPages(u8)
        cy.wrap(Object.keys(pages)).should('include.members', ['OEBPS/content.opf', 'OEBPS/toc.ncx', 'OEBPS/title.xhtml'])
        const content = new DOMParser().parseFromString(pages['OEBPS/content.opf'], 'application/xml')
        cy.wrap(!!content.querySelector('manifest item#title')).should('eq', true)
        cy.wrap(!!content.querySelector('spine itemref[idref="title"]')).should('eq', true)
        const toc = new DOMParser().parseFromString(pages['OEBPS/toc.ncx'], 'application/xml')
        cy.wrap(!!toc.querySelector('navMap navPoint#navpoint-title')).should('eq', true)
      })
  })

  it('exclude title page', () => {
    cy.api({ method: 'GET', url: '/api/document/playground%2Ftitle.xml/epub', qs: { 'skip-title': 'true' }, encoding: 'binary' })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        const u8 = toU8(body)
        const pages = getPages(u8)
        cy.wrap(pages['OEBPS/title.xhtml']).should('be.undefined')
        const content = new DOMParser().parseFromString(pages['OEBPS/content.opf'], 'application/xml')
        cy.wrap(!!content.querySelector('manifest item#title')).should('eq', false)
        cy.wrap(!!content.querySelector('spine itemref[idref="title"]')).should('eq', false)
        const toc = new DOMParser().parseFromString(pages['OEBPS/toc.ncx'], 'application/xml')
        cy.wrap(!!toc.querySelector('navMap navPoint#navpoint-title')).should('eq', false)
      })
  })
})
