# Contributing to Validator Swipe

Thanks for your interest! Contributions of all kinds are welcome: bug reports, translation
fixes, documentation, and code. By participating you agree to follow the
[Code of Conduct](CODE_OF_CONDUCT.md).

> **Security issues:** please do not open a public issue — follow [SECURITY.md](SECURITY.md).
> **Never** post private keys, seed phrases or passwords anywhere in this repository.

## Ground rules

Validator Swipe is intentionally simple, and the following constraints keep it that way:

1. **One static file.** The app is a single `index.html`. No framework, no bundler, no build
   step, no `package.json`. Please don't introduce one without discussing it first.
2. **Non-custodial.** The app must never handle private keys, and no code path may send a
   transaction without an explicit confirmation in the user's wallet.
3. **Never guess data.** A missing metric is shown as "—", never invented.
4. **Demo mode must stay honest.** Anything simulated must be clearly labeled as such.
5. **All 11 languages stay in sync.** Every translation key exists in every language
   ([docs/I18N.md](docs/I18N.md)).

## Reporting bugs and requesting features

Use the [issue templates](https://github.com/Julien59247787/nimiq-app-validatorswipe/issues/new/choose).
For bugs, tell us where you ran the app (Nimiq Pay / desktop browser + Hub / demo mode), which
action failed, and include the error message — the app shows a human message plus a collapsible
technical detail.

## Development setup

There is nothing to install:

```bash
git clone https://github.com/Julien59247787/nimiq-app-validatorswipe.git
cd nimiq-app-validatorswipe
python3 -m http.server 8080
# open http://localhost:8080
```

Served this way the app runs without a backend: the live validator list and staker status
are unavailable, and the app falls back to demo behavior. To test against real data, either
deploy behind the backend described in the [Operator Guide](docs/OPERATOR-GUIDE.md), or
temporarily point the two fetch URLs at a backend you control while you develop.

To test wallet flows:

- **Outside Nimiq Pay:** click "Connect" to use the Nimiq Hub popup with a real wallet.
  Use small amounts.
- **Inside Nimiq Pay:** the WebView is not remotely debuggable, so a temporary on-screen debug
  line is the practical way to inspect state — remove it before opening a pull request.

## Making a change

1. Fork the repository and create a branch (`fix/…`, `feat/…`, `docs/…`, `i18n/…`).
2. Make focused changes; unrelated cleanups belong in a separate pull request.
3. Before opening a pull request:
   - **Syntax:** load the page and check the browser console for errors. A missing brace in
     the inline script breaks the entire app. A quick sanity check is that the numbers of
     `{`/`}` and `(`/`)` in the script are equal.
   - **i18n:** if you touched any text, run the key-parity check from
     [docs/I18N.md](docs/I18N.md#the-golden-rule-key-parity) and make sure all 11 languages
     changed together.
   - **Layout:** check a narrow (phone-sized) viewport and the desktop layout, light and dark.
   - **No leaks:** no secrets, no internal hostnames/IPs, no personal data.
   - **Manual test plan:** run the relevant parts of [docs/TESTING.md](docs/TESTING.md).
4. Open the pull request using the template and describe how you tested it.

### Commit messages

Short, imperative summary line, with a type prefix when it helps:
`fix:`, `feat:`, `docs:`, `i18n:`, `style:`, `chore:`, `refactor:`. Explain the *why* in the body
when it isn't obvious.

### CSP note for maintainers

The deployment uses a Content-Security-Policy that allows the inline script by its SHA-256
hash. **Any change inside the `<script>` changes the hash** and must be redeployed together
with an updated header — see the [Operator Guide](docs/OPERATOR-GUIDE.md#34-content-security-policy).
CSS and markup changes do not.

## Translations

Native-speaker corrections are especially valuable. Change only the affected values in
`index.html`, keep every key, `{placeholder}` and HTML tag intact, and follow
[docs/I18N.md](docs/I18N.md).

## Documentation

Docs live in `docs/` and the top-level Markdown files, and are written in English. Please keep
them free of environment-specific details (hostnames, IPs, paths): use `example.org` and
`<your-domain>` placeholders.

## License

By contributing you agree that your contributions are licensed under the [MIT License](LICENSE).
