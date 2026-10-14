---
name: api-testing
description: Writing HTTP API tests with Playwright's request fixture - status and body assertions, auth, state, negative cases. Use when asked to test a REST or JSON API, write tests without a browser, or verify backend behaviour.
---

# API testing with Playwright

No browser or `page` is needed. Use the `request` fixture; it uses `baseURL` from the config.

```ts
import { test, expect } from '@playwright/test';

test('wrong password returns 401 with a message', async ({ request }) => {
  const res = await request.post('/api/login', { data: { email: 'alice@example.com', password: 'wrong' } });
  expect(res.status()).toBe(401);
  expect((await res.json()).error).toBe('Invalid credentials');
});
```

## Discover before asserting

`curl -i` each endpoint to learn the method, status codes, headers and body shape. Do not assume field names.

## What to assert

- The status code, exactly (200 vs 201 vs 204, 400 vs 401 vs 404).
- The body fields that matter, with exact values; for lists assert the length and the items, not "not empty".
- Error responses: the status and the error message.
- Side effects: after a write, read it back through a second request.

## Cases to cover

Valid input, wrong or missing credentials, unknown id, empty or malformed body, filters with no match, boundaries, and repeating the same call.

## State

If the server keeps state between calls (a cart, a session), start each test from a known state (log in again, call a reset endpoint, or use unique data) so tests pass alone and when repeated.

## Do not

Mock the API you are testing, or test an API through the browser when a request would do.
