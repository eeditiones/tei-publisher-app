describe('Leibnuetz spec', () => {


  it('opens Leibnütz example', () => {
    cy.visit('http://localhost:8080/exist/apps/tei-publisher/annotate/leibnuetz.xml?view=div&odd=annotations')
  })

})