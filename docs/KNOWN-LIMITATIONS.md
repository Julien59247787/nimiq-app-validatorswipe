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
| **Add stake** (existing staker, same validator), including with a main-account balance of 0 and funds held in a swap contract | Verified on-chain (execution result true), again on 2026-11-10 (block 66517911, Nimiq Pay 2.22.x) |
| **Unstake**, **Finish unstaking** and **Switch validator** (1.1.3) | **Not tested on a device yet** (local mock only). Until 1.1.2 these requests could never succeed: the app sent transactions the staking protocol refuses (see below) |
| **Create stake** with funds held in a swap contract | **Executed on-chain on 2026-11-10** (200 NIM, block 66516076, Nimiq Pay 2.22.x, app 1.1.2). Failed 2/2 on 2026-09-23 (Nimiq Pay 2.19.1); the cause of the change is not established. Always failed in September from a contract built by merging several transfers (see below) |
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

## Switch validator and Retire until 1.1.2: the app sent transactions the protocol refuses

Found on 2026-11-11 by reading the staking contract (core-rs-albatross v2.3.0, `primitives/account/src/account/staking_contract/staker.rs`) and Nimiq's own example Mini App
(`mini-app-sdk/dapp/src/components/Staking.vue` in the Nimiq Pay repository):

- **RetireStake** only moves INACTIVE stake to the retired balance, and only once its lock-up is over
  (`retire_stake`: `InsufficientFunds` if the inactive balance is too small, `InvalidForRecipient` while locked).
  Until 1.1.2 "Retire my stake" sent *RetireStake* with an amount of the ACTIVE stake, with no inactive balance:
  it could never succeed.
- **UpdateStaker** (switch validator) fails while the staker has ACTIVE stake, or while its inactive stake is still
  locked (`update_staker`: "All stake must be inactivated or retired before re-delegating"). Until 1.1.2 "Switch"
  sent it with an active stake: it could never succeed. The example Mini App also sends `reactivateAllStake: true`.

The September observations stay true as facts (Android 16 phone, Nimiq Pay v2.19.1: more than 30 *Update Staker*
and *Retire Stake* included in a block with an execution result of **false**; Android 13 emulator with an emptied
swap contract: nothing reached the chain), but their **cause was the app**, not the swap contract (HTLC) or the
cosigner as this page supposed before. **Our reports to the Nimiq Pay team in September were wrong on this point**:
those failures came from our use of the protocol, not from Nimiq Pay. On 2026-11-10 (Nimiq Pay 2.22.x), the old *Retire Stake* request from a
wallet whose swap contract was empty never reached the chain nor the mempool; the request was invalid in any case.

**What 1.1.3 does.** **Unstake** = *SetActiveStake* (active stake minus the amount; `set_active_stake`): the
amount becomes inactive and stays locked one epoch, exactly until block `inactive_from + 43,201` on mainnet
(`Policy::block_after_collateral_lockup`: one epoch is 60 blocks per batch x 720 batches; about 12 hours at about
one block per second). `inactive_from` is the next election block, so the whole wait is 12 to 24 hours. The app shows that block; with the current block height from the API (optional
`block_number`) it also shows the blocks left and keeps "Finish unstaking" and Switch disabled until then. **Finish unstaking** = *RetireStake* of the inactive
balance, possible once the lock is over; too early, the network rejects it at execution and nothing changes, and
the app says the lock may not be over yet. **Claim my funds** = *RemoveStake* of the retired balance. A new Unstake
is refused while one is in progress (it would restart the lock). **Switch**: with an active stake the app explains
the two steps (unstake everything, wait for the lock, then choose the new validator) and sends nothing; with no
active stake it sends *UpdateStaker* with `reactivateAllStake`, which moves the inactive stake to the new validator
and makes it active again. These flows were checked against a local mock only, not yet on a device.

## Create stake from a swap contract (HTLC): failed in September, executed on 2026-11-10

**Update, 2026-11-10.** Create stake (200 NIM, block 66516076) and Add stake (50 NIM, block 66517911) from a wallet
whose funds were in a swap contract were **executed on the chain** (Nimiq Pay 2.22.x, app 1.1.2 with the Mini App
SDK pinned to 0.1.0). Whether the pinned SDK or a Nimiq Pay update made the difference is not established. The
paragraphs below describe the earlier state.

**Update, 2026-09-23 — regression.** Since this date, **Create stake now fails even from a contract created by a
single transfer**, which had worked reliably before: 2 newly created wallets, tested the same way as the 3 earlier
successes below (contract created, Create attempted a few minutes later), gave **2 failures out of 2**, same raw
error and no transaction on the chain. Nimiq Pay's version is unchanged (v2.19.1). This coincides with two Mini App
SDK releases this week (0.2.0 on 2026-09-21, 0.2.1 on 2026-09-22); reading their code shows only a client-side
wrapper change, nothing about Nimiq Pay's closed-source internal logic, so it is a coincidence in time, **not a
proven cause**. Sören (Nimiq Pay team) has not answered since 2026-09-18. Until this is reconfirmed either way,
**do not present the "single transfer" advice or the relay-wallet workaround below as reliable** — they were, and
may again become, correct, but the current on-chain evidence is 2 failures out of 2 from single-transfer contracts.
Version 1.1.2 pins the Mini App SDK to 0.1.0 to test that track (not proven to be the cause).

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

**Unstake and Switch take time.** This is the staking protocol, not a fault: unstaked NIM stay locked about one
epoch after the end of the current one (12 to 24 hours in all) before "Finish unstaking" and then "Claim my funds"; switching validator requires the whole
stake to be unstaked first (see the section on Switch and Retire above). A rejected "Finish unstaking" or Switch
usually means the lock is not over yet: nothing is changed on the chain, try again later.

**The staker state from one node can be wrong.** On 2026-11-11 one of the two nodes behind the round-robin answered
"no staker" for a staker the chain knows. The app (1.1.3) keeps the staker it has already seen, ignores older answers
and reads a "no staker" answer again before a Create; the node itself is the operator's to fix.

## Nimiq Pay measurements and host behavior

- **Confirmation delay.** Blocks are about 1 second apart and a staking transaction is usually
  included about 2 blocks after it is sent (median; at most about 3), with rare outliers of about
  2 minutes. The app re-reads the chain for up to 60 seconds and then keeps the last state it could
  confirm. The transaction history shown by a wallet app may lag behind the chain by up to a minute.
- **SDK errors.** The Mini App SDK's `send*Transaction` promises can *resolve* with an error object
  instead of rejecting; the app treats that as a failure. Nimiq Pay's errors carry a code: `4001` the user
  cancelled, `-32001` the outcome is unknown (it may have been sent). Since 1.1.3 an unknown outcome, and any
  `-32603` other than "invalidated", is not called a failure: the app keeps watching the chain.
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
- **Waiting period.** Unstaking is a three-step process (Unstake, Finish unstaking, Claim). After Unstake the
  amount stays locked until the end of the current epoch, then one more epoch (43,200 blocks): 12 to 24 hours. The app shows the unlock block; it shows the blocks
  left only if the backend gives the current block height (`block_number`, optional). Without it, "Finish unstaking"
  sent too early is rejected by the network and changes nothing. Release also requires that the validator is not
  jailed (`is_inactive_stake_released`), which the app does not check.
- **Ready for the Nimiq Pay fix (since 1.1.7).** Cause: Nimiq Pay sends the value-0 staking signals from its swap
  contract (commit `29957790` notes they "could also be sent by the local wallet"). Proposed fix: send them from the
  local account and expose `getCapabilities()` with `stakingSignalsFromLocalAccount: true`
  ([contract](NIMIQ-PAY-CAPABILITIES.md)). The app detects it by itself and then drops the reserve below. Issue / PR
  to be linked once published.
- **Reserve of 5 NIM (since 1.1.5).** Inside Nimiq Pay the app keeps 5 NIM spendable when staking (pre-filled
  amount, Max button and a refusal above balance minus 5 NIM), so the case below cannot be created from this app.
  It relies on `getBalance` of Nimiq Pay (2.22.1 and later); with an older Nimiq Pay, or if the balance cannot be
  read, the reserve is only explained, not enforced. Staking from another app can still empty the swap contract.
- **Everything staked: free NIM needed.** Nimiq Pay sends Unstake, Finish unstaking and Switch from its swap contract
  (HTLC). When staking emptied it, the contract no longer exists on the chain and the request never reaches it
  (Nimiq Pay answers "outcome unknown"). Workaround proved on 2026-11-11: receive a small amount of NIM; Nimiq Pay
  moves it into a new swap contract and the request is executed. The swap contract is Nimiq Pay's normal spending
  account (payments are made from it, and Nimiq Pay renews it before its timeout), so those NIM stay spendable as
  usual. The app shows this note when the free balance of the basic account is 0; it blocks nothing, since the
  available NIM are normally in the swap contract.
- **Still open on the Nimiq Pay side** (to be re-tested with the correct requests): Create stake from a swap contract
  built by merging several transfers.
- **Right-to-left layout** is not implemented: Arabic is displayed with a left-to-right layout.
- **Third-party CDNs.** Libraries and fonts are loaded from CDNs (jsDelivr, Google Fonts), so the
  page depends on their availability and they see visitors' IP addresses. The Mini App SDK is pinned to 0.1.0 since 1.1.2
  (a test, see the changelog); `@nimiq/core` and the Hub API are pinned too.
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
- Self-host the libraries (the Mini App SDK is pinned to 0.1.0 since 1.1.2, as a test: decide whether to keep the pin).
- Deployment note for operators: with several nodes answering in turn, per-node `ETag` values differ,
  so conditional requests (`304`) do not hit; serve identical files and disable or align the
  `ETag` (see the [Operator Guide](OPERATOR-GUIDE.md)).
- Read swap-contract balances on-chain so the amount can be pre-filled when the main-account balance reads 0.

The full list of ideas is under *1.1.0* in the [changelog](../CHANGELOG.md).

Have a limitation to report? Please [open an issue](https://github.com/Julien59247787/nimiq-app-validatorswipe/issues/new/choose).
