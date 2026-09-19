# Manual test plan

Validator Swipe has no automated test suite yet (it is one static file, see
[CONTRIBUTING.md](../CONTRIBUTING.md)). This checklist is what a maintainer runs before a release. What
has actually been verified on a real device is recorded in [KNOWN-LIMITATIONS.md](KNOWN-LIMITATIONS.md#verification-status-version-100).

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
4. **No leaks:** no secrets, internal hostnames/IPs or full wallet addresses in the repository.

## Checklist

**Loading and browsing**
- [ ] The page loads; the validator list shows real data (or a visible error and two example validators if the API is down).
- [ ] Back / pass / star / next work in Browse, in both directions; a starred validator appears in My favorites.
- [ ] The connection pill shows "Wallet detected" when a wallet is connected and "Wallet not detected" otherwise, before and after a language change.

**Delegation** (My favorites; small amounts)
- [ ] First Create with a wallet whose funds come from a single transfer (a wallet funded by merged transfers can fail at Create, on an emulator and on a phone, see [KNOWN-LIMITATIONS.md](KNOWN-LIMITATIONS.md#create-stake-from-a-swap-contract-htlc-merged-contracts-fail)).
- [ ] No staker yet: amount required, *create staker* is sent, success message stays until dismissed, the waiting line appears and disappears once the chain reflects the transaction, the active delegation banner and history update.
- [ ] Staker exists, same validator: *add stake*.
- [ ] Staker exists, other validator: the amount field is replaced by the switch note; *update staker* is sent without an amount.
- [ ] Main-account balance 0 with funds in Nimiq Pay: the one-line hint appears under the amount field; staking is not blocked.
- [ ] Amount pre-filled from the balance: the "pre-filled" hint shows and disappears when the amount is edited.

**Errors and safety**
- [ ] Cancel or reject in the wallet: an error message with a collapsible technical detail; OK, a tap outside and Escape close it; the Delegate button works again at once.
- [ ] A staking state that cannot be read (stop the backend): the app retries, then refuses and sends nothing.
- [ ] Double tap / triple tap on Delegate: one wallet request.
- [ ] Reload the page while a transaction is pending: the waiting message and the lock on Delegate, Confirm withdrawal and Claim come back, then clear when the chain reflects the action.
- [ ] While an action is pending, Delegate, Confirm withdrawal and Claim are all disabled; browsing, tabs and languages stay usable.
- [ ] Pending that never reaches the chain: after 60 s the message becomes "Not confirmed yet — check Nimiq Pay before trying again", the three buttons stay disabled, and "I checked in Nimiq Pay, continue" lifts the lock.
- [ ] Two open pages: the lock is seen by both; lifting it in one lifts it in the other.
- [ ] The delegation history gets a row only after the chain reflects the action.
- [ ] The success message, the confetti and the removal of the favorite appear only once the chain reflects the action; a wallet "success" that never reaches the chain shows none of them and keeps the favorite.
- [ ] Disabled buttons (Claim, Confirm withdrawal, Delegate) look disabled while an action is pending.

**Retire and claim**
- [ ] Open "Retire my stake": the amount is pre-filled with the active stake; confirm; the stake shows as retiring; claim becomes available after the epoch ends and is sent from Nimiq Pay.

**Interface**
- [ ] Amount field: the keyboard opens and closes; the page returns to where it was.
- [ ] Inside Nimiq Pay: a tap on Browse, My favorites or the app title re-centres the card under the host bar (only when the host reports its inset), and never hides the card's buttons.
- [ ] Every language (fr, en, es, zh, ja, ko, de, pt, ru, tr, ar): texts fit, no untranslated key; the language is remembered after a reload.
- [ ] Narrow phone width (360-450 px), desktop, light and dark themes.
- [ ] Footer: "Report a bug" opens the issue form; the mascot links to the operator's dashboard.

**Hub path (outside Nimiq Pay)**
- [ ] Connect, choose an address, delegate, disconnect; retire works, claim shows the explanatory message.

Record the device, OS, WebView/Chrome version and Nimiq Pay version with the results.
