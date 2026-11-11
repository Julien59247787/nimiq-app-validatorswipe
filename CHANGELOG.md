# Changelog

All notable changes to Validator Swipe are documented here. The format is loosely based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). The history starts at the first
publication, the version submitted to the Nimiq Mini Apps Competition (Cycle II) on 2026-09-18;
every change made since is listed below, with its commit, for traceability. Earlier development
work is available in the Git history.

## [1.1.5] — 2026-11-11

- **Correction of 1.1.4.** The note shown when everything is staked said that Nimiq Pay "may keep" the received NIM
  in a swap contract for up to 14 days. That was wrong: in Nimiq Pay the swap contract (HTLC) is the normal spending
  account; payments are made from it and Nimiq Pay renews it before its timeout (`src/stores/sync/htlc.ts`,
  `extendValidity`). The received NIM stay spendable as usual. Fixed in the 11 languages and in the documentation.
- The footer version link pointed to 1.1.3 in 1.1.4; it now shows 1.1.5.
- **A reserve of 5 NIM stays spendable in Nimiq Pay.** Create and Add stake can no longer empty the Nimiq Pay swap
  contract, so Unstake, Finish unstaking and Switch (value 0, fee 0, sent from that contract) keep reaching the chain.
  The reserve is not spent by them; it only has to stay above 0 (1 NIM would do, 5 NIM leaves a margin for fees or
  dust). The spendable balance is read from Nimiq Pay itself (`listAccounts` gives the local account and the swap
  contract, `getBalance` their balances, Nimiq Pay 2.22.1 and later): the amount is pre-filled with balance minus
  reserve, a **Max** button gives the same value, a larger amount is refused before anything is sent, and a line
  explains the reserve (11 languages). If the balance cannot be read, nothing is pre-filled or refused from it.
  Outside Nimiq Pay (Nimiq Hub) there is no swap contract and no reserve.
- **Current block height from Nimiq Pay.** When the API gives no `block_number`, the app reads the height with
  `getBlockNumber`, so the blocks left and the disabled "Finish unstaking" / Switch until the unlock also work with
  the current backend.

## [1.1.4] — 2026-11-11

- **Real lock duration.** The texts said "about 12 hours"; the real wait is **12 to 24 hours**: the unstaked amount
  counts as inactive from the next election block (`inactive_from`, end of the current epoch, up to about 12 hours
  away), then stays locked one more epoch (43,200 blocks, about 12 hours). Fixed in the 11 languages. When the API
  gives the current block height, the unlock note also shows an estimated local date and time (one block per second).
- **Free NIM needed when everything is staked.** Nimiq Pay sends Unstake, Finish unstaking and Switch from its swap
  contract; when that contract has been emptied (everything staked), the request never reaches the chain. Proved on
  2026-11-11: after receiving 50 NIM, Nimiq Pay moved them into a new swap contract (its normal spending account)
  and the same Unstake was executed.
  The app now says so (information only, nothing is blocked) when the wallet's free balance is 0.
- Known: "Finish unstaking" and Switch are disabled until the unlock **only if** the API gives `block_number`; the
  production backend does not give it yet.

## [1.1.3] — 2026-11-11

Unstake and Switch now follow the staking protocol; the staker state no longer flips; no success or failure is
claimed that the chain has not shown.

### Fixed

- **Unstake (was "Retire my stake") never worked.** The app sent *RetireStake* with an amount of the ACTIVE stake,
  but the staking contract only retires INACTIVE stake whose lock-up is over (core-rs-albatross v2.3.0, `primitives/account/src/account/staking_contract/staker.rs`, `retire_stake`:
  `InsufficientFunds` / `InvalidForRecipient`). Unstaking is now the protocol's three steps, in the same order as
  Nimiq's own example Mini App (`mini-app-sdk/dapp/src/components/Staking.vue` in the Nimiq Pay repository):
  **Unstake** = *SetActiveStake* (the amount becomes inactive and stays locked about one epoch, about 12 hours),
  **Finish unstaking** = *RetireStake* of the inactive balance once the lock is over, **Claim my funds** =
  *RemoveStake*. A new Unstake is refused while one is in progress (it would restart the lock).
- **Switch validator never worked while the stake was active.** *UpdateStaker* fails when the staker has active
  stake (core-rs-albatross v2.3.0, `primitives/account/src/account/staking_contract/staker.rs`, `update_staker`: "All stake must be inactivated or retired before re-delegating"). The app now explains
  the two steps instead of sending a transaction doomed to fail, and sends *UpdateStaker* with `reactivateAllStake`
  once the stake is inactive and unlocked. The September failures of Switch and Retire (included, execution result
  false) are explained by this, not by the swap contract (HTLC) or the Nimiq Pay cosigner as the earlier
  documentation supposed. **Our reports to the Nimiq Pay team in September were wrong on this point**: those
  failures came from our use of the protocol, not from Nimiq Pay.
- **The real unlock is shown.** While unstaking, the app shows the block at which the inactive stake unlocks
  (`inactive_from` from the chain plus one epoch of collateral lock-up, 43,200 blocks on mainnet: `Policy::
  block_after_collateral_lockup` in core-rs-albatross `primitives/src/policy.rs`). If the API also gives the current
  block height (optional `block_number` in `staker-status`), it shows the blocks left and keeps "Finish unstaking"
  and Switch disabled until then; no duration is invented.
- **Staker state flipping, Create offered instead of Add, Create offered again after a successful Create, the
  "active stake" banner missing at launch.** On 2026-11-11 one of the two nodes behind the round-robin answered
  `found: false` for a staker that the other node and the chain know (reported to the operator). The app now numbers
  its staker-status requests and ignores answers older than the last one applied, keeps a staker seen in the session
  unless several answers in a row say otherwise (or its stake can legitimately have disappeared), reads a "no staker"
  answer again before a Create, and reads it again shortly at launch.
- **"Withdrawal initiated!" shown for a transaction that never reached the chain.** An empty (`found: false`)
  answer made "active stake lower than before" true. Only a `found: true` answer can now confirm an action, or the
  `tx-status` endpoint reporting the transaction executed on the chain.
- **An Add executed on the chain was reported as failed.** Nimiq Pay can answer an error although the transaction
  went through (2026-11-10). An unknown outcome (code `-32001`, or `-32603` other than "invalidated") is no longer
  called a failure: the app says Nimiq Pay could not confirm whether it was sent, asks not to send it again and to
  check Nimiq Pay, keeps the lock and keeps watching the chain.
- Label: "Retire my stake" becomes **Unstake**, in echo to Stake (11 languages). The message that said "Nimiq Pay
  currently rejects this action for some wallets" is removed (it was wrong); a rejected Switch or Finish unstaking
  now says the lock may not be over yet.
- The displayed version is v1.1.3 (`scripts/check-version.sh v1.1.3`). The inline script changed: the CSP hash of
  the script changes.

### Known limitations

- Create stake and Add stake from a wallet whose funds are in a swap contract were **executed on the chain on
  2026-11-10** (Nimiq Pay 2.22.x, app 1.1.2 with the SDK pinned to 0.1.0): Create 200 NIM, block 66516076; Add
  50 NIM, block 66517911. Whether this comes from the pinned SDK or from a Nimiq Pay update is not established, so
  the pin is kept.
- The new Unstake, Finish unstaking and Switch flows were tested only against a local mock, **not yet on a device**.
- Still open on the Nimiq Pay side, to be re-tested with the correct requests: Create stake from a swap contract
  built by merging several transfers (failed in September; not re-tested since), and Unstake from a wallet whose swap
  contract is empty (in September and on 2026-11-10 Nimiq Pay sent nothing for the old, invalid requests; not yet
  tried with the new, valid ones).

## [1.1.2] — 2026-10-22

Test release: the Mini App SDK loaded by the page is pinned to 0.1.0.

### Changed

- `@nimiq/mini-app-sdk` is now imported as `@nimiq/mini-app-sdk@0.1.0` instead of the latest published version (the page used to import the
  unpinned package). This is the **test of one hypothesis, not a fix**: the unpinned SDK moved from 0.1.0 to 0.2.0 on 2026-09-21 and to 0.2.1 on
  2026-09-22, shortly before Create stake from a swap contract started failing on 2026-09-23 (see the next entry); it is at 0.2.4 today.
  The coincidence in time is not evidence of a cause: the Nimiq Pay version did not change and the error message comes from the host side.
  The app only uses `init`, `listAccounts` and the five `send...Transaction` methods, none of the functions added in 0.2.x
  (`NimiqProviderError`, `getBalance`, `requestDeviceIdentifier`, ...). With 0.1.0, `init()` returns the host provider itself; 0.2.x returns a
  wrapper object. If Create stake still fails with 0.1.0, the SDK track is ruled out; if it works again, keep the pin and report it to the Nimiq Pay team.
- The inline script changed, so the Content-Security-Policy hash of the script changes: operators must update it ([Operator Guide](docs/OPERATOR-GUIDE.md), section 3.4).
- The displayed version is v1.1.2 (`scripts/check-version.sh v1.1.2`).
- 2026-09-23: **Create stake regression, confirmed on-chain.** Create now fails even from a swap contract (HTLC)
  created by a single transfer (2 new wallets, 2 failures out of 2, same raw error and no transaction reaching the
  chain), which had worked reliably from 2026-09-16 to 2026-09-20 (3 successes out of 3 in the same conditions).
  Nimiq Pay's version is unchanged (v2.19.1); this coincides with two Mini App SDK releases (0.2.0 on 2026-09-21,
  0.2.1 on 2026-09-22), read and found to be a client-side wrapper change only — a coincidence in time, not a proven
  cause. No code change in the app; documentation updated ([docs/KNOWN-LIMITATIONS.md](docs/KNOWN-LIMITATIONS.md),
  [README.md](README.md)) to withdraw the "passes from a single transfer" and relay-wallet-workaround claims until
  reconfirmed.

## [1.1.1] — 2026-09-21

Footer status and description updated; app version shown; audit of displayed text.

### Changed

- Footer status, in 11 languages: "Live on mainnet: real validator data, real delegation inside Nimiq Pay" replaces
  "interactive demo, real validator data", which was no longer true (delegation is real inside Nimiq Pay; it is
  simulated only when no wallet is connected).
- Footer description, in 11 languages: "Built for the Nimiq Mini Apps Competition (Cycle II). Open source, made for
  Nimiq Pay." replaces "Open prototype, no backend" (the app uses the operator's `staker-status`, `validators-list`
  and `tx-status` endpoints) and the competition dates.
- The retire explanation, in 11 languages, no longer says the second step (claiming the funds) is "upcoming": it
  exists.
- Operator Guide: the optional `tx-status` endpoint is documented (it was missing, and the guide said only two endpoints
  are called); `demo.mp4` is stated to be a stable public URL replaced on the nodes without an app release.

### Added

- The app version (`v1.1.1`) is shown, small, at the bottom of the page next to "Report a bug", and links to its
  GitHub release.
- `scripts/check-version.sh`: fails when the displayed version, its link and the newest dated CHANGELOG entry differ;
  added to the release checklist in [docs/TESTING.md](docs/TESTING.md).

### Audit of displayed text

Also fixed after the audit:

- "Outside Nimiq Pay, the delegation is simulated unless you connect a wallet with Nimiq Hub" replaces "stays
  simulated" in the technical section and the sample-data note (11 languages); the Hub path is still not tested end to end.
- The static French copy of the hero button now reads "Voir les validateurs" like the dictionaries (it was "Essayer la
  démo", which no longer matched the button).
- README: the lifecycle summary points to "Known issues and workarounds" for Switch and Retire; the section
  "Verification status (version 1.0.0)" of `docs/KNOWN-LIMITATIONS.md` is now "Verification status (current)" and
  every link to it is updated.

Checked and left as is: the header chip naming the competition (the origin of the app), "you can withdraw it whenever you
  want" (it describes that the validator never holds the funds; the rejection message and Known issues cover Nimiq Pay),
  and the "~40 validators, refreshed daily" figure (it comes from the API).

## [1.1.0] — 2026-09-21

The batch of the next release: remembered favorites, the write lock, honest confirmation, detection of a transaction
rejected by the network, and help messages.

### Added

- Help messages. A Create that fails with "Transaction invalidated" shows a dedicated text (new key
  `app.createNeedsSingleTransfer`, technical detail kept) explaining that the NIM must come from a single transfer and
  the relay-wallet workaround; Add, Switch and Retire keep their messages. The "network rejected" message adds, for
  Switch and Retire only, "Nimiq Pay currently rejects this action for some wallets. Your stake is safe. We've reported
  it to the Nimiq Pay team." (new key `app.txRejectedNimiqPay`), with no workaround. 11 languages. The README and
  [docs/KNOWN-LIMITATIONS.md](docs/KNOWN-LIMITATIONS.md) get a "Known issues and workarounds" section.

- A transaction that the network rejects is now detected. The hash returned by the wallet is kept in the pending
  record and the page asks the optional same-origin endpoint `GET /api/v2/tx-status?hash=` at each poll tick. When the
  transaction is included, rejected at execution and has at least 2 confirmations, the page shows "The network
  rejected this transaction. Nothing was changed." (11 languages, new key `app.txRejected`) and lifts the lock
  automatically (safe: value 0, nothing to duplicate). Any other answer, or no endpoint, leaves the previous behavior
  (waiting, "Still not confirmed", manual "Not sent? Unlock"). See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

- Favorites survive closing and reloading the app: the public addresses of the favorite validators are kept in
  `localStorage` (`vs:favorites`, in order, at most 50, never the wallet address), restored once the validator list
  has loaded, kept in sync between open pages, and never purged while the list is only the built-in fallback.
  Independent of the wallet and kept in demo mode (`37eadec`).

### Fixed

- **One blockchain write at a time.** A single lock now covers create, add, switch, retire and claim: it is recorded
  before the wallet request (`vs:pending`), shared between open pages through `localStorage`, kept across reloads,
  and disables every button that sends a transaction (browsing stays free) with a persistent message. It is lifted
  only when the chain reflects the action, when the page that owns it gets an error or a cancellation, when the wallet
  changes, or through an explicit "Not sent? Unlock" button. The waiting message is progressive: "Waiting for the
  network to confirm your transaction…" for 15 seconds, "This is taking a bit longer than usual…" up to 60 seconds
  (`82858ad`), then "Still not confirmed. The network may be slow, or the transaction may not have been sent. Wait a
  little longer, or unlock to try again." (`089e2c1`). The "Not sent? Unlock" button is Nimiq orange with dark text so that
  it cannot be missed (`089e2c1`). While not confirmed the buttons stay disabled, the chain
  is re-read every 15 seconds for up to 10 minutes, and the user is never locked in for good. Previously only the
  Delegate button was locked (`7855fa6`).
- The delegation history records an action only once the chain reflects it, instead of when the wallet returned;
  an action that the chain never reflects (never included, or rejected at execution) no longer leaves a row or a
  "Delegated" badge (`7855fa6`).
- The success message ("Delegated!", "Switched!", retire, claim) and the confetti no longer appear when the wallet
  answers "success" to the request: they appear only once the chain reflects the action (the wallet can answer
  "success" for a transaction that is rejected at execution or never included). Until then only the persistent
  waiting message is shown
  (`2781943`).
- An action no longer removes the validator from My favorites, neither when it is sent nor when it is confirmed
  (including in demo mode): a validator leaves the favorites only when the user removes its star, so adding stake
  later does not require selecting it again in Browse (`eb092e0`).
- Disabled buttons ("Claim my funds", "Confirm withdrawal", other `.btn` buttons) now look disabled (`2781943`).
- The error "Transaction invalidated during transaction" no longer claims a conflict with a stake in progress: the
  message now says Nimiq Pay rejected the transaction, with the raw detail kept (`7855fa6`).

### Known limitations

- Switch validator (UpdateStaker) and Retire (RetireStake) in Nimiq Pay are **not verified**; two behaviors were
  observed on the chain (Nimiq Pay v2.19.1, 2026-09-16 to 2026-09-20). On an Android 16 phone, from a swap contract
  (HTLC) that still holds funds, they are included in a block but rejected at execution (execution result false, no
  state change; more than 30 occurrences), while Create and Add from a swap contract succeed. On an Android 13
  emulator, with wallets whose swap contract had been entirely spent by the previous Create and Add, no transaction
  reaches the chain and Nimiq Pay shows "Pending". Nimiq Pay's history is not proof of a state change, so earlier
  "verified" statements for Switch are withdrawn. Hypothesis, not proven: Nimiq Pay sends them from a swap contract;
  if it exists the transaction is rejected, if it no longer exists nothing is sent (open question: a user who has
  staked everything). No workaround in the app. See [docs/KNOWN-LIMITATIONS.md](docs/KNOWN-LIMITATIONS.md).

- Create stake fails ("Transaction invalidated during transaction", nothing on the chain) when the wallet's funds
  sit in a swap contract built by merging several transfers; it passes from a contract created by a single
  transfer, in full or partially, and Add stake works from a merged contract. Observed in our tests on an Android 13
  emulator and an Android 16 phone, Nimiq Pay v2.19.1 on both (the host also raises a native notification with the
  same text); the cause on the host side is not established. See
  [docs/KNOWN-LIMITATIONS.md](docs/KNOWN-LIMITATIONS.md#create-stake-from-a-swap-contract-htlc-failed-in-september-executed-on-2026-11-10)
  (status updated 2026-09-23: this no longer passes reliably from a single transfer either, see the 1.1.x entries above).

### Ideas

Ideas with no commitment on a date or a version. None of these is implemented yet.

**Candidate work for a patch release**
- Obtain the height of Nimiq Pay's top bar from the host team to calibrate the re-centring, instead of relying on
  `env(safe-area-inset-top)` being reported.
- Pin the Mini App SDK version (done in 1.1.2 as a test: 0.1.0).
- Operator note: with several nodes answering in turn, per-node `ETag` values differ, so conditional requests
  (`304`) do not hit; see the [Operator Guide](docs/OPERATOR-GUIDE.md).

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
  `@nimiq/core`, fonts) instead of loading them from CDNs.
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
  with a "My stake" block, a permanent "active delegation" banner and a delegation history. These flows are
  implemented; Switch and Retire were later found not to work reliably in Nimiq Pay (see Known limitations under
  1.1.0).
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
- Safe re-centring on explicit gestures: a tap on Browse, on My favorites or on the app title (now a button, with a
  translated label in 11 languages) places the central card just under the host's top bar, using the height
  reported by `env(safe-area-inset-top)` plus an 8 px margin. Nothing moves when the height is unknown, while typing
  or while the keyboard scroll restoration is pending; after a swipe it waits until the page has stopped scrolling
  (nothing moves if it never settles); and it is refused when it would push the row of back / pass / star / next
  buttons below the safe line (`dee7d2c`, `a3407fd`).
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
  connected; the Hub "connecting" label and the delegation history badges are also kept translated (`1118aef`). The pill is now derived from the real connection state and refreshed whenever the staking state renders or a pending action resumes (`4662161`).
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
  limitations, contributing, security and community files (`8ea8be5` to `33a8e5d`).
- Brought up to date with the released behavior: `docs/KNOWN-LIMITATIONS.md` rewritten with a
  verification-status table for 1.0.0 and the Nimiq Pay measurements; new `docs/TESTING.md` (manual test
  plan) and `docs/HOT-DEPLOY.md` (runbook for reloading a node without dropping connections);
  README, architecture and operator guide aligned; storage and privacy statements corrected.
