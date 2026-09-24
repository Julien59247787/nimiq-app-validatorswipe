# Known limitations and verification status

This page lists what the app does not do, what depends on the environment, and — precisely —
what has and has not been verified on a real device. Anything not listed as verified should be
treated as untested.

## Verification status (current)

Real-device checks were made on one Android phone running Nimiq Pay (Android 16, WebView/Chrome
152, device pixel ratio 2) against Nimiq mainnet with real funds, and in desktop and mobile
browser emulation with a mock backend. The manual test plan is in [TESTING.md](TESTING.md).

| Flow | Status |
|---|---|
| Browse validators, favorites, delegation history | Verified on device |
| **Add stake** (existing staker, same validator), including with a main-account balance of 0 and funds held in a swap contract | Verified on-chain (execution result true) |
| **Switch validator** (update staker) and **Retire** in Nimiq Pay | **Not verified.** Two observed behaviors (see below): from a swap contract that still holds funds, the transactions are included in a block but rejected at execution; when the swap contract was entirely spent, no transaction reaches the chain and Nimiq Pay shows "Pending". Earlier "verified" statements were based on the wallet's transaction history and are withdrawn |
| **Create stake** with funds held in a swap contract | **Status changing (2026-09-23):** now fails even from a single-transfer contract, a regression from 3/3 successes on 2026-09-16 to 2026-09-20; always fails from a contract built by merging several transfers (see below) |
| **Claim** (remove stake) | Not tested end to end with the final build |
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

## Switch validator and Retire in Nimiq Pay: two observed behaviors, not verified

Dates 2026-09-16 to 2026-09-20, Nimiq Pay v2.19.1, mainnet, real funds. The transaction history shown by Nimiq Pay
is **not** proof that the staking state changed (it shows these transactions as confirmed or "Pending"); the chain
state is.

**Observed on the chain (verified with a block explorer and the nodes' mempool):**

1. *Android 16 phone, the swap contract still holds funds.* Every *Update Staker* (switch validator) and every
   *Retire Stake* sent from the app is sent from that contract, is **included in a block**, and has an execution
   result of **false**: nothing changes on the chain (value 0, fee 0). More than 30 occurrences. *Create stake* and
   *Add stake* sent from a swap contract have an execution result of true.
2. *Android 13 emulator, two wallets whose swap contracts had been entirely spent by the previous Create / Add.*
   **No transaction appears on the chain at all** (mempool of two nodes watched every 2 seconds, block scan and the
   history of the contracts checked); Nimiq Pay shows the transactions as "Pending".

**Hypothesis (not proven):** Nimiq Pay sends Update and Retire from a swap contract. If the contract still exists
the transaction is included and then rejected; if it no longer exists (everything already staked, no free balance)
nothing is sent. The cause of the rejection on the host side (for example a staker signature proof computed for
another sender) is not established.

**Open question:** for a user who has staked everything (no free balance and no remaining swap contract), Switch and
Retire may be impossible in Nimiq Pay. There is no workaround in the app.

What the app does: it never claims a success from the wallet's answer alone. A single write lock keeps every button
that sends a transaction disabled until the chain reflects the action; after 15 seconds it says the confirmation is
taking longer than usual, after 60 seconds it shows "Still not confirmed. The network may be slow, or the
transaction may not have been sent. Wait a little longer, or unlock to try again.", keeps the buttons disabled,
re-reads the chain every 15 seconds for up to 10 minutes, and offers a manual "Not sent? Unlock" button (never
automatic, because of the risk of a duplicate action). A rejected transaction changes nothing on the chain. If it
stays this way, check the chain (or the transaction in Nimiq Pay) before unlocking; reloading the app re-reads the
chain but does not lift the lock by itself. **Do not present Switch or Retire as verified.**

## Create stake from a swap contract (HTLC): currently fails even from a single transfer

**Update, 2026-09-23 — regression.** Since this date, **Create stake now fails even from a contract created by a
single transfer**, which had worked reliably before: 2 newly created wallets, tested the same way as the 3 earlier
successes below (contract created, Create attempted a few minutes later), gave **2 failures out of 2**, same raw
error and no transaction on the chain. Nimiq Pay's version is unchanged (v2.19.1). This coincides with two Mini App
SDK releases this week (0.2.0 on 2026-09-21, 0.2.1 on 2026-09-22); reading their code shows only a client-side
wrapper change, nothing about Nimiq Pay's closed-source internal logic, so it is a coincidence in time, **not a
proven cause**. Sören (Nimiq Pay team) has not answered since 2026-09-18. Until this is reconfirmed either way,
**do not present the "single transfer" advice or the relay-wallet workaround below as reliable** — they were, and
may again become, correct, but the current on-chain evidence is 2 failures out of 2 from single-transfer contracts.

**Historical results (2026-09-16 to 2026-09-20), superseded by the update above.** Android 13 emulator and
Android 16 phone, Nimiq Pay v2.19.1 on both, mainnet, real funds. The wallet held its funds in a swap contract
(HTLC) and a first stake (**Create stake**) was sent from the app:

| Contract funding the wallet | Amount sent | Result |
|---|---|---|
| 100 NIM received in a single transfer | 100 NIM (all of it) | Passes (phone, 16 Sep; emulator, 19 Sep) |
| 200 NIM received in a single transfer | 100 NIM (partial spend) | Passes (19 Sep) |
| 520.16415 NIM built from several transfers merged by Nimiq Pay | 50, 5 and 1 NIM, two validators, on the production page, a build without locks, the exact 16 Sep version and after a full restart | **Fails** |
| 30.00000 NIM built from two transfers (20 then 10; Nimiq Pay returned the old contract and created a larger one) | 30 NIM (all of it) | **Fails** |
| 20.00000 NIM built from two transfers of 10 NIM sent about four minutes apart (new wallet, Android 16 phone, Nimiq Pay v2.19.1) | 20 NIM (all of it) | **Fails** (nothing on the chain, no staker) |

The error is always the raw message "Failed to send payment transaction: Transaction invalidated during
transaction" (code -32603), and no transaction reaches the chain. **Add stake** worked from a contract of the
same kind, at the time of these tests.

**Historical conclusion (cautious, no longer the current state as of 2026-09-23).** In these tests only contracts
produced by merging several transfers failed at Create (the amount, the decimals and a partial spend were ruled
out), and the failure was **not specific to the emulator**: it was reproduced on a real Android 16 phone with the
same Nimiq Pay version. On the phone, Nimiq Pay also raised a native notification carrying the same text, so the
error is emitted by the host, not by the app. The cause on the Nimiq Pay side was not established then and still
is not. **Workaround observed twice back then (not a guarantee, and not reconfirmed since the 2026-09-23
regression):** withdraw the funds to another address and send them back in a single transfer before the first
Create.

Nimiq Pay refuses to send funds to the wallet's own address ("You can not use this address"), so the funds cannot
be consolidated by sending them to oneself from the wallet.

When a Create fails with this message, the app shows a dedicated help text ("Your first stake couldn't be created ...",
11 languages) and keeps the raw detail under it; Add, Switch and Retire keep their usual messages. This text (app
message key `app.createNeedsSingleTransfer`) has been left unchanged for now: sending NIM in a single transfer
remains a reasonable thing to try even though it is no longer confirmed to work (see the 2026-09-23 update above),
and the app cannot currently offer better advice. The workaround below is affected by the same regression.

## Known issues and workarounds

**Create stake fails with "Your first stake couldn't be created"**. **As of 2026-09-23, this can happen even when the
funds arrived in a single transfer (see the regression above) — the relay-wallet workaround below is not currently
reconfirmed to fix it.** It remains the only workaround observed in our tests, **not a guarantee**:

1. Create a temporary wallet on [wallet.nimiq.com](https://wallet.nimiq.com) **and back it up first**, before
   sending anything to it.
2. Send your whole balance from Nimiq Pay to that wallet's address, checking the address character by character.
3. Wait until the funds have arrived.
4. Send **everything** back in **one single transfer** to your Nimiq Pay address.
5. Wait for "Processing funds" to finish in Nimiq Pay, then create your first stake again.

Risks: a wrong address or a forgotten backup can lose funds, so always double-check. Once your first stake exists,
adding to it works even if funds arrive in several transfers.

**Switch validator or Retire is rejected** ("The network rejected this transaction. Nothing was changed."). Nimiq Pay
currently rejects these actions for some wallets; the stake is safe and the Nimiq Pay team has been informed. There
is **no verified workaround**. In particular, wallet.nimiq.com cannot import a Nimiq Pay wallet (12 words against
24), so do not present it as a way to Switch or Retire.

This workaround comes from two observations, not from a test campaign. It has not been confirmed by the Nimiq Pay team.
When the transaction is included and rejected at execution (Switch, Retire), the app shows "The network rejected this
transaction. Nothing was changed." and, for those two actions only, "Nimiq Pay currently rejects this action for some
wallets. Your stake is safe. We've reported it to the Nimiq Pay team." It never advises a workaround for them.

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
- **Local storage.** The app keeps the chosen language, the action in flight, a short list of
  recent actions (with the wallet address) and the favorite validators (public addresses only) in the browser
  only; see the [Architecture](ARCHITECTURE.md#6-safety-rules-encoded-in-the-ui) summary.
- **Favorites on a shared device.** Favorites are stored per browser and are not tied to a wallet: on a shared
  device the next user of the same browser sees the same favorite validators (no identity, no wallet address).
  They are lost if the host app or the user clears the storage (the WebView of a host app may do so), and they are
  not synchronized between devices.

## Candidate work for a patch release (no commitment)

- Obtain the height of Nimiq Pay's top bar from the host team, so the re-centring can be calibrated
  instead of relying on `env(safe-area-inset-top)` being reported.
- Pin the Mini App SDK version (and, later, self-host the libraries).
- Deployment note for operators: with several nodes answering in turn, per-node `ETag` values differ,
  so conditional requests (`304`) do not hit; serve identical files and disable or align the
  `ETag` (see the [Operator Guide](OPERATOR-GUIDE.md)).
- Read swap-contract balances on-chain so the amount can be pre-filled when the main-account balance reads 0.

The full list of ideas is under *1.1.0* in the [changelog](../CHANGELOG.md).

Have a limitation to report? Please [open an issue](https://github.com/Julien59247787/nimiq-app-validatorswipe/issues/new/choose).
