// StandardJS, should-style assertions

const { unzipSync, strFromU8 } = require('fflate')

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
  const boundary = '----CYPRESSFORM' + Date.now()
  const body = [
    `--${boundary}\r\n` +
    'Content-Disposition: form-data; name="files[]"; filename="title.xml"\r\n' +
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

const getPages = (u8) => {
  const files = unzipSync(u8)
  const map = {}
  Object.keys(files).forEach(k => { map[k] = strFromU8(files[k]) })
  return map
}

describe('/api/document/{document}/epub?skip-title=true', () => {
  before(() => {
    return cy.login().then(() => uploadTitle())
  })

  it('include title page', () => {
    cy.api({ method: 'GET', url: '/api/document/playground%2Ftitle.xml/epub', encoding: 'binary' })
      .its('status').should('eq', 200)

    cy.api({ method: 'GET', url: '/api/document/playground%2Ftitle.xml/epub', encoding: 'binary' })
      .then(({ body }) => {
        const u8 = new Uint8Array(Cypress.Buffer.from(body, 'binary'))
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
      .its('status').should('eq', 200)

    cy.api({ method: 'GET', url: '/api/document/playground%2Ftitle.xml/epub', qs: { 'skip-title': 'true' }, encoding: 'binary' })
      .then(({ body }) => {
        const u8 = new Uint8Array(Cypress.Buffer.from(body, 'binary'))
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
