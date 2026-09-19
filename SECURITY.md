# Security Policy

## Security model: zero custody

Validator Swipe never holds, sees, or transmits a private key, seed phrase or password.

- **Signing happens elsewhere.** Every transaction is built by the app but *signed* inside
  Nimiq Pay (via the Mini App SDK) or in the Nimiq Hub popup (`hub.nimiq.com`). The app
  only receives the result of a signing request the user explicitly approved.
- **The app cannot move funds on its own.** Each staking action (delegate, add stake,
  switch validator, retire, claim) requires an explicit confirmation by the user in their
  wallet. Browsing and "setting aside" favorites sends nothing.
- **Delegation keeps funds under the user's control.** Staking on Nimiq does not transfer
  ownership of the funds to the validator.
- **No accounts, no cookies, no analytics.** Nothing is sent to a third party. The browser keeps
  only local values: the chosen interface language (`localStorage`), the action in flight `vs:pending`
  (cleared on confirmation or after 60 s) and a short list of recent actions `vs:lastActions` used to
  ignore duplicate taps (30 s, up to 8 entries, contains the wallet address, never transmitted, removed by
  clearing the site data). Note that the page loads fonts and libraries
  from third-party CDNs (Google Fonts, jsDelivr), which necessarily see the visitor's IP address.
- **Read-only backend.** The backend endpoints the app calls (`/api/v2/validators-list`,
  `/api/v2/staker-status`) are public, read-only lookups of on-chain data. The wallet
  address is sent to `staker-status` to read that account's public on-chain state — an
  operator's server logs will therefore see addresses that use the app.
- **Demo mode is labeled.** With no wallet connected, simulated actions are explicitly
  marked as demo and never presented as real.

### What operators are responsible for

Anyone hosting this app is responsible for serving it over HTTPS, applying a strict
Content-Security-Policy (see [docs/OPERATOR-GUIDE.md](docs/OPERATOR-GUIDE.md)), keeping the
Nimiq node and backend up to date, and re-verifying the app they serve. Because the app
handles wallet interactions, a tampered copy could mislead users: serve it only from a
domain you control and recompute the CSP script hash after every change.

## Supported versions

Only the latest release (1.0.0 or later) and the latest commit on the default branch are supported.

## Reporting a vulnerability

Please **do not open a public issue** for security problems.

1. Email **ju@nimiq-ju.fr** with the subject `Validator Swipe security`.
2. Or use GitHub's **private vulnerability reporting**
   ("Security" tab → "Report a vulnerability").

Please include a description, reproduction steps, and the potential impact. You can
expect an acknowledgement within a few days. We ask for reasonable time to fix an issue
before public disclosure, and we are happy to credit reporters who wish it.

## Scope

In scope: the code in this repository (`index.html`) and the documented deployment
guidance. Out of scope: vulnerabilities in Nimiq Pay, the Nimiq Hub, the Nimiq network,
third-party CDNs, or an individual operator's own infrastructure — please report those to
the respective owners.
