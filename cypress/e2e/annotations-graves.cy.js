describe('template spec', () => {
    beforeEach(() => {
        cy.visit('http://localhost:8080/exist/apps/tei-publisher/annotate/graves20.xml?view=div&odd=annotations')
    });

    it('opens William Graves example and displays text', () => {

        cy.get('#view1').shadow().find('[data-tei="4.4.2.2.2"]')
            .should('have.text', 'Dear William,')

    })

    it('opens annotation panel when triggering person annotation', () => {

        cy.get('#view1').shadow().find('[data-tei="4.4.2.2.2"]')
            .trigger('mousedown')
            .then(($el) => {
                const el = $el[0]
                const document = el.ownerDocument
                const range = document.createRange()
                range.setStart(el.firstChild, 5);
                range.setEnd(el.firstChild, 12)
                document.getSelection().removeAllRanges(range)
                document.getSelection().addRange(range)
            })
            .trigger('mouseup')
        cy.document().trigger('selectionchange')

        cy.get('[icon="social:person"]').click()

        cy.get('pb-authority-lookup').shadow().find('#query').shadow().find('input')
            .should('contain.value', 'William')
    })


    /*
      it('opens Leibniz example', () => {
        cy.visit('http://localhost:8080/exist/apps/tei-publisher/annotate/test.xml?view=div&odd=annotations')
      })

      it('opens Leibnütz example', () => {
        cy.visit('http://localhost:8080/exist/apps/tei-publisher/annotate/leibnuetz.xml?view=div&odd=annotations')
      })
    */


})