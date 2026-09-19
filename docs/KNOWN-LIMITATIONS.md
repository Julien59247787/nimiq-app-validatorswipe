# Known limitations

## The main-account balance can read 0 while Nimiq Pay shows funds

**Symptom.** A wallet that has just been topped up (for example by buying NIM inside Nimiq
Pay) shows a balance of **0** in Validator Swipe (no pre-filled amount, and an informational
notice), even though Nimiq Pay displays the funds.

**Why.** Funds received through an exchange/swap flow are held in a swap contract (an HTLC,
*hash time-locked contract*) — the mechanism Nimiq Pay uses on purpose — before they reach the
wallet's basic account. The app can only read the **basic-account balance**
(`wallet_balance_luna` from the backend, see the
[Operator Guide](OPERATOR-GUIDE.md#12-get-apiv2staker-statusaddressnq-address)), so funds
sitting in a swap contract do not appear in it. Nimiq describes the swap mechanism in its
article *"What ACTUALLY happens when you swap in the Nimiq Wallet"*.

**Staking still works.** A real-device test showed Nimiq Pay accepting an **Add Stake**
transaction while the basic-account balance read 0 and the funds were held in a swap
contract: Nimiq Pay uses those funds itself. For that reason the app does **not** block
staking when the balance reads 0. *Create stake* (a first stake) and the other actions were
not separately tested with such funds; if the wallet cannot fund a transaction, it rejects it
and the app shows the wallet's error message.

**What the app does when the balance reads 0**

- It does not pre-fill the delegation amount (it cannot know the real amount): type it yourself.
- It shows a dismissible informational notice explaining the situation.
- It never blocks browsing, staking, switching validator, retiring or claiming.

**Possible improvement.** Read swap-contract balances on-chain so the amount can be
pre-filled in that case — see the *Unreleased (toward 1.1.0)* section of the
[changelog](../CHANGELOG.md#unreleased-toward-110).

## Other limitations

- **Claiming retired funds** (*remove stake*) is available inside Nimiq Pay only; on the
  Nimiq Hub path the app shows an explanatory message.
- **Waiting period.** Unstaking is a two-step process: after *retire*, funds become claimable
  once the current network epoch has ended. This usually takes several hours, depending on when in the epoch you retire.
  The app deliberately gives no fixed duration.
- **Machine translations.** Languages other than French and English are machine-generated and
  not all reviewed by native speakers ([I18N.md](I18N.md)).
- **Right-to-left layout** is not implemented: Arabic is displayed with a left-to-right layout.
- **Third-party CDNs.** Libraries and fonts are loaded from CDNs (jsDelivr, Google Fonts), so
  the page depends on their availability and they see visitors' IP addresses.
- **Statistics coverage.** Uptime, reliability, reward rate and fee depend on the operator's
  data source; validators without enough history show "—" for missing values.

Have a limitation to report? Please [open an issue](https://github.com/Julien59247787/nimiq-app-validatorswipe/issues/new/choose).
