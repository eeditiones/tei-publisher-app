// StandardJS, should-style assertions

const uploadAnnotations = () => {
  return cy.fixture('annotations.xml', 'utf8').then(xml => {
    return cy.uploadXml('/api/upload/annotate', 'annotations.xml', xml)
      .then(({ status, body }) => {
        cy.wrap(status).should('eq', 200)
        cy.wrap(body).should('have.length', 1)
        cy.wrap(body[0].name).should('eq', '/db/apps/tei-publisher/data/annotate/annotations.xml')
      })
  })
}

const assertAnnotate = (payload, paraIndex, expectedXml) => {
  return cy.request({
    method: 'POST',
    url: '/api/annotations/merge/annotate%2Fannotations.xml',
    headers: { 'Content-Type': 'application/json' },
    body: payload
  }).then(({ status, body }) => {
    cy.wrap(status).should('eq', 200)
    cy.wrap(body.changes).should('have.length', 1)
    const doc = new DOMParser().parseFromString(body.content, 'application/xml')
    const para = selectPara(doc, paraIndex)
    const xml = new XMLSerializer().serializeToString(para)
    cy.wrap(xml).should('equal', expectedXml)
  })
}

const selectPara = (doc, idx) => {
  const xpath = `//*[local-name()='body']/*[local-name()='p'][${idx}]`
  const res = doc.evaluate(xpath, doc, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null)
  return res.singleNodeValue
}

describe('/api/annotations/merge', () => {
  // Upload once; login before each test for a fresh session
  before(() => {
    return cy.login().then(() => uploadAnnotations())
  })
  beforeEach(() => {
    cy.login()
  })

  it('deletes at start and wraps', () => {
    assertAnnotate({
      annotations: [
        { type: 'delete', node: '1.4.2.2.2', context: '1.4.2.2' },
        { context: '1.4.2.2', start: 1, end: 9, text: 'Gauger I', type: 'hi', properties: {} },
        { context: '1.4.2.2', start: 11, end: 14, text: '113', type: 'hi', properties: {} },
        { context: '1.4.2.2', start: 1, end: 13, text: 'Gauger I, 113', type: 'link', properties: { target: '#foo' } }
      ]
    }, 1, '<p xmlns="http://www.tei-c.org/ns/1.0">(<ref target="#foo"><hi>Gauger I</hi>, <hi>113</hi></ref>).</p>')
  })

  it('deletes at end and wraps', () => {
    assertAnnotate({
      annotations: [
        { type: 'delete', node: '1.4.2.4.2', context: '1.4.2.4' },
        { context: '1.4.2.4', start: 1, end: 4, text: '113', type: 'hi', properties: {} },
        { context: '1.4.2.4', start: 6, end: 14, text: 'Gauger I', type: 'hi', properties: {} },
        { context: '1.4.2.4', start: 1, end: 13, text: '113, Gauger I', type: 'link', properties: { target: '#foo' } }
      ]
    }, 2, '<p xmlns="http://www.tei-c.org/ns/1.0">(<ref target="#foo"><hi>113</hi>, <hi>Gauger I</hi></ref>).</p>')
  })

  it('annotate after nested note', () => {
    assertAnnotate({
      annotations: [
        { context: '1.4.2.8', start: 20, end: 39, text: 'Opuscula theologica', type: 'hi', properties: {} }
      ]
    }, 4, '<p xmlns="http://www.tei-c.org/ns/1.0"><ref target="#">Starb am<note place="footnote">Fehlt.</note></ref>. Sammlung: <hi>Opuscula theologica</hi>.</p>')
  })

  it('wrap to end of paragraph', () => {
    assertAnnotate({
      annotations: [
        { context: '1.4.2.16', start: 210, end: 308, text: 'S. Werenfels, Fasciculus Epigrammatum, in: ders., Opuscula III (Anm. 20), S. 337–428, dort S. 384:', type: 'link', properties: { target: '#foo' } }
      ]
    }, 8, '<p xmlns="http://www.tei-c.org/ns/1.0">Bei <persName type="author" ref="kbga-actors-8470">Budé</persName> (Anm. 21), S. 56f.59, finden sich zwei Briefe von Fontenelle an Turettini, in denen <persName ref="kbga-actors-8482">Fontenelle</persName> sich lobend über <persName ref="kbga-actors-1319">Werenfels</persName> äußert. Den erwähnten Dank formulierte <persName ref="kbga-actors-1319">Werenfels</persName> in Form eines Epigramms; vgl. <ref target="#foo"><persName type="author" ref="kbga-actors-1319">S. Werenfels</persName>, <hi rend="i">Fasciculus Epigrammatum</hi>, in: ders., <hi rend="i">Opuscula</hi> III (Anm. 20), S. 337–428, dort S. 384:</ref></p>')
  })

  it('annotate after nested choice', () => {
    assertAnnotate({
      annotations: [
        { context: '1.4.2.10', start: 9, end: 28, text: 'Opuscula theologica', type: 'hi', properties: {} }
      ]
    }, 5, '<p xmlns="http://www.tei-c.org/ns/1.0"><hi>Zum <choice><abbr>Bsp.</abbr><expan>Beispiel</expan></choice></hi> <hi>Opuscula theologica</hi>.</p>')
  })

  it('insert choice/abbr/expan', () => {
    assertAnnotate({
      annotations: [
        { context: '1.4.2.12', start: 6, end: 17, text: 'ipsum dolor', type: 'abbreviation', properties: { expan: 'sit amet' } }
      ]
    }, 6, '<p xmlns="http://www.tei-c.org/ns/1.0">Lorem <choice><abbr>ipsum dolor</abbr><expan>sit amet</expan></choice> sit amet.</p>')
  })

  it('insert app/lem/rdg', () => {
    assertAnnotate({
      annotations: [
        { context: '1.4.2.12', start: 6, end: 17, text: 'ipsum dolor', type: 'app', properties: { 'wit[1]': '#me', 'rdg[1]': 'sit amet' } }
      ]
    }, 6, '<p xmlns="http://www.tei-c.org/ns/1.0">Lorem <app><lem>ipsum dolor</lem><rdg wit="#me">sit amet</rdg></app> sit amet.</p>')
  })

  it('delete choice/abbr/expan', () => {
    assertAnnotate({
      annotations: [
        { type: 'delete', node: '1.4.2.14.2', context: '1.4.2.14' }
      ]
    }, 7, '<p xmlns="http://www.tei-c.org/ns/1.0">Lorem ipsum dolor sit amet.</p>')
  })

  it('delete element containing note', () => {
    assertAnnotate({
      annotations: [
        { type: 'delete', node: '1.4.2.8.1', context: '1.4.2.8' }
      ]
    }, 4, '<p xmlns="http://www.tei-c.org/ns/1.0">Starb am<note place="footnote">Fehlt.</note>. Sammlung: Opuscula theologica.</p>')
  })

  after(() => {
    cy.logout()
  })
})
