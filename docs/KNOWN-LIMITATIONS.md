# Known limitations and verification status

This page lists what the app does not do, what depends on the environment, and — precisely —
what has and has not been verified on a real device. Anything not listed as verified should be
treated as untested.

## Verification status (version 1.0.0)

Real-device checks were made on one Android phone running Nimiq Pay (Android 16, WebView/Chrome
152, device pixel ratio 2) against Nimiq mainnet with real funds, and in desktop and mobile
browser emulation with a mock backend. The manual test plan is in [TESTING.md](TESTING.md).

| Flow | Status |
|---|---|
| Browse validators, favorites, delegation history | Verified on device |
| **Add stake** (existing staker, same validator), including with a main-account balance of 0 and funds held in a swap contract | Verified on-chain on device |
| **Switch validator** (update staker) | Verified on-chain on device |
| Complete cycle create / add / switch / retire / claim | Verified on device with real funds for the competition submission; retire and claim were **not** replayed end to end with the final 1.0.0 build |
| **Create stake** (a first stake) with funds held in a swap contract | **Not tested end to end** |
| Wallet rejection or cancellation, SDK `ErrorResponse` resolved instead of rejected | Verified on device (error message shown, action can be retried) |
| Duplicate taps, page reload while a transaction is pending | Verified in browser emulation; reload behavior checked on device |
| Connection through Nimiq Hub (browser or hardware wallet such as Ledger) | Implemented, **not tested end to end** on mobile browsers or with a hardware wallet |
| Languages other than French and English | Machine-generated, not reviewed by native speakers |

## The main-account balance can read 0 while Nimiq Pay shows funds

**What you see.** A wallet that has been topped up through a swap (for example by buying NIM
inside Nimiq Pay) can show a balance of **0** in Validator Swipe: the amount field is not
pre-filled and a one-line hint under it says that the available balance is shown in Nimiq Pay.

**Why.** Funds received through a swap are held in a swap contract (an HTLC, *hash time-locked
contract*) — a mechanism Nimiq Pay uses on purpose — before they reach the wallet's basic account.
The app can only read the **basic-account balance** (`wallet_balance_luna` from the backend, see
the [Operator Guide](OPERATOR-GUIDE.md#12-get-apiv2staker-statusaddressnq-address)), so funds sitting
in a swap contract do not appear in it. Nimiq Pay can nevertheless use them when staking. Nimiq
describes the swap mechanism in its article *"What ACTUALLY happens when you swap in the Nimiq Wallet"*.

**What the app does.** It does not pre-fill the amount (it cannot know it: type it yourself),
shows the one-line hint, and never blocks browsing, staking, switching validator, retiring or
claiming. If the wallet cannot fund a transaction it rejects it and the app shows the wallet's
error message.

## Transactions that stay "Pending" in Nimiq Pay

Observed on two Android emulator wallets (Nimiq Pay in an emulator, mainnet, real funds): after a first stake was
created and topped up, an *Update Staker* (switch) and a *Retire Stake* sent from the app stayed "Pending" in
Nimiq Pay and were **not on the chain** eight minutes later, while the create and add transactions had been
confirmed within about 2 seconds. The cause is not established (host or network side; the app only receives a
transaction hash or an error from the SDK and cannot see the host's pending state). What the app does about it: a
single write lock keeps every button that sends a transaction disabled until the chain reflects the previous
action; after 60 seconds it shows "Not confirmed yet — check Nimiq Pay before trying again", keeps the buttons
disabled, re-reads the chain every 15 seconds for up to 10 minutes, and offers an explicit "I checked in Nimiq Pay,
continue" button. Check the transaction in Nimiq Pay before continuing.

## Create stake from a swap contract (HTLC): merged contracts fail

Observed in our tests (Android 13 emulator, Nimiq Pay, Nimiq Pay version unknown, mainnet, real funds; dates
2026-09-16 to 2026-09-20). The wallet held its funds in a swap contract (HTLC) and a first stake (**Create stake**)
was sent from the app:

| Contract funding the wallet | Amount sent | Result |
|---|---|---|
| 100 NIM received in a single transfer | 100 NIM (all of it) | Passes (phone, 16 Sep; emulator, 19 Sep) |
| 200 NIM received in a single transfer | 100 NIM (partial spend) | Passes (19 Sep) |
| 520.16415 NIM built from several transfers merged by Nimiq Pay | 50, 5 and 1 NIM, two validators, on the production page, a build without locks, the exact 16 Sep version and after a full restart | **Fails** |
| 30.00000 NIM built from two transfers (20 then 10; Nimiq Pay returned the old contract and created a larger one) | 30 NIM (all of it) | **Fails** |

The error is always the raw message "Failed to send payment transaction: Transaction invalidated during
transaction" (code -32603), and no transaction reaches the chain. **Add stake** worked from a contract of the
same kind.

**Conclusion (cautious).** In these tests only contracts produced by merging several transfers fail at Create
(the amount, the decimals and a partial spend are ruled out). The cause on the Nimiq Pay side is not established
and should be confirmed with the host team. **Workaround observed twice (not a guarantee):** withdraw the funds to
another address and send them back in a single transfer before the first Create.

The app reports the failure as "Nimiq Pay rejected the transaction" and keeps the raw detail; it does not
describe it as a stake conflict.

## Nimiq Pay measurements and host behavior

- **Confirmation delay.** Blocks are about 1 second apart and a staking transaction is usually
  included about 2 blocks after it is sent (median; at most about 3), with rare outliers of about
  2 minutes. The app re-reads the chain for up to 60 seconds and then keeps the last state it could
  confirm. The transaction history shown by a wallet app may lag behind the chain by up to a minute.
- **SDK errors.** The Mini App SDK's `send*Transaction` promises can *resolve* with an error object
  instead of rejecting; the app treats that as a failure.
- **Host bar and scrolling.** Inside Nimiq Pay the host's browser bar can overlay the top of the
  page. On the test phone `env(safe-area-inset-top)` reported **51 CSS px**. The app scrolls the
  page in two cases only: to restore the position after the on-screen keyboard closes, and, on a tap
  on Browse, My favorites or the app title, to place the card at that inset plus 8 px. The
  re-centring is skipped when the host does not report the inset, and refused when it would push
  the card's buttons under the Android navigation bar, so it may do nothing on small screens or
  with the retire panel open. The browser itself may also nudge the card into view after a tab tap.
  Placement can differ on other devices or Nimiq Pay versions.

## Other limitations

- **Claiming retired funds** (*remove stake*) is available inside Nimiq Pay only; on the Nimiq Hub
  path the app shows an explanatory message.
- **Waiting period.** Unstaking is a two-step process: after *retire*, funds become claimable once
  the current network epoch has ended. This usually takes several hours, depending on when in the
  epoch you retire. The app deliberately gives no fixed duration.
- **Right-to-left layout** is not implemented: Arabic is displayed with a left-to-right layout.
- **Third-party CDNs.** Libraries and fonts are loaded from CDNs (jsDelivr, Google Fonts), so the
  page depends on their availability and they see visitors' IP addresses. The Mini App SDK
  version is not pinned.
- **Statistics coverage.** Uptime, reliability, reward rate and fee depend on the operator's data
  source; validators without enough history show "—" for missing values. Reliability is capped at
  100 % by the reference API.
- **Local storage.** The app keeps the chosen language, the action in flight and a short list of
  recent actions (with the wallet address) in the browser only; see the
  [Architecture](ARCHITECTURE.md#6-safety-rules-encoded-in-the-ui) summary.

## Candidate work for a patch release (no commitment)

- Obtain the height of Nimiq Pay's top bar from the host team, so the re-centring can be calibrated
  instead of relying on `env(safe-area-inset-top)` being reported.
- Pin the Mini App SDK version (and, later, self-host the libraries).
- Deployment note for operators: with several nodes answering in turn, per-node `ETag` values differ,
  so conditional requests (`304`) do not hit; serve identical files and disable or align the
  `ETag` (see the [Operator Guide](OPERATOR-GUIDE.md)).
- Read swap-contract balances on-chain so the amount can be pre-filled when the main-account balance reads 0.

The full list of ideas is under *Unreleased* in the [changelog](../CHANGELOG.md#unreleased).

Have a limitation to report? Please [open an issue](https://github.com/Julien59247787/nimiq-app-validatorswipe/issues/new/choose).
