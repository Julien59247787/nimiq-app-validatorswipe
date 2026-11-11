# 🛡️ Validator Swipe

**Pick a Nimiq validator with a swipe, delegate with a tap.**

Validator Swipe is a [Nimiq Pay](https://nimiq.com) mini app that turns choosing a
validator — usually a dry table of numbers — into a fast, informed decision, then lets
you delegate (stake) your NIM in one tap. It also covers the rest of the staking
lifecycle: add stake, unstake and claim your funds back, and switch validator, in the steps the Nimiq protocol requires (see [Known issues and workarounds](#known-issues-and-workarounds)).

Built by **@Ju'Team** (Ju & Claude) for the Nimiq Mini Apps Competition (Cycle II, updated for Cycle III).
Licensed under [MIT](LICENSE).

---

## Table of contents

- [Features](#features)
- [Screenshots](#screenshots)
- [How staking works here](#how-staking-works-here)
- [Quick start](#quick-start)
- [Architecture in 10 lines](#architecture-in-10-lines)
- [Running your own instance](#running-your-own-instance)
- [Documentation](#documentation)
- [Good to know](#good-to-know)
- [Known issues and workarounds](#known-issues-and-workarounds)
- [Project status](#project-status)
- [Reporting a bug](#reporting-a-bug)
- [Contributing & security](#contributing--security)
- [License](#license)

## Features

- **Every active validator, real data.** Uptime, reliability, reward rate, delegation
  fee and total stake for all active validators (39 at the time of writing), not a curated
  shortlist. Missing metrics are shown as `—`, never guessed.
- **Two-phase flow.** *Browse* (skip / set aside — free, no transaction) then
  *My favorites* (the only place a transaction can be sent). Nothing is ever delegated
  by accident while browsing.
- **Complete staking lifecycle**, driven by the account's real on-chain state:
  create a staker, add to an existing stake, **unstake** (then *finish unstaking* once the lock of 12 to
  24 hours is over), **claim** the funds, and switch validator once the stake is unstaked (see
  [Known issues and workarounds](#known-issues-and-workarounds)).
- **Always in sync with the chain.** After every transaction the app re-reads the on-chain state
  until it is reflected, and shows a "waiting for the network to confirm" line meanwhile.
- **Tidy positioning.** In Nimiq Pay, a tap on Browse, My favorites or the app title re-centres the card under the host bar
  when the host reports its height, and never at the cost of hiding the card's buttons.
- **Comfortable typing.** After typing an amount, the page returns to where it was when the keyboard closes.
- **One write at a time.** Duplicate taps, double connections and page reloads cannot send the same action twice,
  and while a transaction is waiting for the chain every button that sends a transaction stays disabled, across
  reloads and open pages, with a clear "Not confirmed yet" state if the chain never reflects it. Success is shown
  only once the chain reflects the action, never on the wallet's answer alone
  (see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)).
- **Runs inside Nimiq Pay *and* in a regular browser.** Inside Nimiq Pay it uses the
  Mini App SDK. Outside, a "Connect" button uses the Nimiq Hub (implemented; see
  [docs/KNOWN-LIMITATIONS.md](docs/KNOWN-LIMITATIONS.md) for what has been tested).
- **Non-custodial by design.** The app never sees a private key: every transaction is
  signed in Nimiq Pay or the Nimiq Hub. See [SECURITY.md](SECURITY.md).
- **Honest demo mode.** With no wallet connected the app stays browsable, and any
  simulated action is clearly labeled as a demo — it can never be mistaken for a real one.
- **11 languages** (fr, en, es, zh, ja, ko, de, pt, ru, tr, ar), English by default.
  See [docs/I18N.md](docs/I18N.md).
- **Single static file.** No build step, no bundler, no framework — one `index.html`.

## Screenshots

Captured on a phone with the live app (English interface). The validator names shown are
public validators; no wallet address is visible.

| | |
|---|---|
| ![Landing page: headline "Pick your validator with a swipe, delegate with a tap", with the "See the validators", "Who pays for what?" and "Watch the demo video" buttons](docs/images/01-landing-page.png) | ![Browse tab: wallet detected, banner "You're currently delegating to…", active stake of 130 NIM with "Retire my stake" and "Claim my funds" buttons, and a validator card showing uptime, reliability, reward rate, staked amount and fee](docs/images/02-browse-active-stake.png) |
| **1. Landing page.** The mini app's entry page: what it does, plus buttons to jump to the validators, to the "who pays for what" explanation, and to the demo video. | **2. Browse tab.** A wallet is detected; the gold banner shows the current on-chain delegation, "My stake" shows the active stake with the *Retire* and *Claim* buttons, and the card shows real uptime, reliability, reward rate, total stake and fee. Below: back / pass / set aside (star) / next. |
| ![My favorites tab: a favorited validator card and an empty "Amount to delegate (NIM)" field with the placeholder "Enter the amount of NIM to stake here"](docs/images/03-favorites-delegate-amount.png) | ![My favorites tab with the amount field pre-filled with the wallet's available balance, and the hint "This amount is pre-filled with your available balance — double-check it before confirming."](docs/images/04-delegate-amount-prefilled.png) |
| **3. My favorites — delegate.** The only place a transaction can be sent. When the main-account balance reads 0 the amount field shows an explicit placeholder, and a one-line hint says the available balance is shown in Nimiq Pay. | **4. Pre-filled amount.** When the wallet's spendable balance is known, the amount is pre-filled with it (editable), with a reminder to double-check before confirming. |
| ![Retire flow: "Amount to retire (NIM)" pre-filled with the active stake, an explanation that the funds return after the current network epoch ends, and a "Confirm withdrawal" button](docs/images/05-retire-stake.png) | |
| **5. Unstake** (screenshot of an earlier version, where the button read "Retire my stake"). The amount is pre-filled with the active stake; since 1.1.3 the text explains the three steps: Unstake, Finish unstaking after the lock of 12 to 24 hours, Claim my funds. | |

## How staking works here

Staking lets you put NIM to work: you *delegate* it to a validator (a node that keeps
the network running) and earn a share of the rewards, without your funds ever leaving
your control — the validator never holds your NIM.

Nimiq's staking contract allows **one staker per address**. The app therefore checks
your on-chain state and picks the right transaction:

| Your account | Action | Transaction |
|---|---|---|
| No staker yet | Delegate | create staker |
| Staker exists, same validator | Add funds | add stake |
| Staker exists, other validator, no active stake | Switch validator | update staker (moves the stake and reactivates it) |
| Staker exists, other validator, active stake | Switch validator | nothing sent: unstake first, then switch after the lock |
| Want your funds back | Step 1: unstake | set active stake (the amount becomes inactive, locked 12 to 24 hours) |
| Inactive stake, lock over | Step 2: finish unstaking | retire stake |
| Retired stake available | Step 3: claim | remove stake |

## Quick start

The app is one static HTML file, so trying it locally takes seconds:

```bash
git clone https://github.com/Julien59247787/nimiq-app-validatorswipe.git
cd nimiq-app-validatorswipe
python3 -m http.server 8080      # any static file server works
# open http://localhost:8080
```

Opened like this, the app runs but the live validator list and on-chain staker status
are **not** available: they come from a small backend API (`/api/v2/...`) that a static
server does not provide. The app degrades gracefully (built-in example validators,
demo mode). To get the full experience, deploy it with the backend described in the
[Operator Guide](docs/OPERATOR-GUIDE.md).

Good to know when running from a clone: the "Watch the demo video" button links to a
`demo.mp4` that is not part of the repository (it is a dead link locally), and the
`og:image` link-preview URL points at the original deployment. Both are covered in the
[Operator Guide](docs/OPERATOR-GUIDE.md#6-customizing-for-your-own-validators).

## Architecture in 10 lines

1. One self-contained `index.html` (HTML + CSS + vanilla JS, no build step).
2. Inside Nimiq Pay: `@nimiq/mini-app-sdk` (loaded from a CDN, pinned to 0.1.0 since 1.1.2) provides the wallet
   account and signs/sends staking transactions.
3. Outside Nimiq Pay: `@nimiq/hub-api` opens the Nimiq Hub popup to pick an address;
   transactions are built locally with `@nimiq/core` and signed + broadcast through the Hub.
4. `GET /api/v2/validators-list` supplies the validator list and their metrics.
5. `GET /api/v2/staker-status?address=…` supplies the account's real staking state and
   spendable balance, so the UI always reflects the chain rather than local guesses.
6. Both endpoints are served by your own backend, next to a Nimiq node — see the Operator Guide.
7. All user-visible text lives in one `T` dictionary (11 languages, same keys everywhere).
8. No cookies, no analytics, and nothing is sent to a third party. Storage is local to the browser only:
   the chosen language (`localStorage`); the action currently in flight, `vs:pending` (`sessionStorage` and
   `localStorage`, cleared when the chain reflects the action, on an error of the page that owns it, or by the
   explicit unlock button); a short list of the last actions, `vs:lastActions`, used to ignore duplicate taps
   (30 s window, up to 8 entries, contains the wallet address, never transmitted; overwritten later); and the
   favorite validators, `vs:favorites` (public validator addresses only, in order, at most 50, never the wallet
   address). All of it can be removed by clearing the site data.
   Fonts and libraries are loaded from third-party CDNs (Google Fonts, jsDelivr), which
   necessarily see the visitor's IP address.
9. A strict Content-Security-Policy is expected; the inline script is allowed by hash.
10. Details: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Running your own instance

Another Nimiq validator operator can deploy this mini app on their own infrastructure
and list their own validators first. Everything needed — backend endpoints and their
schemas, Nimiq node requirements, reverse proxy, CSP and hash computation, deployment
steps and a verification checklist — is in **[docs/OPERATOR-GUIDE.md](docs/OPERATOR-GUIDE.md)**.

## Documentation

| Document | Purpose |
|---|---|
| [docs/OPERATOR-GUIDE.md](docs/OPERATOR-GUIDE.md) | Deploy and operate the mini app on your own nodes |
| [docs/HOT-DEPLOY.md](docs/HOT-DEPLOY.md) | Runbook: reload a node without dropping connections, two-node setups |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the app is built and why |
| [docs/I18N.md](docs/I18N.md) | Translations: structure, key parity, adding a language |
| [docs/KNOWN-LIMITATIONS.md](docs/KNOWN-LIMITATIONS.md) | What has been verified on a real device, known limitations, candidate work |
| [docs/TESTING.md](docs/TESTING.md) | Manual test plan run before a release |
| [CHANGELOG.md](CHANGELOG.md) | History since the first publication (1.0.0) and ideas without a date |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [SECURITY.md](SECURITY.md) | Security model and how to report a vulnerability |

## Good to know

- **A balance of 0 in the app.** A wallet can show **0** on its main account while Nimiq Pay
  shows funds: funds received through a swap (for example a top-up inside Nimiq Pay) sit in a swap
  contract that Nimiq Pay can still use when staking. The app can only read the main-account
  balance, so it does not pre-fill the amount and shows a one-line hint under the amount field; it
  never blocks staking. Details: [docs/KNOWN-LIMITATIONS.md](docs/KNOWN-LIMITATIONS.md).
- **Confirmation takes a few seconds.** Blocks are about 1 second apart and a staking transaction is
  usually included about 2 blocks after it is sent (a rare outlier can take about 2 minutes). The
  app keeps checking for up to 60 seconds. The transaction history shown by a wallet app may lag
  behind the chain by up to a minute; the app reads the chain itself.
- **Reliability is capped at 100 %.** The statistics source can publish a value above 100 % for some validators;
  the API caps it at 100 % (a fraction between 0 and 1) and the app shows it as provided.

## Known issues and workarounds

**Create stake fails with "Your first stake couldn't be created"** (Nimiq Pay, funds that arrived in several transfers).
The "relay wallet" workaround, observed in our tests, **not a guarantee**:

1. Create a temporary wallet on [wallet.nimiq.com](https://wallet.nimiq.com) **and back it up first**, before
   sending anything to it.
2. Send your whole balance from Nimiq Pay to that wallet's address, checking the address character by character.
3. Wait until the funds have arrived.
4. Send **everything** back in **one single transfer** to your Nimiq Pay address.
5. Wait for "Processing funds" to finish in Nimiq Pay, then create your first stake again.

Risks: a wrong address or a forgotten backup can lose funds, so always double-check. Once your first stake exists,
adding to it works even if funds arrive in several transfers.

**Keep 5 NIM in Nimiq Pay.** Nimiq Pay sends Unstake, Finish unstaking and Switch from its swap contract; if
staking empties it, those requests cannot leave Nimiq Pay. Since 1.1.5 the app keeps 5 NIM spendable when you stake
(they are not spent by these requests). If everything is already staked, receive a few NIM first.

**Unstake and Switch take time.** That is the Nimiq staking protocol: unstaked NIM stay locked 12 to 24 hours
(until the end of the current epoch, then one more epoch) before "Finish unstaking" and "Claim my funds", and switching validator requires the stake to be unstaked first.
Until 1.1.2 the app sent requests the protocol refuses for both (fixed in 1.1.3; see the details below). Our
September reports to the Nimiq Pay team blamed Nimiq Pay for these failures: they were wrong, the cause was our app.

Details: [docs/KNOWN-LIMITATIONS.md](docs/KNOWN-LIMITATIONS.md).

## Project status

**Version 1.1.3** is the current release (the version is shown at the bottom of the app). **Version 1.0.0** was the first
publication: the version submitted to the Nimiq Mini Apps Competition (Cycle II) on 2026-09-18 (tag
`competition-submission`). Every change since is listed in the [CHANGELOG](CHANGELOG.md).

What has been verified, on one Android phone in Nimiq Pay with real funds: browsing, favorites, **Create stake**
and **Add stake** (executed on-chain on 2026-11-10 with Nimiq Pay 2.22.x; Create had failed in September), error
handling and duplicate-tap protection. **Not verified on a device yet:** the 1.1.3 **Unstake**, **Finish
unstaking** and **Switch validator** flows (until 1.1.2 those requests were invalid for the protocol), Claim with
the final build, and the Nimiq Hub path on mobile browsers or with a hardware wallet. The
details, with the environment, are in
[docs/KNOWN-LIMITATIONS.md](docs/KNOWN-LIMITATIONS.md#verification-status-current). Some translations
are machine-generated and have not been reviewed by native speakers — corrections are welcome (see
[docs/I18N.md](docs/I18N.md)).

## Reporting a bug

Found a problem? Use the **Report a bug** link in the app's footer, or [open an issue](https://github.com/Julien59247787/nimiq-app-validatorswipe/issues/new/choose)
with the bug template. Please include where you ran the app, which action failed and the error
message (with its technical detail), and **never** share private keys, seed phrases, passwords or
your full wallet address. Security vulnerabilities go through [SECURITY.md](SECURITY.md) instead.

## Contributing & security

Contributions are welcome — please read [CONTRIBUTING.md](CONTRIBUTING.md) and the
[Code of Conduct](CODE_OF_CONDUCT.md). To report a vulnerability, follow
[SECURITY.md](SECURITY.md); please do not open a public issue for security problems.

## License

[MIT](LICENSE) © 2026 Julien CURTO.

---

Made with ♥ by **@Ju'Team** (Ju & Claude) · [@julien59247787](https://x.com/julien59247787)
