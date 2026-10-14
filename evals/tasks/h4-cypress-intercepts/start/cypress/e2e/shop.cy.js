describe('shop', () => {
  it('signs in with the custom login command', () => {
    cy.login();
    cy.url().should('include', '/products');
    cy.get('[data-testid=user-name]').should('have.text', 'Alice Reyes');
  });

  it('rejects a wrong password', () => {
    cy.login('nope');
    cy.url().should('include', '/login');
    cy.get('[data-testid=login-error]').should('have.text', 'Invalid credentials');
  });

  it('shows no products when the catalogue API returns an empty list', () => {
    cy.intercept('GET', '/api/products*', { fixture: 'empty-products.json' }).as('products');
    cy.login();
    cy.wait('@products');
    cy.get('[data-testid^=product-]').should('have.length', 0);
  });

  it('filters products using the real API', () => {
    cy.login();
    cy.intercept('GET', '/api/products*').as('search');
    cy.get('[data-testid=search]').type('mug');
    cy.wait('@search');
    cy.get('[data-testid^=product-]').should('have.length', 1);
  });

  it('waits for the cart API before checking the badge', () => {
    cy.intercept('POST', '/api/cart').as('cart');
    cy.login();
    cy.get('[data-testid=add-1]').click();
    cy.wait('@cart').its('response.statusCode').should('eq', 200);
    cy.get('[data-testid=cart-count]').should('have.text', '1');
  });
});
