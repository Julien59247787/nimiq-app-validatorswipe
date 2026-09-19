# Operator Guide

**Audience:** a Nimiq validator operator who wants to host their own copy of Validator Swipe
on their own infrastructure (and, if they like, feature their own validators).

**Scope:** everything the static `index.html` needs from a server — backend endpoints, Nimiq
node, hosting, reverse proxy, HTTPS, CSP — plus how to customize the app and verify a
deployment.

Conventions: `example.org` / `<your-domain>` stand for your own domain; all paths are
examples. **1 NIM = 100,000 luna.** Addresses are written in user-friendly form with spaces
(`NQ07 0000 0000 …`).

## Contents

0. [Overview and checklist](#0-overview-and-checklist)
1. [API contract](#1-api-contract-consumed-by-indexhtml)
2. [Data sources and logic](#2-data-sources-and-logic)
3. [Hosting: static files, reverse proxy, HTTPS, CSP](#3-hosting-static-files-reverse-proxy-https-csp)
4. [Nimiq node prerequisites](#4-nimiq-node-prerequisites)
5. [Minimal setup without a full backend](#5-minimal-setup-without-a-full-backend)
6. [Customizing for your own validators](#6-customizing-for-your-own-validators)
7. [Deployment steps](#7-deployment-steps)
8. [Post-deployment verification checklist](#8-post-deployment-verification-checklist)
9. [Updating, monitoring, troubleshooting](#9-updating-monitoring-troubleshooting)

---

## 0. Overview and checklist

```
Browser / Nimiq Pay WebView
   │  (same origin)
   ├── GET /                          static index.html (+ demo.mp4, og-image.png, …)
   ├── GET /api/v2/validators-list    ← your backend (cached, refreshed daily)
   └── GET /api/v2/staker-status      ← your backend (live proxy to your node's RPC)

Your backend ──JSON-RPC (localhost only)──► your Nimiq node (main-albatross)
Your backend ──HTTPS, once a day──────────► a public source of per-validator scores (§2.2)

Signing / broadcasting never touches your server: transactions are built and signed
client-side (Nimiq Pay mini-app SDK, or a Nimiq Hub popup outside Nimiq Pay).
```

The app is **not** "plug into any validator". It calls exactly **two** backend endpoints,
relative to its own origin, so the API and the static files must be served from the **same
origin** (or a reverse proxy must make them look so).

At runtime the page also loads from `cdn.jsdelivr.net`: `@nimiq/hub-api` (`<script src>`),
`@nimiq/mini-app-sdk` and `@nimiq/core` (dynamic `import()`; the latter loads a WebAssembly
module). This drives the CSP in §3.4. Self-hosting these requires editing the app.

**What you need, in short:**

- [ ] A synced Nimiq mainnet node with JSON-RPC bound to localhost (§4)
- [ ] A small backend exposing the two endpoints (§1), or the minimal variant (§5)
- [ ] A web server / reverse proxy serving `index.html` and `/api/` on one origin over HTTPS (§3)
- [ ] A Content-Security-Policy including the inline-script hash (§3.4)
- [ ] Your own validators, image, links in `index.html` (§6)

> This repository contains the front end only. The backend is described by contract so you
> can implement it in any language; a clean reference extract may be published separately
> (see the [changelog](../CHANGELOG.md) for future work).

---

## 1. API contract consumed by `index.html`

Only these two endpoints are called. Both are `GET`, JSON, unauthenticated and read-only.
Every response should carry `Cache-Control: no-store`.

Common envelope fields:

| Field | Type | Meaning |
|---|---|---|
| `api_version` | string | `"2"` |
| `generated_at` | string | ISO-8601 UTC time the response was produced |

Error shape: HTTP 4xx with `{ "error": "<code>" }`. Reject unknown query parameters with
`400 {"error":"unsupported_query_parameter:<name>"}`; unknown paths return
`404 {"error":"not_found"}`.

### 1.1 `GET /api/v2/validators-list?limit=200`

Purpose: populate the swipe cards (all active validators, sorted by stake descending).

Query: `limit` — optional integer 1..200 (default 200). Invalid → `400 {"error":"invalid_limit"}`.

Response `200`:

```json
{
  "api_version": "2",
  "generated_at": "2026-09-18T09:23:48.889Z",
  "cache_updated_at": "2026-09-17T17:42:03.028Z",
  "count": 39,
  "validators": [
    {
      "address": "NQ07 0000 0000 0000 0000 0000 0000 0000 0000",
      "stake_luna": 68518027016612,
      "availability": 0.99999,
      "dominance": 0.99,
      "reliability": null,
      "reward_rate": 0.11000,
      "fee": 0.05,
      "name": "Example Staking"
    }
  ]
}
```

| Field | Type | Unit / range | `null` means |
|---|---|---|---|
| `address` | string | user-friendly `NQ…` address of the **validator** | never null |
| `stake_luna` | integer | total stake, luna | never null |
| `availability` | number\|null | fraction 0..1 (the UI multiplies by 100) | source publishes no score |
| `dominance` | number\|null | fraction 0..1 | same. Returned by the reference backend but **currently ignored by the UI** (optional) |
| `reliability` | number\|null | fraction 0..1 (a *different* metric from availability) | same |
| `reward_rate` | number\|null | theoretical yearly, net-of-fee yield as a fraction (0.11 = 11 %) | fee unknown |
| `fee` | number\|null | validator commission, fraction 0..1 | source publishes no fee |
| `name` | string\|null | validator's self-published display name | not published |

**Rule: never guess.** A missing value is an explicit `null` (never `0`, never omitted, never
invented). The UI renders `null` as "—". Returning `0` would display "0 % yield", which is a lie.

Front-end behavior worth knowing:

- If the request fails (network error, non-2xx status, invalid JSON), the app keeps a hard-coded
  two-entry list and shows a "could not load the full list" note (see §6). If the request succeeds
  but `validators` is empty, the same two entries stay in place **silently, with no note**.
- `name` from the API wins over any hard-coded name. If `name` is `null`, the UI shows a
  shortened address.
- Ordering is done client-side (by number of available stats, then name); you don't need to sort.

### 1.2 `GET /api/v2/staker-status?address=<NQ address>`

Purpose: show the connected wallet's staking state and spendable balance, and — critically —
let the app choose the right transaction type (create staker vs add stake vs update staker).

Query: `address` — required. Do a loose format check server-side, e.g.
`^NQ[0-9]{2}([ A-Z0-9]{4,44})$` and length ≤ 48, else `400 {"error":"invalid_address"}` (a
sanity cap before handing the string to the node, not a strict validator).

Response `200` (always 200 for a well-formed address, even if it never staked):

```json
{
  "api_version": "2",
  "generated_at": "2026-09-18T09:23:48.889Z",
  "address": "NQ.. .... ....",
  "found": true,
  "active_balance_luna": 30240000000,
  "delegation": "NQ40 …validator address…",
  "inactive_balance_luna": 5016415,
  "inactive_from": 61776000,
  "retired_balance_luna": 0,
  "wallet_balance_luna": 0
}
```

| Field | Type | Meaning |
|---|---|---|
| `found` | boolean | `true` iff the node knows a **staker** entry for this address. Most addresses are `false` — normal, not an error. |
| `active_balance_luna` | int\|null | currently staked (active) amount |
| `delegation` | string\|null | validator address currently delegated to |
| `inactive_balance_luna` | int\|null | amount in retired/unbonding state (a retire is in progress if > 0) |
| `inactive_from` | int\|null | marker for when the unbonding delay started. Returned by the reference backend but **not read by the current UI** (optional) |
| `retired_balance_luna` | int\|null | fully unbonded amount, withdrawable |
| `wallet_balance_luna` | int\|null | **spendable balance of the basic account**, independent of `found` |

Semantics to keep exactly right:

- `wallet_balance_luna` is **not** the staked balance. It is the basic-account balance only.
  Funds locked in a contract (e.g. a swap HTLC still settling) do **not** appear here — a
  freshly topped-up wallet can legitimately read `0`. The UI then shows a non-blocking
  "funds may still be settling" hint, and pre-fills the delegation amount from this value
  only when it is ≥ 1 NIM.
- No staker → `found:false` and all staker fields `null`; `wallet_balance_luna` is still reported.
- If the node RPC itself fails or times out → the same explicit-null response
  (`found:false`, nulls) rather than a 500. (Trade-off: the UI cannot tell "not a staker"
  from "node down".)
- No caching: this is a live, per-request passthrough.

> **Critical dependency.** Before sending a delegation, the app calls this endpoint to decide
> between *create staker*, *add stake* and *update staker (switch validator)*. If the call
> fails, the app **assumes "no existing staker"** and attempts *create staker* — which the
> network rejects for a wallet that already has a staker. A backend that returns
> `found:false` for real stakers therefore breaks adding stake and switching validator.
> Implement this endpoint faithfully or not at all.

Not consumed by the app but useful: `GET /api/health` → `200`, for monitoring and deploy checks.

---

## 2. Data sources and logic

### 2.1 Your Nimiq node (JSON-RPC, local)

Backend → node: JSON-RPC 2.0 over HTTP POST, **localhost only**. Methods used (all read-only):

| Method | Used for |
|---|---|
| `getActiveValidators` | address and total stake of every active validator (`validators-list`) |
| `getStakerByAddress` | `found`, active/inactive/retired balances, `delegation`, `inactive_from` |
| `getAccountByAddress` | `wallet_balance_luna` (basic account `balance`) |

Notes:

- `getStakerByAddress` throws `"No staker with address …"` for non-stakers. Treat that as the
  normal `found:false` case.
- Use short timeouts (≈ 5 s) and never expose the RPC port publicly.
- Do **not** proxy arbitrary RPC methods to the internet; expose only the two endpoints above.

### 2.2 Per-validator stats (uptime / reliability / fee / name)

The node RPC gives stake per validator but not the scoring statistics. Obtain them from a
**public source of validator statistics** you are comfortable relying on — for example a
public Nimiq validators API or explorer. The contract only cares about the resulting fields
(`availability`, `dominance`, `reliability`, `fee`, `name`); how you fill them is up to you.
Whatever source you choose:

- Prefer a documented API over parsing web pages. If you must parse a page whose structure you
  don't control, a markup change will silently yield `null` (the contract handles that safely,
  but the stats disappear) — monitor for "everything became null".
- Be polite to the source: refresh **once a day**, one request per validator, spaced several
  seconds apart, and check its terms of use. Never call it on user requests — always serve from
  your own cache.
- Only validators with enough established history have scores and a fee; newer ones legitimately
  have `null` everywhere. `reward_rate` is `null` for exactly the same validators (it needs `fee`).
- `reward_rate` is **computed**, not fetched: the protocol reward formula from the official
  `@nimiq/utils` package (`calculateStakingRewards`, with `stakedSupplyRatio` = total staked /
  PoS supply from `posSupplyAt`), evaluated for 100,000 NIM over 365 days with that
  validator's `fee` and **auto-restake = false** (conservative, comparable across validators).
  The staked-supply ratio is computed once per run (network-wide), clamped to [0.01, 0.99].

### 2.3 Cache and refresh

- Table (SQLite in the reference; any store works):
  `validators_cache(address PK, stake_luna, availability, dominance, reliability,
  reward_rate, fee, name, updated_at)`.
- A daily job: `getActiveValidators` → fetch scores for each validator → upsert → delete rows
  for validators no longer active.
- A timer (e.g. systemd `OnBootSec=5min`, `OnUnitActiveSec=1d`, `Persistent=true`) drives it.
  Expose `cache_updated_at` (= `max(updated_at)`) so freshness is visible.
- `validators-list` reads only from the cache: fast, no external call per request.

### 2.4 Rate limiting

`staker-status` triggers two RPC calls per request. Put a per-IP rate limit at the reverse
proxy (a small burst, a low sustained rate) and keep the node RPC bound to localhost.

---

## 3. Hosting: static files, reverse proxy, HTTPS, CSP

### 3.1 Layout

Serve the static app and proxy `/api/` to the backend on the same host:

```
https://<your-domain>/            → index.html (+ assets)
https://<your-domain>/api/*       → backend (e.g. 127.0.0.1:<port>)
```

The app uses **relative** URLs (`/api/v2/…`, `demo.mp4`), so a sub-path deployment needs
`/api` reachable at the origin root (or a proxy rewrite).

**HTTPS is mandatory**: Nimiq Pay and the Nimiq Hub popup require a secure origin, and the
CSP below assumes it. Use any ACME client (Let's Encrypt) or your existing certificate setup.

### 3.2 Example — nginx

```nginx
server {
  listen 443 ssl http2;
  server_name <your-domain>;
  ssl_certificate     /etc/ssl/<your-domain>/fullchain.pem;
  ssl_certificate_key /etc/ssl/<your-domain>/privkey.pem;

  root /srv/validator-swipe;
  index index.html;

  types { video/mp4 mp4; audio/mp4 m4a; }          # see §3.3

  location /api/ {
    limit_req zone=api burst=20 nodelay;            # limit_req_zone defined in http{}
    proxy_pass http://127.0.0.1:8080;               # your backend
    proxy_set_header Host $host;
    add_header Cache-Control "no-store" always;
  }

  add_header Content-Security-Policy "<see §3.4>" always;
  add_header X-Content-Type-Options nosniff always;
  add_header Referrer-Policy strict-origin-when-cross-origin always;
}
```

### 3.2b Example — Caddy

```caddy
<your-domain> {
    root * /srv/validator-swipe
    encode gzip

    handle /api/* {
        reverse_proxy 127.0.0.1:8080
    }
    handle {
        file_server
    }

    header {
        Content-Security-Policy "<see §3.4>"
        X-Content-Type-Options nosniff
        Referrer-Policy strict-origin-when-cross-origin
    }
    header /api/* Cache-Control "no-store"
}
```

Caddy obtains and renews HTTPS certificates automatically and ships correct MIME types.
Per-IP rate limiting is not built into stock Caddy: use a plugin, or rate-limit in front
(CDN / WAF / firewall).

**Caching headers.** `/api/*` → `no-store` (the list is already cached server-side; the client
must not add a second, stale layer). `index.html` → `no-cache` (or a short `max-age`) so a
new deployment — and its new CSP hash — reaches visitors immediately. Large media
(`demo.mp4`, images) may use a long `max-age`. If a CDN sits in front, it may add its own edge
caching by file extension (`.ico`, `.png`…): purge after replacing such files.

### 3.3 MIME types (real incident)

If you host the demo video, make sure `.mp4` is served as `video/mp4` (and `.m4a` as
`audio/mp4`). Some servers and config templates ship without these mappings and fall back to
`application/octet-stream`, which makes browsers **download** the file instead of playing it
when the "Watch the demo video" link is clicked. Also verify Range / partial-content support
if you want seeking on large files.

```bash
curl -sI https://<your-domain>/demo.mp4 | grep -i '^content-type'
```

### 3.4 Content-Security-Policy

The app has **one inline `<script>`** (plus one external `<script src>` for the Hub API).
Instead of `'unsafe-inline'`, allow the inline script by its SHA-256 hash. A working policy:

```
default-src 'self';
script-src 'self' 'wasm-unsafe-eval' 'sha256-<HASH_OF_INLINE_SCRIPT>' https://cdn.jsdelivr.net;
style-src 'self' 'unsafe-inline' https://fonts.googleapis.com;
font-src https://fonts.gstatic.com;
img-src 'self' data:;
connect-src 'self' https://cdn.jsdelivr.net;
frame-ancestors 'self';
base-uri 'none';
form-action 'self';
```

Why each non-obvious piece is there:

- `'wasm-unsafe-eval'`: `@nimiq/core` instantiates a WebAssembly module. Without it the
  staking-transaction path fails with a CSP error even though everything else works.
- `connect-src https://cdn.jsdelivr.net`: the WASM binary is `fetch()`ed from the CDN
  (a separate directive from `script-src`).
- `script-src https://cdn.jsdelivr.net`: the Hub API script and the SDK/core ES modules.
- `img-src data:`: inline images/icons.
- `style-src 'unsafe-inline'`: the page uses inline `<style>` and style attributes. **CSS-only
  changes therefore never require a new hash** — only edits inside the `<script>` do.
- The Nimiq Hub login/signing UI opens in a **popup window**, not an iframe, so it is not
  governed by `frame-src` / `connect-src`.

**Computing the hash — redo it on every change to the inline script.** Whitespace counts, and
on Windows / `git autocrlf` checkouts line endings can silently change bytes, so always
normalize CRLF → LF before hashing. Hash **the deployed file**, not your working copy.

With Node.js:

```bash
node -e '
const fs=require("fs"), c=require("crypto");
const html=fs.readFileSync("index.html","utf8");
const m=html.match(/<script>([\s\S]*?)<\/script>/);   // the inline script (no src attribute)
const s=m[1].replace(/\r\n/g,"\n").replace(/\r/g,"\n");
console.log("sha256-"+c.createHash("sha256").update(s,"utf8").digest("base64"));
'
```

Or with Perl and OpenSSL only (equivalent output):

```bash
perl -0777 -ne 'print $1 if /<script>(.*?)<\/script>/s' index.html \
  | tr -d '\r' | openssl dgst -sha256 -binary | openssl base64 -A | sed 's/^/sha256-/'; echo
```

Put the printed `sha256-…` value in the `script-src` directive.

### 3.5 Multi-node / load-balanced deployments

- The static files and the inline-script hash must be **byte-identical on every node**
  (compare the SHA-256 of `index.html` across nodes).
- Update the hash on all nodes in the same maintenance step; a node serving new HTML with an
  old hash (or vice versa) breaks only the visitors routed there — hard to spot with
  round-robin DNS.
- Each node needs access to a Nimiq node RPC (its own or a shared internal one) and its own
  copy of the cache (or a shared database).

---

## 4. Nimiq node prerequisites

- A Nimiq PoS ("Albatross") client on the **main network** (`main-albatross`), fully synced
  (`isConsensusEstablished` = true). The reference deployment runs `core-rs-albatross` with
  `sync_mode = "full"`.
- JSON-RPC server enabled and bound to **`127.0.0.1`** with an IP allow-list restricted to
  localhost. Do not publish it. The read-only methods in §2.1 are all that is required.
- No transaction-history index is needed: `getStakerByAddress`, `getAccountByAddress` and
  `getActiveValidators` work without it.
- Resources: a normal full node; the backend itself is tiny (e.g. Node.js ≥ 20 + SQLite) and
  the daily job is negligible load.
- Minimal monitoring: `/api/health` returns 200; alert if `cache_updated_at` is older than
  ~36 h; alert if `validators-list` returns `count: 0` or if all stats become `null` (the
  stats source broke); alert on node consensus loss.

---

## 5. Minimal setup without a full backend

You can satisfy the contract with much less:

| Endpoint / field | Required? | Minimal implementation |
|---|---|---|
| `staker-status` | **Yes** (drives create/add/switch) | thin proxy: `getStakerByAddress` (+ `getAccountByAddress` for the balance) against a Nimiq RPC you trust, mapped to §1.2 |
| `validators-list` | Strongly recommended | `getActiveValidators` → `address` + `stake_luna`; every other field `null` |
| stats / `reward_rate` / `name` | Optional | add later from any public source you like; compute `reward_rate` with `@nimiq/utils` |

Degradation if you skip pieces:

- Failed `validators-list` → only the two hard-coded entries appear, with a notice; an empty list → the same two entries, silently.
- All stats `null` → cards show "—" (honest, but less useful).
- `wallet_balance_luna: null` → no amount pre-fill (the user types it); `0` → the "funds may be settling" hint.
- Wrong or absent `staker-status` → existing stakers cannot reliably add stake or switch (see §1.2).

A static-file variant is viable for `validators-list`: a cron job writes the JSON to disk and
the web server serves `/api/v2/validators-list` as a static file (the `?limit=` parameter is
then ignored; the app always asks for 200). `staker-status` must be dynamic.

---

## 6. Customizing for your own validators

The front end is a single file, and a few things in it belong to the original deployment.
Edit your own copy of `index.html`:

### a) Your validators — `KNOWN_VALIDATORS` and `FALLBACK_VALIDATORS`

Both live in the script, near `loadValidatorsList()`:

```js
var KNOWN_VALIDATORS = {
  "NQxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx": {   // your validator address
    name: "Your Validator Name",                        // used only if the API publishes no name
    desc: "A short description shown on the card"
  }
};

var FALLBACK_VALIDATORS = [   // shown only if /api/v2/validators-list can't be reached
  { name: "Your Validator Name", isKnown: true, address: "NQxx xxxx …",
    availability: 99.5, reward: 11.0, staked: "1.0M NIM",     // illustrative fallback numbers
    desc: KNOWN_VALIDATORS["NQxx xxxx …"].desc }
];
```

- The key of `KNOWN_VALIDATORS` must be the exact user-friendly address (with spaces) that
  your `validators-list` returns.
- The `desc` is displayed on that validator's card; validators not listed there have no description.
- The fallback numbers are only used when the API is unreachable. Keep them honest or set them to `null`.
- The list shown to users always comes from your API; these constants do not reorder or filter it.

### b) Link preview — `og:image`

Near the top of `<head>`, `<meta property="og:image">` holds an **absolute URL** on the original
domain. Point it to an image hosted on your own domain (1200×630 recommended) and adjust the
`<title>`, `<meta name="description">` and `og:*` texts if you wish.

### c) Footer credits and links

At the end of `<body>`, the `credit-footer` block contains the original authors' credit, a
community link and a mascot image; the matching texts are the `footer.*` keys in the `T`
dictionary. Replace or remove them (remember to keep or delete the keys consistently in all
11 languages — see [I18N.md](I18N.md)). The MIT license requires you to keep the copyright
notice in [LICENSE](../LICENSE).

### d) Demo video

The hero has a "Watch the demo video" button linking to a relative `demo.mp4`. Provide your own
recording next to `index.html`, or remove the button (`hero.ctaVideo`).

### e) After any edit inside the `<script>`

Recompute the CSP hash (§3.4) and update the header on every node. CSS/markup-only edits don't
need a new hash.

---

## 7. Deployment steps

1. **Node:** run a synced mainnet Nimiq node with localhost-only JSON-RPC (§4).
2. **Backend:** implement or deploy the two endpoints (§1, §5) next to it; bind them to
   localhost; schedule the daily refresh job if you use per-validator stats (§2.3).
3. **Customize** `index.html` (§6) and test it locally.
4. **Upload** `index.html` (and `og-image.png`, `demo.mp4`, mascot/logo images you use) to your
   web root.
5. **Compute the hash** of the deployed `index.html` (§3.4) and set the CSP header.
6. **Configure the reverse proxy**: static root, `/api/` → backend, HTTPS, MIME types,
   rate limiting (§3).
7. **Reload** the web server and run the [verification checklist](#8-post-deployment-verification-checklist).
8. **Make it available in Nimiq Pay** by following the official Nimiq Mini Apps documentation
   (how mini apps are listed is decided by Nimiq, not by this app).

## 8. Post-deployment verification checklist

Run through this after every deployment, on **every** node/origin (not just the first).

1. **Files:** `sha256sum index.html` is identical on all nodes and matches what you meant to ship.
2. **CSP hash:** recomputed from the *deployed* file (§3.4) and equal to the `sha256-…` value in the
   served header (`curl -sI https://<your-domain>/ | grep -i content-security-policy`).
3. **API:** both endpoints return `200` with the expected shape and the error paths return the
   documented `400` / `404` (commands below). `validators-list` has `count` > 0 and a recent
   `cache_updated_at`; `staker-status` for a known staker returns `found:true`.
4. **Health:** `GET /api/health` → `200`.
5. **HTTPS only:** plain HTTP redirects to HTTPS (Nimiq Pay and the Hub popup need a secure origin).
6. **MIME / media:** `demo.mp4` is served as `video/mp4` (if you ship the video).
7. **Browser console** (desktop Chrome, hard reload): no CSP violations, no failed `/api/*`
   requests. A quick in-console check that the page runs the script you think it does:
   ```js
   const s=[...document.querySelectorAll("script")].find(e=>!e.src).textContent;
   const b=await crypto.subtle.digest("SHA-256",new TextEncoder().encode(s));
   "sha256-"+btoa(String.fromCharCode(...new Uint8Array(b)))   // must equal the hash in your CSP
   ```
8. **Functional, no wallet (plain browser):** cards load with real stats, swiping and favoriting
   work, and "delegate" shows the clearly labeled *demo mode* message (nothing is sent).
9. **Functional, wallet outside Nimiq Pay:** "Connect" opens the Nimiq Hub popup (allow popups
   for your domain), the address is detected and `staker-status` is fetched for it (Network
   tab). Use a wallet with a small spendable balance.
10. **Functional, inside Nimiq Pay** (the target environment): open the mini app from Nimiq Pay
    on a real device; confirm the address is detected, the amount field is pre-filled from
    `wallet_balance_luna` (when ≥ 1 NIM), and a real delegation is offered for confirmation
    **in the wallet UI** (your server never signs or broadcasts anything). The Nimiq Pay
    WebView is not remotely debuggable, so plan a way to see diagnostics during first tests
    (for example a temporary on-screen debug line that you remove afterwards).
11. **Multi-node:** repeat 1–7 against each node directly (bypassing round-robin DNS), then once
    through the public name.
12. **Monitoring armed:** alerts on a stale `cache_updated_at`, an empty or all-null
    `validators-list`, and node consensus loss.

Notes:

- `connect-src` does **not** need `hub.nimiq.com`: the Hub opens as a top-level popup window and
  the app talks to it through the Hub API library, not via `fetch`. If a CSP violation ever names
  `hub.nimiq.com`, capture it (e.g. with `report-uri`) and add only what the report shows rather
  than widening the policy pre-emptively.
- Test wallet flows with small amounts. A wallet whose balance is temporarily locked in a swap
  contract legitimately reads `wallet_balance_luna: 0` (§1.2) — that is not a backend bug.

Quick commands:

```bash
# API responds and is well-formed
curl -s https://<your-domain>/api/v2/validators-list | head -c 400
curl -s "https://<your-domain>/api/v2/staker-status?address=NQ07%200000%200000%200000%200000%200000%200000%200000%200000"

# Error paths
curl -s "https://<your-domain>/api/v2/staker-status?address=bad"          # → {"error":"invalid_address"}
curl -s "https://<your-domain>/api/v2/validators-list?limit=999"          # → {"error":"invalid_limit"}
curl -s "https://<your-domain>/api/v2/validators-list?foo=1"              # → {"error":"unsupported_query_parameter:foo"}

# Static assets & MIME
curl -sI https://<your-domain>/demo.mp4 | grep -i content-type            # → video/mp4

# CSP present, and its hash matches the deployed script
curl -sI https://<your-domain>/ | grep -i content-security-policy
curl -s  https://<your-domain>/ | perl -0777 -ne 'print $1 if /<script>(.*?)<\/script>/s' \
  | tr -d '\r' | openssl dgst -sha256 -binary | openssl base64 -A; echo
```

## 9. Updating, monitoring, troubleshooting

**Updating the app:** pull the new `index.html`, re-apply your customizations (see §6 — keep
them in a patch or a fork), recompute and deploy the hash together with the file, on all nodes
at once.

**Symptoms and causes:**

| Symptom | Likely cause |
|---|---|
| Blank page / nothing works, CSP errors in console | Hash of the inline script does not match the header (file changed, or line endings differ) |
| Only two validators shown | `validators-list` unreachable or wrong path (a "could not load the full list" note is shown), **or** it returned an empty list (no note is shown) |
| Staking transaction fails only outside Nimiq Pay | `'wasm-unsafe-eval'` or `connect-src https://cdn.jsdelivr.net` missing from the CSP |
| Delegating a second time fails | `staker-status` reports `found:false` for an existing staker (see §1.2) |
| All validator stats show "—" | The stats source changed or is unreachable; check the daily job and `cache_updated_at` |
| Video downloads instead of playing | Missing `video/mp4` MIME mapping (§3.3) |
| Amount field never pre-fills | `wallet_balance_luna` is `null`, `0`, or below 1 NIM (the "funds may be settling" hint appears for `0`) |
