# 🛡️ Validator Swipe

A Nimiq Pay mini app that turns choosing a validator — usually a dry table of
numbers — into a fast, informed decision, then lets you delegate in one tap.

## What it does

New to Nimiq? **Staking** lets you put your NIM to work: you delegate it to a
validator (a computer that keeps the network running), and earn a share of
the network's rewards — without ever sending your funds away. You can
withdraw at any time; the validator never holds your NIM.

Validator Swipe shows you every active validator on the Nimiq network — not a
curated shortlist — each with real, live data: uptime, reliability, reward
rate, delegation fee, total stake. Swipe through them, **set favorites aside**
to compare (no transaction, completely free), then delegate for real only
once you've decided, from a dedicated "My favorites" view. Delegating never
happens by accident while browsing.

## Who it's for

Anyone holding NIM who wants their stake earning rewards, but doesn't want to
dig through a raw JSON API or a spreadsheet to pick a validator.

## How it uses Nimiq Pay

- `@nimiq/mini-app-sdk` `init()` to detect the Nimiq Pay environment and
  connect the user's wallet.
- A real `sendNewStakerTransaction()` delegates NIM to the chosen validator —
  the only place in the app a transaction fires.
- Live validator data (address, stake, availability, reliability, reward
  rate, fee) is pulled from the team's own production API, itself sourced
  from the Nimiq network and NimiqHub — never invented placeholder numbers.
- Falls back to a clearly-labeled simulated mode outside Nimiq Pay, so the
  app stays testable in any browser.

## Built by real validator operators

The two top-billed validators (`nodenimiq1`/`nodenimiq2.nimiq-ju.fr`) are our
own, in production since December 2024 — this app was built by people who
actually run Nimiq validators, for people who want to pick one.

---

Built for the Nimiq Mini Apps Competition, Cycle II (Aug 24 – Sep 18, 2026).
