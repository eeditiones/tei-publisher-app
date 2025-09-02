// StandardJS, should-style assertions

const { toU8, containsEntry } = require('../support/zip')

const uploadImagesDoc = () => {
  const xml = `<?xml version="1.0" encoding="UTF-8"?>
  <TEI xmlns="http://www.tei-c.org/ns/1.0">
  <teiHeader>
    <fileDesc>
      <titleStmt><title>EPUB Images Collection Test</title></titleStmt>
      <publicationStmt><p/></publicationStmt>
      <sourceDesc><p/></sourceDesc>
    </fileDesc>
  </teiHeader>
  <text><body>
    <div type="document" n="1" xml:id="d1" subtype="document">
      <head>Document 1</head>
      <graphic url="demo.png" />
    </div>
  </body></text>
  </TEI>`
  return cy.uploadXml('/api/upload/playground', 'images.xml', xml)
}


describe('/api/document/{document}/epub?images-collection', () => {
  before(() => {
    return cy.login().then(() => uploadImagesDoc())
  })

  it('let tei-publisher determine images collection', () => {
    cy.api({ method: 'GET', url: '/api/document/playground%2Fimages.xml/epub', encoding: 'binary' })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        const u8 = toU8(body)
        cy.wrap(containsEntry(u8, 'OEBPS/demo.png')).should('eq', false)
      })
  })

  it('define images collection', () => {
    cy.api({ method: 'GET', url: '/api/document/playground%2Fimages.xml/epub', qs: { 'images-collection': '/db/apps/tei-publisher/data' }, encoding: 'binary' })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        const u8 = toU8(body)
        cy.wrap(containsEntry(u8, 'OEBPS/demo.png')).should('eq', true)
      })
  })
})
