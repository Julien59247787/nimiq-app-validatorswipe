# Known limitations

## Funds received in Nimiq Pay may be temporarily unspendable

**Symptom.** A wallet that has just been topped up (for example by buying NIM inside Nimiq
Pay) shows a spendable balance of **0** in Validator Swipe, even though the funds are visible
in the wallet.

**Why.** Funds received through an exchange/swap flow can be held for a while inside a swap
contract (an HTLC, *hash time-locked contract*) operated by the exchange partner, before they
land in the wallet's basic account. While they sit in that contract they are not part of the
account's spendable balance. This is a property of how the swap works, not a bug in Validator
Swipe. Nimiq describes the mechanism in its article *"What ACTUALLY happens when you swap in
the Nimiq Wallet"* (May 2021).

The app reads the **basic-account balance** only (`wallet_balance_luna` from the backend, see
the [Operator Guide](OPERATOR-GUIDE.md#12-get-apiv2staker-statusaddressnq-address)). Funds locked
in a contract do not appear there until they are released.

**What still works and what doesn't**

| Action | Needs new spendable funds? | While the balance reads 0 |
|---|---|---|
| Browse validators, set favorites aside | No | Works |
| Switch validator for an existing stake (*update staker*) | No — it moves the existing stake | Works |
| Retire an already-active stake | No | Works |
| Claim funds after the waiting period (*remove stake*) | No | Works |
| Create a first stake | **Yes** | Blocked |
| Add funds to an existing stake | **Yes** | Blocked |

**What the app does.** When a connected wallet reports a spendable balance of exactly 0, the
app shows a non-blocking "funds may still be settling" notice, does not pre-fill the
delegation amount, and stops actions that need new funds before the wallet can reject them
with a confusing error. It never claims to know the cause for sure: a balance of 0 can also
simply mean an empty wallet.

**What to do.** Wait for the swap to complete and the funds to reach the wallet, then reload
the app. Moving an already-active stake to another validator, and retiring it, are possible
in the meantime.

**Possible improvement.** Detect funds still locked in a swap contract precisely, instead of
the "balance is exactly 0" heuristic — see *Future improvements* in the
[changelog](../CHANGELOG.md#future-improvements).

## Other limitations

- **Claiming retired funds** (*remove stake*) is available inside Nimiq Pay only; on the
  Nimiq Hub path the app shows an explanatory message.
- **Waiting period.** Unstaking is a two-step process: after *retire*, funds become claimable
  once the current network epoch has ended. Depending on when you retire, that can be short or
  take several hours. The app deliberately gives no fixed duration.
- **Machine translations.** Languages other than French and English are machine-generated and
  not all reviewed by native speakers ([I18N.md](I18N.md)).
- **Right-to-left layout** is not implemented: Arabic is displayed with a left-to-right layout.
- **Third-party CDNs.** Libraries and fonts are loaded from CDNs (jsDelivr, Google Fonts), so
  the page depends on their availability and they see visitors' IP addresses.
- **Statistics coverage.** Uptime, reliability, reward rate and fee depend on the operator's
  data source; validators without enough history show "—" for missing values.

Have a limitation to report? Please [open an issue](https://github.com/Julien59247787/nimiq-app-validatorswipe/issues/new/choose).
