# Changelog

All notable changes to Validator Swipe are documented here. The format is loosely based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The project has no tagged
releases yet; the current production version is 1.0.0. Older entries are grouped by date and
reconstructed from the git history.

## [Unreleased] (toward 1.1.0)

Batch of improvements under consideration for the next release, with no commitment on a date. None of these
is implemented yet.

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
- Cap the reliability figure at 100 % on the API side, if decided.

**Robustness**
- Self-host the third-party libraries (`@nimiq/mini-app-sdk`, `@nimiq/hub-api`,
  `@nimiq/core`, fonts) instead of loading them from CDNs, and pin the Mini App SDK version
  (it is currently unpinned).
- Claiming retired funds through the Nimiq Hub path (currently Nimiq Pay only).
- Read funds held in swap contracts (HTLC) on-chain, so the delegation amount can be
  pre-filled when the main-account balance reads 0.
- Automated tests and a CI check for i18n key parity and script syntax.

**Interface**
- Re-frame the view after an action (confirmation, error, closing a modal) and when the on-screen keyboard
  closes, so the "currently delegating" banner, the waiting notice, the Active stake block and the card are
  visible instead of leaving the page half-scrolled with the app title cut off. Idea: `scrollIntoView` with
  `block: 'start'` or `'center'` and a margin, taking `visualViewport` into account, without jank or
  interference with the keyboard (the page shifting up while the keyboard is open in the amount field is
  normal browser behavior). To be tested on a real phone before any release.
- When the on-screen keyboard closes (end of typing in the amount field), the page does not return to its
  previous scroll position. Idea: remember the scroll position when the amount field gets focus and restore
  it smoothly on blur or when `visualViewport` returns to full height. To be tested on a real phone.
- Planned for 1.1.0, together with the re-framing above: align the static fallback text of the
  funds-pending banner in the HTML (it still carries the older wording, invisible in normal use because the
  translation dictionary replaces it) with the current dictionary text.
- The mascot image no longer has a rounded border; a `border-radius` could be reintroduced if a rounded look is wanted.
- The "status unreadable" message could distinguish the case where no wallet address is available yet.
- The pending-confirmation banner is driven by the status polling; it could also follow the transaction directly.
- Delegation history: when the same validator was delegated to several times in a session, the
  "Delegated" badge shows on every row of that validator; only the most recent one should carry it.

**Internationalization**
- Native-speaker review of the machine-translated languages.
- Right-to-left layout (`dir="rtl"`) for Arabic.
- Fallback to English instead of French when a key is missing, and refresh a code comment
  that still mentions a French default.

**Documentation**
- Add screenshots and an animated demo to the README.

---

## [1.0.0] — 2026-09-19

First production release (the version deployed on 2026-09-19). It delivers: Add and Create stake no longer blocked
when the main-account balance is 0 (funds held in swap contracts); switching validator without an amount; the
staking state refreshed after every transaction (on-chain re-read with a visible waiting line); duplicate-send
guards (an action lock that survives a page reload, a 30-second duplicate check); a dismissible error modal;
the SDK's `ErrorResponse` handled as a failure; the oversized validator card fixed; a home page without
overflow on mobile; a "Report a bug" link; a light, cut-out, linked mascot; and up-to-date documentation.

### Added
- The footer mascot is now a link (44 px tap area, translated label) to the operator's public
  dashboard, and uses a light 96 px image (`tux-nimiq-96.png`, about 15 KB instead of 98 KB, sharp
  hexagon on a transparent background). The old `tux-nimiq.png` stays in place.
- A discreet "Report a bug" link in the footer (translated in all 11 languages) opening the GitHub
  bug-report form; the bug template now asks not to share the full wallet address.

### Hardened
- Duplicate-submit guard: one tap now produces one wallet request. A synchronous in-memory lock is
  taken before any promise in the delegate, retire and claim handlers (the button's `disabled` attribute
  alone did not stop synthetic or re-dispatched click events, which could send two transactions); it is
  released on success, error, cancellation or unreadable status, and expires on its own after 90 seconds.
  The same action (wallet, kind, validator, amount) is also ignored for 30 seconds, in the same page, in
  other pages of the app open at the same time and after a page reload (recent actions are kept in
  `localStorage`; if it is blocked only the in-memory checks apply). A failed or cancelled action can be
  retried immediately. A discreet message (translated in 11 languages) is shown when a duplicate is refused.
- A pending action survives a page reload: right before each wallet request the app records it in
  `sessionStorage` and `localStorage`. If the page is reloaded less than 60 seconds later (host refresh,
  pull-to-refresh), the "waiting for the network to confirm" notice is restored, the Delegate button stays
  locked and the polling resumes until the chain reflects the action or 60 seconds after the send. The
  record is cleared on confirmation, at the cap, and on any error or cancellation; retire and claim are
  never locked by it.
- Local storage now holds, besides the chosen language, the in-flight action `vs:pending` and the short
  list of recent actions `vs:lastActions` (wallet address included, local only, never transmitted; see the
  README and SECURITY.md).
- Connection: the Nimiq Pay SDK is initialised once per page and `listAccounts()` is called once; the
  Nimiq Hub connect button ignores a second click while connecting.

### Fixed
- The displayed staking state stayed stale after a confirmed delegation, switch, add, retire or claim:
  the app re-read the on-chain state once, immediately, but a transaction is only mined some seconds
  later, so the old delegation, stake and card modes stayed on screen until a reload. After every
  real action the app now re-reads `staker-status` 1.8 seconds after the wallet returns, then every
  2 seconds until 20 seconds, then every 5 seconds, up to a total cap of 60 seconds (about 18
  requests at most, none afterwards; the values are named constants, chosen from measured
  inclusion delays: about 1 s per block, staking transactions included 0-3 blocks after sending, with
  rare outliers of about 2 minutes), paused while the app is hidden, never in parallel, retrying at the next tick if a
  request fails, until the chain reflects the change. Each read updates the delegation banner, the
  stake block, the delegation history and the Add/Switch mode of the cards together, and a short
  notice (translated in 11 languages) tells the user the network is still confirming. It also
  re-reads when the app returns to the foreground and when a success message is dismissed. The app
  never shows a state the chain does not confirm: at the cap it keeps the last real state.
- While a confirmation is pending, only the Delegate button is disabled (browsing, favorites, retire
  and claim stay available): the displayed state is stale, so the Add/Switch mode could be wrong.
  It is re-enabled as soon as the chain confirms, or at the cap. Rapid double clicks send one
  transaction.
- If the staking state cannot be read when delegating (HTTP error, timeout, unexpected response),
  the app no longer assumes "no staker" (which made a Create fail for an existing staker): it retries
  twice quickly, then shows a clear message (11 languages) and sends nothing.
- On narrow phones (about 360-450 px) the "Technical integration" section was wider than the screen
  (its grid column was sized by long unbreakable function names, and the checklist items were
  laid out as flex rows), so the code block and the right end of the list were cut off and one
  column of text showed one word per line. The columns can now shrink, the list wraps normally, and
  the code block keeps its own horizontal scroll.
- The code sample comment was hard-coded in French on the English page; it is now in English.
- Switching validator no longer asks for an amount. The "Enter an amount to delegate" check ran
  before the app knew whether the action was a switch (update staker, which moves the whole existing
  stake and sends no value). It now only applies to Create / Add stake, and never lets a Create
  go out without an amount, including when the staker status could not be read. When the selected
  favorite differs from the current delegation, the amount field is replaced by a short explanation
  (translated in all 11 languages).
- The validator card could become huge (almost screen-high, with a large empty area) after a
  resize while the other tab was open, typically after staking from My favorites and going back
  to Browse. The card-height calibration measured a hidden (zero-width) container, wrapped the text
  one letter per line and locked an enormous minimum height. It now skips hidden containers,
  recalibrates when a tab is shown again, and ignores implausible values.
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
  release it also blocked adding new stake; that block was removed afterwards (see *1.0.0*).
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
