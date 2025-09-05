// StandardJS, should-style assertions

const { toU8, readEntry } = require('../support/zip')

const uploadTitleNotes = () => {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
  <TEI xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader>
    <fileDesc>
      <titleStmt>
        <title>EPUB title notes Test</title>
      </titleStmt>
      <publicationStmt><p/></publicationStmt>
      <sourceDesc><p/></sourceDesc>
    </fileDesc>
  </teiHeader>
  <text><body>
    <div type="document" n="1" xml:id="d1" subtype="document">
      <head>Document 1<note n="1" xml:id="d1fn1" type="source">note</note></head>
      <p>Document 1 body</p>
    </div>
  </body></text>
  </TEI>`
  return cy.uploadXml('/api/upload/playground', 'title-notes.xml', xml)
}


describe('Notes in document title', () => {
  before(() => {
    return cy.login().then(() => uploadTitleNotes())
  })

  it('notes in document title should not appear in navigation entry', () => {
    cy.api({ method: 'GET', url: '/api/document/playground%2Ftitle-notes.xml/epub', encoding: 'binary' })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        const u8 = toU8(body)
        const nav = readEntry(u8, 'OEBPS/nav.xhtml')
        const doc = new DOMParser().parseFromString(nav, 'application/xhtml+xml')
        const navLabel = doc.querySelector('nav ol li a')
        cy.wrap(navLabel && navLabel.textContent).should('not.include', 'note')
      })
  })
})
