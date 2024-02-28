describe('template spec', () => {

  it('opens William Graves example', () => {
    cy.visit('http://localhost:8080/exist/apps/tei-publisher/annotate/graves20.xml?view=div&odd=annotations')

    cy.get('#view1').shadow().find('[data-tei="4.4.2.2.2"]')
        .should('have.text','Dear William,')

    /*
        cy.get('#view1').shadow().find('[data-tei="4.4.2.2.2"]')
            .dblclick({position:'right'})
    */


  })
  it('opens Leibniz example', () => {
    cy.visit('http://localhost:8080/exist/apps/tei-publisher/annotate/test.xml?view=div&odd=annotations')
  })

  it('opens Leibnütz example', () => {
    cy.visit('http://localhost:8080/exist/apps/tei-publisher/annotate/leibnuetz.xml?view=div&odd=annotations')
  })


})