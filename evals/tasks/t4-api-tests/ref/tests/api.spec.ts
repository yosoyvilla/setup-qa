import { test, expect } from '@playwright/test';

const login = (request, password: string) =>
  request.post('/api/login', { data: { email: 'alice@example.com', password } });

test('valid login returns name and token', async ({ request }) => {
  const r = await login(request, 'Passw0rd!');
  expect(r.status()).toBe(200);
  const body = await r.json();
  expect(body.name).toBe('Alice Reyes');
  expect(body.token).toBeTruthy();
});

test('wrong password returns 401 with error', async ({ request }) => {
  const r = await login(request, 'wrong');
  expect(r.status()).toBe(401);
  expect((await r.json()).error).toBe('Invalid credentials');
});

test('product search returns only matching products', async ({ request }) => {
  const r = await request.get('/api/products', { params: { q: 'mug' } });
  const items = await r.json();
  expect(items).toHaveLength(1);
  expect(items[0].name).toBe('Camp Mug');
});

test('cart count increments per add', async ({ request }) => {
  await login(request, 'Passw0rd!');
  expect((await (await request.post('/api/cart', { data: { id: 1 } })).json()).count).toBe(1);
  expect((await (await request.post('/api/cart', { data: { id: 2 } })).json()).count).toBe(2);
});
