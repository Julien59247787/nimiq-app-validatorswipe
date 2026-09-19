# Changelog

All notable changes to Validator Swipe are documented here. The format is loosely based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The history starts at the first
publication, the version submitted to the Nimiq Mini Apps Competition (Cycle II) on 2026-09-18;
every change made since is listed below, with its commit, for traceability. Earlier development
work is available in the Git history.

## [Unreleased]

Ideas with no commitment on a date or a version. None of these is implemented yet.

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

**Interface**
- The mascot image has no rounded border; a `border-radius` could be added if a rounded look is wanted.
- The "status unreadable" message could distinguish the case where no wallet address is available yet.
- The pending-confirmation notice is driven by the status polling; it could also follow the transaction directly.

**Internationalization**
- Native-speaker review of the machine-translated languages.
- Right-to-left layout (`dir="rtl"`) for Arabic.
- Fallback to English instead of French when a key is missing, and refresh a code comment
  that still mentions a French default.

**Documentation**
- An animated demo in the README.

---

## [1.0.0] — 2026-09-18 — First publication (Nimiq Mini Apps Competition submission)

Submitted commit: `d205df9` (tag `competition-submission`), the state of the repository when the
submission (PR #238 of the competition's submissions repository) was merged on 2026-09-18.

### As submitted
- Every active validator with real data (uptime, reliability, reward rate, delegation fee, total
  stake), in a two-phase flow: *Browse* (pass / set aside) then *My favorites* (the only place a
  transaction can be sent).
- The complete staking lifecycle driven by the account's on-chain state (`/api/v2/staker-status`):
  create staker, add stake, switch validator, retire, then claim after the network waiting period,
  with a "My stake" block, a permanent "active delegation" banner and a delegation history.
- Nimiq Pay (Mini App SDK) and regular browsers (Nimiq Hub, transactions built with `@nimiq/core`).
- 11 languages, English by default; honest demo mode when no wallet is connected.
- Endless ribbon browsing in both tabs; validators ordered by number of available metrics;
  the retire amount pre-filled with the real active stake; an explicit placeholder on the amount field.
- A "funds pending" notice when a connected wallet reports a main-account balance of exactly 0. In
  this version it also blocked adding new stake (removed afterwards, see below).
- Known at the time: the displayed staking state was read once right after a transaction, so it could
  stay stale until a reload; switching validator asked for an amount; a duplicate tap could send twice.

### Changes since the competition submission

All dated 2026-09-19 (Paris time). Commit references are short SHAs.

**Added**
- After a tap on the star or the shield, and when a success or error message closes, the view is gently
  re-framed so the "currently delegating" banner, the waiting notice, the Active stake block and the
  validator card are visible. Nothing moves while typing, within a second of a manual scroll, while the
  keyboard restoration is pending, or when the area is hidden; with `prefers-reduced-motion` the move
  is instant (`0c9a477`).
- One discreet hint under the "Amount to delegate" field, shown only for a connected wallet whose
  main account reads 0, when the amount is not pre-filled and the card is in Add/Create mode
  (`11146f5`). It replaces the large notice and its "OK, got it" button (11 languages).
- The scroll position is remembered when the amount field gets focus and restored when the
  on-screen keyboard closes; nothing happens while typing, after a manual scroll, or without
  `visualViewport` (`9dae6a9`).
- A visible "waiting for the network to confirm" line after each transaction, with the state re-read
  from the chain until it is reflected (`d4f15e3`, `c2c4cb7`, `ee243c9`, `e4a25b5`).
- A discreet "Report a bug" link in the footer (translated in 11 languages) opening the GitHub
  bug-report form (`186ba30`).
- The footer mascot links to the operator's public dashboard and uses a light 96 px image with a
  transparent background, `tux-nimiq-96.png` (`61c2137`, `3d92cbb`).

**Changed**
- The re-framing after the star, the shield and a closing message now always aligns the top of the central card (the
  app header under the host bar) with the top of the screen, whatever is displayed below it (`1118aef`).
- Reliability is now capped at 100 % by the API (contract: a fraction between 0 and 1).
- Add and Create stake are no longer blocked when the main-account balance reads 0: funds held in a
  swap contract can be used by the wallet when staking (`c9f8aad`).
- Switching validator no longer asks for an amount (it moves the whole stake); the amount is only
  required for Create / Add, and the field is replaced by a short explanation in switch mode (`5a2987c`).
- The success message stays until dismissed instead of closing after 6 seconds (`7e3e04a`).
- Full-width buttons center their label (`17ac1b2`).
- After every transaction the app re-reads `staker-status` 1.8 s after the wallet returns, then every
  2 s until 20 s, then every 5 s, capped at 60 s (about 18 requests at most, paused while hidden,
  one chain at a time). Only the Delegate button is locked while a confirmation is pending
  (`d4f15e3`, `c2c4cb7`, `ee243c9`).

**Fixed**
- The connection pill no longer goes back to "Wallet not detected" after a language change with a wallet
  connected; the Hub "connecting" label and the delegation history badges are also kept translated (`1118aef`).
- In the delegation history, the "Delegated" badge appears on a single row: the most recent entry for the
  validator that is the current on-chain delegation; every other entry shows "Past" (`49c85e0`).
- An error object *resolved* by the wallet SDK is treated as a failure instead of a success (`c9f8aad`).
- The displayed staking state no longer stays stale after a confirmed transaction (`d4f15e3`).
- The validator card no longer takes an oversized height after a resize while the other tab is shown (`8651b46`).
- The "Technical integration" section fits narrow phones; the code sample comment is in English (`4ac7784`).
- The mascot's white background is cut out (`3d92cbb`); a double-encoded UTF-8 text is repaired (`b14dce6`).
- The error message can be dismissed with OK, a tap outside or Escape (`2419906`).

**Hardened**
- One tap produces one wallet request: a synchronous action lock taken before any promise, a 30-second
  duplicate check kept in `localStorage` (shared by open pages and surviving a reload), and a single
  SDK initialisation / `listAccounts()` call per page (`f2091d2`, `bb01104`).
- A pending action survives a page reload: it is recorded in `sessionStorage` and `localStorage`
  (`vs:pending`) and, if the page reloads within 60 seconds, the waiting line and the polling resume
  and the Delegate button stays locked until the chain reflects the action (`bb01104`).
- If the staking state cannot be read when delegating, the app retries twice, then shows a message and
  sends nothing, instead of assuming there is no staker (`c2c4cb7`).
- Local storage holds the chosen language, `vs:pending` and `vs:lastActions` (up to 8 entries, wallet
  address included, local only, never transmitted); see the README and SECURITY.md (`e8f605b`).

**Documentation**
- Full documentation set: README with screenshots, architecture, i18n and operator guides, known
  limitations, contributing, security and community files (`8ea8be5` to `33a8e5d`), then updated to
  describe the released behavior.
