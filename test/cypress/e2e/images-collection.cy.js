// StandardJS, should-style assertions

const { unzipSync } = require('fflate')

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
  const boundary = '----CYPRESSFORM' + Date.now()
  const body = [
    `--${boundary}\r\n` +
    'Content-Disposition: form-data; name="files[]"; filename="images.xml"\r\n' +
    'Content-Type: application/xml\r\n\r\n' +
    xml + '\r\n' +
    `--${boundary}--\r\n`
  ].join('')
  return cy.api({ method: 'POST', url: '/api/upload/playground', headers: { 'Content-Type': `multipart/form-data; boundary=${boundary}`, Accept: 'application/json' }, body })
}

const containsEntry = (u8, name) => {
  const files = unzipSync(u8)
  return Object.prototype.hasOwnProperty.call(files, name)
}

describe('/api/document/{document}/epub?images-collection', () => {
  before(() => {
    return cy.login().then(() => uploadImagesDoc())
  })

  it('let tei-publisher determine images collection', () => {
    cy.api({ method: 'GET', url: '/api/document/playground%2Fimages.xml/epub', encoding: 'binary' })
      .its('status').should('eq', 200)

    cy.api({ method: 'GET', url: '/api/document/playground%2Fimages.xml/epub', encoding: 'binary' })
      .then(({ body }) => {
        const u8 = new Uint8Array(Cypress.Buffer.from(body, 'binary'))
        cy.wrap(containsEntry(u8, 'OEBPS/demo.png')).should('eq', false)
      })
  })

  it('define images collection', () => {
    cy.api({ method: 'GET', url: '/api/document/playground%2Fimages.xml/epub', qs: { 'images-collection': '/db/apps/tei-publisher/data' }, encoding: 'binary' })
      .its('status').should('eq', 200)

    cy.api({ method: 'GET', url: '/api/document/playground%2Fimages.xml/epub', qs: { 'images-collection': '/db/apps/tei-publisher/data' }, encoding: 'binary' })
      .then(({ body }) => {
        const u8 = new Uint8Array(Cypress.Buffer.from(body, 'binary'))
        cy.wrap(containsEntry(u8, 'OEBPS/demo.png')).should('eq', true)
      })
  })
})
