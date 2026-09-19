# Changelog

All notable changes to Validator Swipe are documented here. The format is loosely based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The project has no tagged
releases yet; entries are grouped by date and reconstructed from the git history.

## Unreleased

### Fixed
- Adding or creating a stake is no longer blocked when the main-account balance reads 0. A
  real-device test showed Nimiq Pay accepting an Add Stake with funds held in a swap contract
  (HTLC), so the guard refused a flow that works. The "funds pending" notice is now purely
  informational (reworded in all 11 languages).
- An error object *resolved* by the wallet SDK (instead of a rejection) is now treated as a
  failure for delegate, retire and claim, instead of showing a false success.
- The "pre-filled with your available balance" hint only appears when the amount was actually
  pre-filled, and disappears once you edit it.
- The success message no longer closes by itself after 6 seconds: it stays until the user
  dismisses it with "OK" (like error messages).
- Full-width buttons (the "OK" of the message dialogs, "Confirm withdrawal") now center their label.

## 2026-09-18 — Competition submission, final polish

### Documentation
- Full documentation set: expanded README with screenshots, architecture, i18n and operator
  guides, known limitations, contributing, security and community files.

### Added
- Link to the recorded demo video in the hero section.
- "Funds pending" hint: when a connected wallet reports a spendable balance of exactly 0
  (typically funds held in a swap contract after a top-up), the app explains it. In this
  release it also blocked adding new stake; that block was removed afterwards (see *Unreleased*).
- Retire-amount field is pre-filled with the real active stake and styled like the
  delegation amount field.
- Endless ribbon browsing in both tabs (Browse and My favorites), in both directions; the
  back button animates like forward swipes.
- Explicit, translated placeholder on the delegation amount field.

### Changed
- Validators are ordered by number of available metrics (uptime / reliability / reward,
  3 down to 0), then alphabetically, so the order is stable from run to run.
- Validator names prefer the name published by the API, falling back to a hard-coded name,
  then to a shortened address.
- Card height is calibrated once at load to the tallest expected card so the action buttons
  no longer jump when swiping.
- Yellow border on the Browse / My favorites tab buttons (they were invisible on dark backgrounds).

### Fixed
- **Critical:** with a wallet connected but no amount entered, the app fell through to the
  simulated demo path and showed a fake "delegation successful" with confetti although
  nothing had been sent. A connected wallet with an empty/zero amount now stops with a
  validation error; the pure demo path (no wallet at all) is clearly labeled as demo mode
  in all 11 languages and no longer touches the real delegation banner.
- Demo-mode success message no longer contradicts itself.
- Hero section lost its horizontal padding (a CSS shorthand overrode the shared wrapper),
  leaving the top of the page flush against the screen edges on mobile.
- Placeholder text on the gold-styled amount field was unreadable (browser default opacity).
- Meta description was still in French while the rest of the app defaulted to English.

## 2026-09-17 — Real staking cycle, Hub support, English by default

### Added
- **Full staking lifecycle**: retire stake, then claim (remove stake) after the network
  waiting period; "My stake" block showing active / inactive / retired balances from
  on-chain data; permanent "active delegation" banner and a delegation history.
- Existing stakers are detected (`/api/v2/staker-status`) so the app chooses between
  create staker, add stake and update delegation (see [ARCHITECTURE.md](docs/ARCHITECTURE.md)).
- **Nimiq Hub support outside Nimiq Pay**: "Connect" / "Disconnect" buttons; staking
  transactions built with `@nimiq/core` and signed + broadcast through the Hub.
- Delegation amount pre-filled from the wallet's real spendable balance
  (`wallet_balance_luna`).
- Wallet status badge, dedicated wallet bar, language switcher moved next to the app name.
- Open Graph / meta description tags and a 1200×630 `og:image`.
- Waiting-period messages for unstaking, phrased around the end of the current epoch
  rather than a fixed duration.

### Changed
- **English is now the default language** (manual choice, then Nimiq Pay's language, then English).
- Visual identity aligned with the Nimiq logo: blue plus official Nimiq gold accents.
- Mobile layout: cards flow naturally (no dead space), full-width phone view with a small gutter.
- Uniform "Validator" tag for all validators (no special styling for the team's own nodes).

### Fixed
- Second delegation failed with "Transaction invalidated" (a Nimiq address can hold only one
  staker) — solved by the state-aware transaction choice above.
- `listAccounts()` can resolve with an error object instead of an array; now handled.
- Horizontal jitter on mobile (`overflow-x: hidden`), truncated shield icon, stale
  "technical integration" text, unused translation keys.
- 16 translation keys were missing in 9 languages; added (see [docs/I18N.md](docs/I18N.md)).

### Removed
- Hard-coded default delegation amount of 100 NIM (a 20 NIM wallet would fail by default).
- Temporary on-screen debug banner used to investigate a wallet-balance issue.

## 2026-09-16 — Error handling and unstake groundwork

### Added
- Human-readable error messages (the raw SDK error is kept as collapsible technical detail),
  custom error and success modals, balance hint before delegating.
- "Retire stake" and claim flows, gold accent, star icon for favorites, forward navigation
  in both tabs.
- Ready to display the validator's published name once exposed by the API.

### Fixed
- Broken Discord badge replaced by a plain text link; misleading CTA label; validator-list
  loading errors are now visible in the UI.

## 2026-09-14 — Translations and branding

### Added
- Manual language switcher (French / English), then the 9 remaining languages: es, zh, ja,
  ko, de, pt, ru, tr, ar (11 in total, machine-translated).
- "Made with love" credit footer and project mascot.

### Changed
- Color palette aligned with the project logo.

## 2026-09-13 — Full validator list and two-phase flow

### Added
- The complete list of active validators (39 at the time of writing) instead of two, with real uptime,
  reliability, reward rate and fee.
- Browse-then-decide flow: *Browse* (set aside, free) and *My favorites* (delegate).
- MIT license and a first README.

## 2026-09-12 — Initial version

### Added
- First version of the mini app: validator cards, swipe interaction, French/English i18n,
  stake amount field, real delegation through the Nimiq Pay SDK.

---

## Future improvements

Ideas that would make the app easier to reuse and harden. None of these are implemented yet.

**Configurability (for other operators)**
- Move `KNOWN_VALIDATORS` / `FALLBACK_VALIDATORS` out of `index.html` into an external
  configuration file or served endpoint, so an operator can list their own validators without
  editing the page — and without invalidating the CSP script hash.
- Make the site URL, `og:image`, demo-video link, footer credits and contact links
  configurable in one place (currently hard-coded to the original deployment).
- Generate the CSP script hash automatically as part of a deployment script.

**Backend**
- Publish a clean, secret-free reference implementation of the two endpoints and the daily
  refresh job (currently only specified by contract in the
  [Operator Guide](docs/OPERATOR-GUIDE.md)).

**Robustness**
- Self-host the third-party libraries (`@nimiq/mini-app-sdk`, `@nimiq/hub-api`,
  `@nimiq/core`, fonts) instead of loading them from CDNs, and pin the Mini App SDK version
  (it is currently unpinned).
- Claiming retired funds through the Nimiq Hub path (currently Nimiq Pay only).
- Read funds held in swap contracts (HTLC) on-chain, so the delegation amount can be
  pre-filled when the main-account balance reads 0.
- Automated tests and a CI check for i18n key parity and script syntax.

**Internationalization**
- Native-speaker review of the machine-translated languages.
- Right-to-left layout (`dir="rtl"`) for Arabic.
- Fallback to English instead of French when a key is missing, and refresh a code comment
  that still mentions a French default.

**Documentation**
- Add screenshots and an animated demo to the README.
