// Demo shop used as the system under test. Zero dependencies.
// Env: PORT (default 3000), UI=v1|v2, LATENCY=max random API delay in ms, BUG=comma list:
//   login-any-password | login-no-error | search-ignores-filter | search-case-sensitive | search-no-trim | login-any-email | cart-caps-at-3 | cart-count-stale
const http = require('http');
const { URL } = require('url');

const PORT = +process.env.PORT || 3000;
const UI = process.env.UI || 'v1';
const LATENCY = +process.env.LATENCY || 0;
const BUGS = new Set((process.env.BUG || '').split(',').filter(Boolean));

const USER = { email: 'alice@example.com', password: 'Passw0rd!', name: 'Alice Reyes' };
const PRODUCTS = [
  { id: 1, name: 'Trail Backpack', category: 'bags' },
  { id: 2, name: 'Day Backpack', category: 'bags' },
  { id: 3, name: 'Steel Bottle', category: 'drinkware' },
  { id: 4, name: 'Camp Mug', category: 'drinkware' },
  { id: 5, name: 'Rain Jacket', category: 'apparel' },
];
let cartCount = 0;

const delay = () => new Promise((r) => setTimeout(r, LATENCY ? Math.random() * LATENCY : 0));
const json = (res, code, body) => {
  res.writeHead(code, { 'content-type': 'application/json' });
  res.end(JSON.stringify(body));
};
const readBody = (req) => new Promise((r) => { let d = ''; req.on('data', (c) => (d += c)); req.on('end', () => r(d ? JSON.parse(d) : {})); });

const page = (title, body) => `<!doctype html><html lang="en"><head><meta charset="utf-8"><title>${title}</title></head><body>${body}</body></html>`;

const loginPage = () => UI === 'v1'
  ? page('Login', `<h1>Shop login</h1>
<form id="f"><input data-testid="login-email" placeholder="email"><input data-testid="login-password" type="password" placeholder="password">
<button data-testid="login-submit" type="submit">Log in</button></form><p data-testid="login-error" hidden></p>
<script>f.onsubmit=async e=>{e.preventDefault();const [em,pw]=f.querySelectorAll('input');
const r=await fetch('/api/login',{method:'POST',body:JSON.stringify({email:em.value,password:pw.value})});const j=await r.json();
if(r.ok){sessionStorage.name=j.name;location='/products'}else{const p=document.querySelector('[data-testid=login-error]');p.hidden=false;p.textContent=j.error}}</script>`)
  : page('Sign in', `<h1>Sign in to the shop</h1>
<form id="f"><label>Email address <input name="email"></label><label>Password <input name="password" type="password"></label>
<button type="submit">Sign in</button></form><div role="alert" id="err"></div>
<script>f.onsubmit=async e=>{e.preventDefault();const [em,pw]=f.querySelectorAll('input');
const r=await fetch('/api/login',{method:'POST',body:JSON.stringify({email:em.value,password:pw.value})});const j=await r.json();
if(r.ok){sessionStorage.name=j.name;location='/products'}else{err.textContent=j.error}}</script>`);

const productsPage = () => UI === 'v1'
  ? page('Products', `<header><span data-testid="user-name"></span> <span data-testid="cart-count">0</span></header>
<input data-testid="search" placeholder="search"><ul data-testid="results"></ul>
<script>document.querySelector('[data-testid=user-name]').textContent=sessionStorage.name||'';
const s=document.querySelector('[data-testid=search]'),ul=document.querySelector('[data-testid=results]');
let n=0;async function load(){const k=++n;const j=await (await fetch('/api/products?q='+encodeURIComponent(s.value))).json();if(k!==n)return;
ul.innerHTML=j.map(p=>'<li data-testid="product-'+p.id+'">'+p.name+' <button data-testid="add-'+p.id+'">Add</button></li>').join('')}
s.oninput=load;load();
ul.onclick=async e=>{const id=e.target.dataset.testid?.replace('add-','');if(!id)return;
const j=await (await fetch('/api/cart',{method:'POST',body:JSON.stringify({id:+id})})).json();document.querySelector('[data-testid=cart-count]').textContent=j.count}</script>`)
  : page('Products', `<header role="banner"><span id="who"></span> <a href="/cart" aria-label="Cart"><span id="cc">0</span> items</a></header>
<label>Search products <input id="q" type="search"></label><ul id="list" aria-label="Product list"></ul>
<script>who.textContent='Signed in as '+(sessionStorage.name||'');
let n=0;async function load(){const k=++n;const j=await (await fetch('/api/products?q='+encodeURIComponent(q.value))).json();if(k!==n)return;
list.innerHTML=j.map(p=>'<li><span>'+p.name+'</span> <button aria-label="Add '+p.name+' to cart" data-id="'+p.id+'">Add to cart</button></li>').join('')}
q.oninput=load;load();
list.onclick=async e=>{const id=e.target.dataset.id;if(!id)return;
const j=await (await fetch('/api/cart',{method:'POST',body:JSON.stringify({id:+id})})).json();cc.textContent=j.count}</script>`);

http.createServer(async (req, res) => {
  const u = new URL(req.url, 'http://x');
  if (u.pathname === '/login' || u.pathname === '/') { res.writeHead(200, { 'content-type': 'text/html' }); return res.end(loginPage()); }
  if (u.pathname === '/products') { res.writeHead(200, { 'content-type': 'text/html' }); return res.end(productsPage()); }
  if (u.pathname === '/health') return json(res, 200, { ok: true });
  if (u.pathname === '/api/login' && req.method === 'POST') {
    await delay();
    const b = await readBody(req);
    const ok = (b.email === USER.email || BUGS.has('login-any-email')) && (b.password === USER.password || BUGS.has('login-any-password'));
    if (ok) { cartCount = 0; return json(res, 200, { name: USER.name, token: 'tok-alice' }); }
    return json(res, 401, { error: BUGS.has('login-no-error') ? '' : 'Invalid credentials' });
  }
  if (u.pathname === '/api/products') {
    await delay();
    const q = BUGS.has('search-no-trim') ? (u.searchParams.get('q') || '').toLowerCase() : (u.searchParams.get('q') || '').trim().toLowerCase();
    const raw = u.searchParams.get('q') || '';
    const match = (p) => (BUGS.has('search-case-sensitive') ? p.name.includes(raw) : p.name.toLowerCase().includes(q));
    const list = BUGS.has('search-ignores-filter') ? PRODUCTS : PRODUCTS.filter(match);
    return json(res, 200, list);
  }
  if (u.pathname === '/api/cart' && req.method === 'POST') {
    await delay();
    await readBody(req);
    if (!(BUGS.has('cart-caps-at-3') && cartCount >= 3)) cartCount += 1;
    return json(res, 200, { count: BUGS.has('cart-count-stale') ? 0 : cartCount });
  }
  json(res, 404, { error: 'not found' });
}).listen(PORT, () => console.log(`shop listening on ${PORT} ui=${UI} bugs=${[...BUGS]}`));
