// StandardJS, should-style assertions
const { toU8, names, readEntry } = require('../support/zip')

// Upload via fixtures using cy.request (multipart for XML, REST PUT for image)
const uploadCoverDoc = () => {
  // Upload XML via multipart/form-data (fixture-based)
  const uploadXml = () => cy.fixture('cover.xml', 'utf8').then(xml => {
    const boundary = '----CYPRESSFORM' + Date.now()
    const body = [
      `--${boundary}\r\n` +
      'Content-Disposition: form-data; name="files[]"; filename="cover.xml"\r\n' +
      'Content-Type: application/xml\r\n\r\n' +
      xml + '\r\n' +
      `--${boundary}--\r\n`
    ].join('')
    return cy.api({
      method: 'POST',
      url: '/api/upload/playground',
      headers: { 'Content-Type': `multipart/form-data; boundary=${boundary}`, Accept: 'application/json' },
      body
    }).then(({ status, body }) => {
      cy.wrap(status).should('eq', 200)
      cy.wrap(body).should('have.length', 1)
      cy.wrap(body[0].name).should('eq', '/db/apps/tei-publisher/data/playground/cover.xml')
    })
  })

  // Upload image via REST PUT to the same collection
  const uploadJpg = () => cy.fixture('book.jpg', 'binary').then(bin => {
    const buf = Cypress.Buffer.from(bin, 'binary')
    return cy.request({
      method: 'PUT',
      url: 'http://localhost:8080/exist/rest/db/apps/tei-publisher/data/playground/book.jpg',
      body: buf,
      headers: { 'Content-Type': 'image/jpeg' },
      auth: { user: 'tei', pass: 'simple' },
      log: false
    }).then(({ status }) => {
      cy.wrap([200, 201, 204]).should('include', status)
    })
  })

  return uploadXml().then(() => uploadJpg())
}

const filterEntries = (u8, wanted) => {
  const all = names(u8)
  return wanted.filter(n => all.includes(n))
}

describe('/api/document/{document}/epub?cover-image', () => {
  before(() => {
    return cy.login().then(() => uploadCoverDoc())
  })

  it('creating an epub without a cover image', () => {
    cy.api({ method: 'GET', url: '/api/document/playground%2Fcover.xml/epub', encoding: 'binary' })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        const u8 = toU8(body)
        const found = filterEntries(u8, ['OEBPS/content.opf', 'OEBPS/book.jpg'])
        expect(found.length).to.eq(1)
        expect(found).to.include('OEBPS/content.opf')
      })
  })

  it('defining a cover image for the epub', () => {
    cy.api({ method: 'GET', url: '/api/document/playground%2Fcover.xml/epub', qs: { 'cover-image': 'book.jpg' }, encoding: 'binary' })
      .then(({ status, body }) => {
        expect(status).to.eq(200)
        const u8 = toU8(body)
        const found = filterEntries(u8, ['OEBPS/content.opf', 'OEBPS/book.jpg'])
        expect(found.length).to.eq(2)
        const content = new DOMParser().parseFromString(readEntry(u8, 'OEBPS/content.opf'), 'application/xml')
        expect(!!content.querySelector('metadata meta[name="cover"][content="book.jpg"]')).to.eq(true)
        const manifestItem = content.querySelector('manifest item[id="book.jpg"]')
        expect(manifestItem && manifestItem.getAttribute('properties')).to.eq('cover-image')
      })
  })

  after(() => {
    cy.logout()
  })
})
