# 🛡️ Validator Swipe

**Pick a Nimiq validator with a swipe, delegate with a tap.**

Validator Swipe is a [Nimiq Pay](https://nimiq.com) mini app that turns choosing a
validator — usually a dry table of numbers — into a fast, informed decision, then lets
you delegate (stake) your NIM in one tap. It also covers the rest of the staking
lifecycle: switch validator, add stake, retire, and claim your funds back.

Built by **@Ju'Team** (Ju & Claude) for the Nimiq Mini Apps Competition, Cycle II.
Licensed under [MIT](LICENSE).

---

## Table of contents

- [Features](#features)
- [How staking works here](#how-staking-works-here)
- [Quick start](#quick-start)
- [Architecture in 10 lines](#architecture-in-10-lines)
- [Running your own instance](#running-your-own-instance)
- [Documentation](#documentation)
- [Project status](#project-status)
- [Contributing & security](#contributing--security)
- [License](#license)

## Features

- **Every active validator, real data.** Uptime, reliability, reward rate, delegation
  fee and total stake for all active validators (~40 on mainnet), not a curated
  shortlist. Missing metrics are shown as `—`, never guessed.
- **Two-phase flow.** *Browse* (skip / set aside — free, no transaction) then
  *My favorites* (the only place a transaction can be sent). Nothing is ever delegated
  by accident while browsing.
- **Complete staking lifecycle**, driven by the account's real on-chain state:
  create a staker, add to an existing stake, switch validator, **retire** a stake,
  then **claim** the funds after the network waiting period.
- **Runs inside Nimiq Pay *and* in a regular browser.** Inside Nimiq Pay it uses the
  Mini App SDK. Outside, a "Connect" button uses the Nimiq Hub, so the app can be
  tried and used with a real wallet in any browser.
- **Non-custodial by design.** The app never sees a private key: every transaction is
  signed in Nimiq Pay or the Nimiq Hub. See [SECURITY.md](SECURITY.md).
- **Honest demo mode.** With no wallet connected the app stays browsable, and any
  simulated action is clearly labeled as a demo — it can never be mistaken for a real one.
- **11 languages** (fr, en, es, zh, ja, ko, de, pt, ru, tr, ar), English by default.
  See [docs/I18N.md](docs/I18N.md).
- **Single static file.** No build step, no bundler, no framework — one `index.html`.

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
| Staker exists, other validator | Switch validator | update staker (moves the whole stake) |
| Want your funds back | Step 1: wait for epoch end | retire stake |
| Retired stake available | Step 2: claim | remove stake |

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

## Architecture in 10 lines

1. One self-contained `index.html` (HTML + CSS + vanilla JS, no build step).
2. Inside Nimiq Pay: `@nimiq/mini-app-sdk` (loaded from a CDN) provides the wallet
   account and signs/sends staking transactions.
3. Outside Nimiq Pay: `@nimiq/hub-api` opens the Nimiq Hub popup to pick an address;
   transactions are built locally with `@nimiq/core` and signed + broadcast through the Hub.
4. `GET /api/v2/validators-list` supplies the validator list and their metrics.
5. `GET /api/v2/staker-status?address=…` supplies the account's real staking state and
   spendable balance, so the UI always reflects the chain rather than local guesses.
6. Both endpoints are served by your own backend, next to a Nimiq node — see the Operator Guide.
7. All user-visible text lives in one `T` dictionary (11 languages, same keys everywhere).
8. No cookies, no tracking, no analytics; the only persisted value is the chosen language
   (`localStorage`).
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
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the app is built and why |
| [docs/I18N.md](docs/I18N.md) | Translations: structure, key parity, adding a language |
| [CHANGELOG.md](CHANGELOG.md) | History of changes, plus ideas for future improvements |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute |
| [SECURITY.md](SECURITY.md) | Security model and how to report a vulnerability |

## Project status

Submitted to the Nimiq Mini Apps Competition (Cycle II). The complete real staking
cycle (create / add / switch / retire / claim) has been tested on a real device with
real funds. Some translations are machine-generated and have not been reviewed by
native speakers — corrections are welcome (see [docs/I18N.md](docs/I18N.md)).

## Contributing & security

Contributions are welcome — please read [CONTRIBUTING.md](CONTRIBUTING.md) and the
[Code of Conduct](CODE_OF_CONDUCT.md). To report a vulnerability, follow
[SECURITY.md](SECURITY.md); please do not open a public issue for security problems.

## License

[MIT](LICENSE) © 2026 Julien CURTO.

---

Made with ♥ by **@Ju'Team** (Ju & Claude) · [@julien59247787](https://x.com/julien59247787)
