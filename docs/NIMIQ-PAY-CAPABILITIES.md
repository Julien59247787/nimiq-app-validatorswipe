# Nimiq Pay host capability: `getCapabilities` (proposed contract)

Status: **proposed by Validator Swipe, not yet in Nimiq Pay.** Issue / PR: to be linked once published.
Validator Swipe 1.1.7 and later already read it, so the app switches to the target behaviour on its own the day a
Nimiq Pay release implements it.

## Why

Nimiq Pay sends the value-0 staking signals of a Mini App (set active stake = Unstake, retire stake = Finish
unstaking, update staker = Switch) from its swap contract (HTLC) (`src/lib/tx.ts`, staking branch). When staking has
emptied that contract, it no longer exists on the chain and those transactions can never be accepted, so the user
cannot unstake from a Mini App. The commit that added Mini App staking (`29957790`, 2026-01-24) already notes that
these signalling transactions "could also be sent by the local wallet", as remove-stake already is. Since 1.1.5
Validator Swipe works around it by keeping 5 NIM spendable (see [KNOWN-LIMITATIONS](KNOWN-LIMITATIONS.md)).

## Proposed fix in Nimiq Pay

1. Send set-active-stake, retire-stake and update-staker (value 0, fee 0) from the user's local (basic) account,
   signed by the local key, like the remove-stake branch.
2. Expose a host method so Mini Apps can tell whether (1) is in place.

## Contract

Request (Nimiq network, like `getBlockNumber`):

```
nimiq.getCapabilities()            // no argument
```

Answer: a plain object. Fields are optional; an unknown field must be ignored by Mini Apps.

| Field | Type | Meaning |
| --- | --- | --- |
| `stakingSignalsFromLocalAccount` | boolean | `true` when set-active-stake, retire-stake and update-staker are sent from the local account, so they do not depend on the swap contract balance |

Example: `{ "stakingSignalsFromLocalAccount": true }`.

Rules for the host: no user prompt, no toast, no network access needed; answer immediately.

## What Validator Swipe does with it

- Calls it once after `listAccounts`, only if `nimiq.getCapabilities` is a function, with a 3 s timeout.
- Only `stakingSignalsFromLocalAccount === true` (exactly) switches the reserve off: the amount is pre-filled with the
  whole spendable balance, Max gives the whole balance, the reserve note and the "free NIM needed" note are hidden.
- A missing method, an error (a host that does not know the method answers `UnknownRequestError`, which Nimiq Pay
  does not show as a toast), a timeout or any other value keeps the 1.1.6 behaviour (5 NIM reserve).
