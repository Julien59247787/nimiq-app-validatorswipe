# Hot-deploy runbook — lighttpd2 behind a load balancer (Validator Swipe hosting)

Generic companion to the [Operator Guide](OPERATOR-GUIDE.md) (section 3.5, multi-node deployments). No secrets, no real addresses or hostnames: `nodeA` / `nodeB` are the two identical web+API nodes, `lb` is the reverse proxy in front (round-robin, active health check on `GET /`, retries on connection errors only).

Everything below was run for real on a two-node setup (about 25 deployments in one day, zero 5xx seen by clients).

## 1. Principles

1. **Never restart the web server for a content or header change.** Replace the worker instead (section 3). A full `systemctl restart` refuses connections for about 3 s.
2. **One node at a time**, then a pause of at least 60 s and a health check of the other node before touching it. The pause lets the balancer's health check settle and the first node take traffic again.
3. **Test before reloading**: `lighttpd2-worker -t -c <candidate>` must exit 0 with no "config error" line. An invalid config plus a reload leaves the site with no worker.
4. **Both nodes stay byte-identical** (SHA-256), except two tolerated differences: the per-node TLS `pemfile` line and any per-node page title.
5. **Backups go outside the docroot** (public `*.bak` files in a web root are downloadable). Use e.g. `<backup-dir>/<what>-<timestamp>/` (root-only).
6. **Rollback must be ready before you start** and, where possible, instant (section 6).
7. **Verify by hash, not by eye**: SHA-256 of what is actually served, on each node, via the per-node hostname and via the public round-robin.

## 2. lighttpd2 facts that matter

- Two processes: an **angel** (supervisor, owns the listening sockets) and a **worker**. `kill -USR1 <worker>` makes the angel start a new worker and retire the old one: no refused connection (only transfers in flight on the old worker are cut).
- `SIGHUP` on the angel does nothing useful. `USR1` on the angel kills it. Always signal the **worker**.
- After the signal, wait for a *new* worker PID and check the angel PID did not change.
- `-t` prints harmless "Address already in use" noise (it cannot bind while the real server runs). Trust the exit code plus the absence of "config error".
- `if` blocks are evaluated in file order. An `index ("index.html")` directive rewrites `/` to `/index.html` **before** later rules, so a later rule on `request.path == "/"` never fires (a common pitfall): match both `/` and `/index.html`.
- `header.overwrite` in a later block wins over an earlier one. That is how nested test paths override the production CSP (section 5).

## 3. Reload procedure (config and/or content)

Per node, best scripted (write your own; every step read-only until every guard passes):

1. Guards: expected hash present exactly once, candidate config differs from the live one by the expected number of lines only, the change lies inside the intended `if` block, `-t` passes, exactly one angel and one worker exist.
2. Backup the live config (and the page being replaced) outside the docroot.
3. Install the candidate config, `kill -USR1 <worker>`, wait for the new worker PID (≤ 6 s), check the angel PID is unchanged.
4. **Then** install the content: write `.new` next to the target and `mv -f` it (atomic rename). If a new asset (image) is referenced by the page, install the asset first, the HTML last.
5. Print: sha256 of the served file, hashes now in the CSP, local `/api/health`, service state.

While it runs, an **external probe loop** (through the public name, ~5 req/s, ≥ 60 s) records status codes and latency. Expected: all 200, max latency well under 1.5 s. Typical worker swap: 0.1–0.6 s.

After both nodes: 16+ requests through the round-robin, each checked for **per-response consistency** (the hash of the inline script of that response must appear in the CSP header of the same response), then the symmetry script (files, CSP as configured and as served, whole `lighttpd.conf` diff except `pemfile`, services active, health of each node, page versions seen).

## 4. CSP by hash

The app has one inline `<script>`; the CSP allows it by SHA-256.

- Recompute on **every** change of the `<script>` content (not for CSS or HTML outside the script). Normalize CRLF to LF before hashing:
  `perl -0777 -ne 'print $1 if /<script>(.*?)<\/script>/s' index.html | tr -d '\r' | openssl dgst -sha256 -binary | openssl base64 -A`
  Cross-check with a second, independent implementation (Node `crypto`, or the browser itself).
- **Double hash during transition** (old + new in `script-src`) so that the page never breaks whatever node or version answers; then swap the HTML; remove the old hash in a later clean-up. With three versions in flight (prod, candidate, test) the prod block can temporarily hold three hashes.
- A mixed-version window (node A done, node B not yet) is safe **only** because of the double hash: verify per response (section 3).
- Keep the `report-uri` endpoint: a CSP violation report right after a deploy is the fastest signal that a hash is wrong.

## 5. Test paths on the production origin

To let testers use the real origin (wallet allow-lists, same-origin storage) without touching production, publish candidate builds under nested sub-paths of the app prefix (for example `/…/<app>/candidate/` and `/…/<app>/diagnostic/`).

- Declare each test block **after** the production block so its own CSP (hash of that build) overrides it.
- Every test block sets `Cache-Control: no-store` and `X-Robots-Tag: noindex, nofollow, noarchive`, and is not linked from anywhere.
- Same origin means shared `localStorage`: keys written by a test build are visible to production and vice versa. Namespaced keys and short expiry keep this harmless.
- **Instrumented/diagnostic builds live only under their own path.** Add an explicit guard: a marker string of the instrumentation must be absent from production and from the other test paths (grep the served bytes), present only under the diagnostic path.
- Test directories accumulate `index.html.bak-*` files (public). Clean them up together with the test blocks when the test is over (clean-up is a separate, explicit go).

## 6. Rollback

- **Content**: put the backed-up `index.html` back (atomic `mv`). If the old script hash is still in the CSP (double-hash phase) no reload is needed at all.
- **Config**: restore the timestamped `lighttpd.conf` backup, `-t`, `USR1`.
- Roll back one node, verify, then the other; same probes and pause.

## 7. Cache-Control on the production page

The HTML is served `Cache-Control: no-cache` (revalidate every load), only for the app root and its `index.html`, via a dedicated small block. Static assets (images, video) are left alone; test paths keep `no-store`.

**ETag caveat (measured):** lighttpd2's ETag is not derived from mtime alone. Two identical files with the *same* mtime on two nodes get *different* ETags (inode and/or size take part), so aligning mtimes does **not** align ETags. Consequence: behind a round-robin, a conditional request that lands on the other node gets a full 200 instead of a 304. This is correct and harmless (a few extra KB), just not optimal; a 304 works normally per node. Do not spend effort on `touch`.

## 8. Restarting the API without visible errors

A reverse proxy retries only on connection-level errors. If the web server stays up and answers 502/503 because the API behind it is stopped, the proxy forwards that 5xx to the client without retrying on the other node, and its active health check (`GET /`) does not see the API. So **drain the node first**:

1. Add a temporary rule making `/` and `/index.html` answer 503 on this node (`respond 503;`), validate with `-t`, reload the worker.
2. Wait ~15 s (health check interval + timeout) until the balancer stops sending traffic to it.
3. Restart the API service; wait for its `/api/health` to return 200 (usually 1–2 s).
4. Only then remove the drain rule (same procedure), wait ~15 s for two successful checks.
5. Pause ≥ 60 s, do the other node.

Measured result: API restart absorbed with zero client-visible 5xx; the only 503s in the web log were the health checks themselves. Side effect: the node's own dashboard root returns 503 for ~30–40 s.

Deploying an API change also means: back up the old source outside the source tree, install with the original owner/mode, commit to the local repository, verify identical SHA-256 on both nodes, and test the change first on a **separate process on another port** against the real database (read-only queries), comparing field by field with the live output. Beware null handling: `Number(null)` is `0`, so a clamp such as `Math.min(1, Number(x))` silently turns nulls into zeros — keep nulls as nulls.

## 9. API load and latency (measured)

- `staker-status` and `validators-list` are served with `Cache-Control: no-store`, TTL 0; each `staker-status` request costs about 2 local RPC calls (~1 ms each when the node is healthy).
- Per-client-IP concurrency cap of 20 simultaneous requests at the web server: excess requests get a **clean 503** (no stall, no crash). Behind a shared proxy all users appear as one IP; keep that in mind before lowering the cap.
- Recommended client polling after a transaction: about 1.8 s, then 2 s growing to 20 s, then every 5 s, hard cap at 60 s. About one request every 6 s per active user in the steady state was comfortable.
- `/api/health` reads the database (3 small reads), so it is sensitive to write locks: always set a busy timeout when querying the database from scripts (`.timeout 20000`), or you will see spurious "database is locked".
- Dates in SQLite are stored as ISO-8601 text: compare with `strftime('%Y-%m-%dT%H:%M:%fZ','now','-N minutes')`, not with `datetime('now')` (different format, wrong lexical comparison).

## 10. Pre-flight / post-flight checklist

Before: symmetry script all green · candidate config `-t` OK · hashes recomputed (two methods) · backups taken · load balancer operator informed · no long transfer in progress (e.g. a demo video) · rollback path written down.

After: served sha256 per node = expected · CSP header hashes per node identical · 16+ round-robin responses consistent · production page unchanged where it should be (fingerprint) · diagnostic marker absent from production · probes all 200 · load balancer logs reviewed for the window (5xx, slow requests, up/down transitions) · journal entry written (UTC chronology, PIDs before/after, backup locations).
