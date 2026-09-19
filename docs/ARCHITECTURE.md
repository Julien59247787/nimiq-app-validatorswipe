# Architecture

Validator Swipe is deliberately small: **one static `index.html`** (markup, CSS and vanilla
JavaScript, no framework, no bundler, no build step) plus two read-only JSON endpoints
provided by the operator's backend.

```
                ┌────────────────────────── browser / Nimiq Pay WebView ─────────────────────────┐
                │                                                                                 │
   user ───────►│  index.html  (UI, i18n dictionary, state, staking logic)                        │
                │     │                       │                          │                        │
                └─────┼───────────────────────┼──────────────────────────┼────────────────────────┘
                      │ fetch (same origin)   │ inside Nimiq Pay         │ outside Nimiq Pay
                      ▼                       ▼                          ▼
        ┌───────────────────────┐   ┌──────────────────────┐   ┌───────────────────────────┐
        │ Operator backend      │   │ @nimiq/mini-app-sdk  │   │ @nimiq/hub-api  (popup)   │
        │  /api/v2/validators-  │   │ window.nimiqPay,     │   │ + @nimiq/core (builds the │
        │        list           │   │ signs & sends txs    │   │ staking tx locally)       │
        │  /api/v2/staker-status│   └──────────────────────┘   └───────────────────────────┘
        └──────────┬────────────┘
                   ▼
          Nimiq full node (RPC)  ──►  Nimiq network
```

## Components

### 1. The page (`index.html`)

Inside a single IIFE-style script block:

- **Data layer** — `loadValidatorsList()` fetches the validator list and normalizes it
  (fractions → percentages, `luna` → NIM, missing metrics stay `null` and are shown as `—`).
  Cards are sorted by number of available metrics (best first), then alphabetically.
- **Fresh on-chain view** — after every real transaction the app re-reads `/api/v2/staker-status`
  (first read 1.8 s after the wallet returns, every 2 s until 20 s, then every 5 s, capped at 60 s,
  single de-duplicated chain, paused while hidden) until the chain reflects the action; every read
  re-renders the delegation banner, stake block, history and Add/Switch mode of the cards together,
  and only the Delegate button is locked meanwhile. An unreadable status before delegating is
  retried twice, then refused (nothing is sent).
- **View re-framing** — after a tap on the star or the shield, and when a success/error message closes, the page
  scrolls gently so the delegation banner, waiting notice, active stake and card are visible (skipped while
  typing, within 1 s of a manual scroll, while the keyboard restoration is pending, or when hidden; instant
  with `prefers-reduced-motion`).
- **Scroll restoration** — when the on-screen keyboard closes after typing an amount, the page returns
  to the scroll position it had when the field got focus (nothing happens while typing, after a manual
  scroll, or without `visualViewport`).
- **State** — a small `state` object: `{ nimiq, hub, myAddress }` (Nimiq Pay provider, Nimiq
  Hub client, connected address), plus `lastStakerStatus` (the latest on-chain snapshot).
- **Two phases** — *Browse* (pass / set aside; never sends a transaction) and *My favorites*
  (the only place staking actions can be triggered).
- **i18n** — a `T` dictionary with 11 languages; see [I18N.md](I18N.md).
- **Feedback** — custom success/error modals (human message first, technical detail
  collapsed), a permanent "active delegation" banner, and a one-line hint under the amount field when the
  connected wallet's main account reads 0 (Add/Create mode, amount not pre-filled).

### 2. Wallet connection (two paths)

| | Inside Nimiq Pay | Outside Nimiq Pay (regular browser) |
|---|---|---|
| Detection | `window.nimiqPay` exists | it doesn't |
| Library | `@nimiq/mini-app-sdk` (dynamic ES import from a CDN) | `@nimiq/hub-api` (script tag, pinned version) |
| Get the address | `listAccounts()` | `chooseAddress()` popup → "Connect" button |
| Send a transaction | `sendNewStakerTransaction`, `sendStakeTransaction`, `sendUpdateStakerTransaction`, `sendRetireStakeTransaction`, `sendRemoveStakeTransaction` | build with `@nimiq/core` `TransactionBuilder`, then `hub.checkout()` (signs **and** broadcasts) |
| Disconnect | n/a | "Disconnect" button |

`@nimiq/core` is loaded lazily (dynamic import, pinned version) only when a Hub staking
transaction is needed, so the heavy WASM bundle is not downloaded otherwise.

Known limitation: **claiming retired funds** (`remove stake`) is available inside Nimiq Pay
only; on the Hub path the app shows an explanatory message.

### 3. Choosing the right staking transaction

Nimiq's staking contract allows **one staker per address**, so a naive "always create a
staker" breaks on the second delegation. Before sending, the app reads
`/api/v2/staker-status` and chooses:

```
no staker on chain                          → create staker  (delegation + value)
staker exists, same validator picked        → add stake      (value)
staker exists, different validator picked   → update staker  (new delegation; moves the
                                              existing stake, does not add funds)
```

Unstaking is two steps: **retire** (choose an amount; funds become claimable after the
network's waiting period, which is tied to the end of the current epoch) and then
**claim / remove stake**.

### 4. Backend contract

The page only needs two endpoints, served from the **same origin** as the page
(relative URLs, so no CORS configuration is required):

- `GET /api/v2/validators-list?limit=200`
- `GET /api/v2/staker-status?address=<user friendly address>`

Their schemas, data sources and operational requirements are specified in the
[Operator Guide](OPERATOR-GUIDE.md).

### 5. Graceful degradation

| Situation | Behavior |
|---|---|
| Validator list unavailable | A visible error box; the page keeps working with two built-in example validators |
| Staker status unavailable (HTTP error, timeout, bad response) | Before delegating: two quick retries, then "Couldn't read your staking state" and nothing is sent; status widgets stay as last read |
| No wallet connected | Demo mode: browsing works, simulated delegation is clearly labeled as demo |
| `listAccounts()` returns an error object | Logged, the app stays disconnected (no crash) |
| Main-account balance reads 0 | Informational notice, no amount pre-fill; staking is **not** blocked (Nimiq Pay can use funds held in a swap contract) |

### 6. Safety rules encoded in the UI

- A connected wallet with an empty/zero amount **never** falls into the simulated demo path;
  it shows a validation error instead.
- The delegation amount field is pre-filled from the wallet's real spendable balance
  (`wallet_balance_luna`) when known; the retire amount from the active stake
  (`active_balance_luna`). Both remain editable.
- Errors from the wallet SDK are translated to a human message; the raw SDK message is kept
  in a collapsible technical detail for debugging.
- Every real action (delegate, retire, claim) passes a duplicate-submit guard: a synchronous lock taken
  before any promise, plus a 30-second "same action" key kept in `localStorage` (shared between open pages
  of the app and surviving a reload; fail-open if storage is blocked). One tap therefore produces one
  wallet request; a failed or cancelled action can be retried at once. The pending action is also
  recorded in `sessionStorage` and `localStorage`, so after a page reload (less than 60 s after the send)
  the waiting state and the polling are restored and only the Delegate button stays locked until the
  chain reflects the action.
- **Local storage summary.** `nimiq-miniapp-lang` (language), `vs:pending` (action in flight, session + local,
  cleared on confirmation or after 60 s) and `vs:lastActions` (up to 8 recent actions for the 30 s duplicate
  check; contains the wallet address). All local to the browser, never sent anywhere, no cookies.
- The wallet SDK can *resolve* with an error object instead of rejecting; that is treated as
  a failure (never as a success) for delegate, retire and claim.
- The app never blocks staking on a 0 main-account balance: funds held in a swap contract are
  invisible to it but usable by the wallet ([KNOWN-LIMITATIONS.md](KNOWN-LIMITATIONS.md)).

## Hard-coded, operator-specific bits

A few things in `index.html` are tied to the original deployment and should be changed by
whoever forks it. The exact steps are in the [Operator Guide](OPERATOR-GUIDE.md#6-customizing-for-your-own-validators):

- `KNOWN_VALIDATORS` and `FALLBACK_VALIDATORS` (example validators highlighted/used as fallback),
- the `og:image` absolute URL and the `demo.mp4` link,
- footer credits and contact links.

## Third-party runtime dependencies

| Dependency | How it is loaded |
|---|---|
| `@nimiq/mini-app-sdk` | dynamic `import()` from jsDelivr (Nimiq Pay path only) |
| `@nimiq/hub-api` 1.14.0 | `<script>` from jsDelivr |
| `@nimiq/core` 2.21.0 | dynamic `import()` from jsDelivr, Hub path only |
| `hub.nimiq.com` | popup opened by the Hub client |
| Google Fonts | Fraunces, Sora, Space Mono (stylesheet + font files) |

All of them must be allowed by your Content-Security-Policy — see the Operator Guide.
A future improvement is to self-host these assets to remove the CDN dependency.

## Performance notes

- No build step and no framework: the page is one request plus fonts.
- Card height is calibrated once at load (an off-screen probe measures the tallest card)
  so the action buttons don't jump while swiping.
- The browse ribbon loops endlessly in both directions.
