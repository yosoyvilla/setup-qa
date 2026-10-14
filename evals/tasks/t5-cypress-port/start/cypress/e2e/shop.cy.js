describe('shop', () => {
  const login = (password = 'Passw0rd!') => {
    cy.visit('/login');
    cy.get('[data-testid=login-email]').type('alice@example.com');
    cy.get('[data-testid=login-password]').type(password);
    cy.get('[data-testid=login-submit]').click();
  };

  it('logs in and shows the user name', () => {
    login();
    cy.url().should('include', '/products');
    cy.get('[data-testid=user-name]').should('have.text', 'Alice Reyes');
  });

  it('rejects a wrong password', () => {
    login('nope');
    cy.url().should('include', '/login');
    cy.get('[data-testid=login-error]').should('have.text', 'Invalid credentials');
  });

  it('filters products by search', () => {
    login();
    cy.get('[data-testid=search]').type('mug');
    cy.get('[data-testid^=product-]').should('have.length', 1);
    cy.get('[data-testid=results]').should('contain', 'Camp Mug');
  });

  it('adds a product to the cart', () => {
    login();
    cy.get('[data-testid=add-1]').click();
    cy.get('[data-testid=cart-count]').should('have.text', '1');
  });
});
