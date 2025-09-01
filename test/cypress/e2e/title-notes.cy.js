// StandardJS, should-style assertions

const { unzipSync, strFromU8 } = require('fflate')

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
  const boundary = '----CYPRESSFORM' + Date.now()
  const body = [
    `--${boundary}\r\n` +
    'Content-Disposition: form-data; name="files[]"; filename="title-notes.xml"\r\n' +
    'Content-Type: application/xml\r\n\r\n' +
    xml + '\r\n' +
    `--${boundary}--\r\n`
  ].join('')
  return cy.api({
    method: 'POST', url: '/api/upload/playground',
    headers: { 'Content-Type': `multipart/form-data; boundary=${boundary}`, Accept: 'application/json' },
    body
  })
}

const readEntry = (u8, name) => {
  const files = unzipSync(u8)
  return files[name] ? strFromU8(files[name]) : undefined
}

describe('Notes in document title', () => {
  before(() => {
    return cy.login().then(() => uploadTitleNotes())
  })

  it('notes in document title should not appear in navigation entry', () => {
    cy.api({ method: 'GET', url: '/api/document/playground%2Ftitle-notes.xml/epub', encoding: 'binary' })
      .its('status').should('eq', 200)

    cy.api({ method: 'GET', url: '/api/document/playground%2Ftitle-notes.xml/epub', encoding: 'binary' })
      .then(({ body }) => {
        const u8 = new Uint8Array(Cypress.Buffer.from(body, 'binary'))
        const nav = readEntry(u8, 'OEBPS/nav.xhtml')
        const doc = new DOMParser().parseFromString(nav, 'application/xhtml+xml')
        const navLabel = doc.querySelector('nav ol li a')
        cy.wrap(navLabel && navLabel.textContent).should('not.include', 'note')
      })
  })
})
