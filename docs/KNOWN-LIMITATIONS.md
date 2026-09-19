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
