# Known limitations

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

**What the app does when the balance reads 0.** It does not pre-fill the amount (it cannot know it:
type it yourself), shows the one-line hint, and never blocks browsing, staking, switching validator,
retiring or claiming. If the wallet cannot fund a transaction it rejects it and the app shows the
wallet's error message.

**What was tested.** Add Stake with a main-account balance of 0 and the funds held in a swap contract
was verified on a real device. Create Stake (a first stake) with such funds has not been tested end
to end.

**Possible improvement.** Read swap-contract balances on-chain so the amount can be pre-filled in
that case — see the *Unreleased* section of the [changelog](../CHANGELOG.md#unreleased).

## Other limitations

- **Claiming retired funds** (*remove stake*) is available inside Nimiq Pay only; on the
  Nimiq Hub path the app shows an explanatory message.
- **Waiting period.** Unstaking is a two-step process: after *retire*, funds become claimable
  once the current network epoch has ended. This usually takes several hours, depending on when in the epoch you retire.
  The app deliberately gives no fixed duration.
- **Confirmation delay.** A staking transaction is usually included about 2 blocks (about 2 seconds)
  after it is sent, with rare outliers of about 2 minutes; the app keeps checking for up to 60 seconds
  and then keeps the last state it could confirm. The transaction history of a wallet app may lag behind
  the chain by up to a minute.
- **Real-device coverage.** Retire and claim with the latest builds, and Create Stake with funds held in a
  swap contract, have not been re-tested end to end on a device.
- **Machine translations.** Languages other than French and English are machine-generated and
  not all reviewed by native speakers ([I18N.md](I18N.md)).
- **Right-to-left layout** is not implemented: Arabic is displayed with a left-to-right layout.
- **Third-party CDNs.** Libraries and fonts are loaded from CDNs (jsDelivr, Google Fonts), so
  the page depends on their availability and they see visitors' IP addresses.
- **Statistics coverage.** Uptime, reliability, reward rate and fee depend on the operator's
  data source; validators without enough history show "—" for missing values.

Have a limitation to report? Please [open an issue](https://github.com/Julien59247787/nimiq-app-validatorswipe/issues/new/choose).
