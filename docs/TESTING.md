# Manual test plan

Validator Swipe has no automated test suite yet (it is one static file, see
[CONTRIBUTING.md](../CONTRIBUTING.md)). This checklist is what a maintainer runs before a release. What
has actually been verified on a real device is recorded in [KNOWN-LIMITATIONS.md](KNOWN-LIMITATIONS.md#verification-status-current).

## Environments

| Environment | Use |
|---|---|
| Nimiq Pay (Android or iOS) with a small amount of real NIM | Real transactions, host-specific behavior (scrolling, keyboard, dialogs) |
| Desktop browser + Nimiq Hub | Hub connection path (small amounts) |
| Desktop / phone-sized browser without a wallet | Demo mode, layout, i18n |
| Local static server (`python3 -m http.server`) | UI without a backend (built-in example validators) |
| Local mock server (your own) returning fixed `staker-status` values | Repeatable state changes without spending NIM |

## Before every release

1. **Syntax:** load the page with the browser console open: no error. Count `{`/`}` and `(`/`)` in the inline script.
2. **i18n parity:** every key exists in the 11 languages ([I18N.md](I18N.md#the-golden-rule-key-parity)); no mojibake.
3. **CSP hash:** recompute the script hash (normalize CRLF to LF) and compare with the deployed header ([Operator Guide](OPERATOR-GUIDE.md#34-content-security-policy)).
4. **Pinned libraries:** the URLs of `@nimiq/mini-app-sdk`, `@nimiq/core` and `@nimiq/hub-api` in `index.html` carry an exact version.
5. **Displayed version:** `scripts/check-version.sh vX.Y.Z` must print OK (the version shown at the bottom of the page, its release link and the newest dated CHANGELOG entry agree with the tag about to be created). Read the footer status and description in a few languages: they must match the current reality.
6. **No leaks:** no secrets, internal hostnames/IPs or full wallet addresses in the repository.

## Checklist

**Loading and browsing**
- [ ] The page loads; the validator list shows real data (or a visible error and two example validators if the API is down).
- [ ] Back / pass / star / next work in Browse, in both directions; a starred validator appears in My favorites.
- [ ] The connection pill shows "Wallet detected" when a wallet is connected and "Wallet not detected" otherwise, before and after a language change.

**Delegation** (My favorites; small amounts)
- [ ] First Create from a wallet whose funds are in a swap contract: executed on-chain on 2026-11-10 with Nimiq Pay 2.22.x after failing in September; check the current state in [KNOWN-LIMITATIONS.md](KNOWN-LIMITATIONS.md#create-stake-from-a-swap-contract-htlc-failed-in-september-executed-on-2026-11-10) and the execution result on the chain.
- [ ] No staker yet: amount required, *create staker* is sent, success message stays until dismissed, the waiting line appears and disappears once the chain reflects the transaction, the active delegation banner and history update.
- [ ] Staker exists, same validator: *add stake*.
- [ ] Staker exists, other validator, **active stake**: the note explains that the stake must be unstaked first; Delegate shows the same explanation and **nothing is sent**.
- [ ] Staker exists, other validator, **no active stake** (inactive, lock over): *update staker* is sent with `reactivateAllStake: true` and no amount; check the execution result on the chain, not in the wallet's history.
- [ ] One node answering "no staker" every other time (mock it): the banner and the stake block never disappear, Delegate on the same validator always sends *add stake*, never *create staker*.
- [ ] Main-account balance 0 with funds in Nimiq Pay: the one-line hint appears under the amount field; staking is not blocked.
- [ ] Amount pre-filled from the balance: the "pre-filled" hint shows and disappears when the amount is edited.

**Favorites**
- [ ] Star a validator, reload the app: it is still in My favorites and the counter is right; remove it with the star button, reload: it is gone.
- [ ] Favorites survive closing the app and are the same in a second open page (star in one, the other updates).
- [ ] With the validator API unavailable (fallback list), favorites of unknown validators are kept in the stored list, not lost.
- [ ] With storage blocked or corrupted, the app still works (favorites for the session only), without an error message.

**Errors and safety**
- [ ] Cancel or reject in the wallet: an error message with a collapsible technical detail; OK, a tap outside and Escape close it; the Delegate button works again at once.
- [ ] A staking state that cannot be read (stop the backend): the app retries, then refuses and sends nothing.
- [ ] Double tap / triple tap on Delegate: one wallet request.
- [ ] Reload the page while a transaction is pending: the waiting message and the lock on Delegate, Confirm withdrawal and Claim come back, then clear when the chain reflects the action.
- [ ] While an action is pending, Delegate, Confirm withdrawal and Claim are all disabled; browsing, tabs and languages stay usable.
- [ ] Progressive messages: "Waiting for the network to confirm your transaction…" for 15 s, then "This is taking a bit longer than usual…" up to 60 s.
- [ ] Pending that the chain never reflects (never included, or included but rejected at execution, which is what Switch and Retire do today in Nimiq Pay, in one of two ways): after 60 s the message becomes "Still not confirmed. The network may be slow, or the transaction may not have been sent. Wait a little longer, or unlock to try again." with an orange "Not sent? Unlock" button, the three buttons stay disabled, and "Not sent? Unlock" lifts the lock (manual only).
- [ ] Rejected transaction with the `tx-status` endpoint available (mock it: found true, execution_result false, confirmations 3): the message "The network rejected this transaction. Nothing was changed." appears and the lock is lifted by itself. With found false, warming, 404, a timeout, an invalid hash or confirmations 1, or execution_result true: no message, the lock stays and the usual waiting, "Still not confirmed" and manual unlock apply.
- [ ] Create that fails with "Transaction invalidated" (mock the wallet): the help text "Your first stake couldn't be created ..." with the raw detail below; the same failure on Add, Switch or Retire shows the usual message. A network-rejected Switch or Retire shows the extra Nimiq Pay line; a rejected Add does not.
- [ ] Two open pages: the lock is seen by both; lifting it in one lifts it in the other.
- [ ] The delegation history gets a row only after the chain reflects the action.
- [ ] The success message and the confetti appear only once the chain reflects the action; a wallet "success" that the chain never reflects shows none of them.
- [ ] After any action (create, add, switch, retire, claim, also in demo mode) the validator is still in My favorites and the counter is unchanged; after a Create the same validator's card is in Add mode with the amount field visible; the validator leaves My favorites only when its star is removed.
- [ ] Disabled buttons (Claim, Confirm withdrawal, Delegate) look disabled while an action is pending.

**Unstake, finish unstaking and claim**
- [ ] Open "Unstake": the amount is pre-filled with the active stake; confirm: *set active stake* is sent with the new active balance (active minus the amount); no success message until the chain shows an inactive balance.
- [ ] With an inactive balance: "Unstake" is disabled and a note says unstaking is in progress; "Finish unstaking" is shown and sends *retire stake* with the inactive balance; too early, the network rejects it and the message says the lock may not be over yet.
- [ ] With a retired balance: "Claim my funds" sends *remove stake* from Nimiq Pay.
- [ ] Nimiq Pay answers an unknown outcome (code -32001, or -32603 other than "invalidated"): the message says Nimiq Pay could not confirm whether it was sent and asks not to send it again; the lock stays and the success message appears if the chain then reflects the action.

**Interface**
- [ ] Amount field: the keyboard opens and closes; the page returns to where it was.
- [ ] Inside Nimiq Pay: a tap on Browse, My favorites or the app title re-centres the card under the host bar (only when the host reports its inset), and never hides the card's buttons.
- [ ] Every language (fr, en, es, zh, ja, ko, de, pt, ru, tr, ar): texts fit, no untranslated key; the language is remembered after a reload.
- [ ] Narrow phone width (360-450 px), desktop, light and dark themes.
- [ ] Footer: "Report a bug" opens the issue form; the mascot links to the operator's dashboard.

**Hub path (outside Nimiq Pay)**
- [ ] Connect, choose an address, delegate, disconnect; retire works, claim shows the explanatory message.

Record the device, OS, WebView/Chrome version and Nimiq Pay version with the results.
