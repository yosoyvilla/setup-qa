Cypress.Commands.add('login', (password = 'Passw0rd!') => {
  cy.visit('/login');
  cy.get('[data-testid=login-email]').type('alice@example.com');
  cy.get('[data-testid=login-password]').type(password);
  cy.get('[data-testid=login-submit]').click();
});
