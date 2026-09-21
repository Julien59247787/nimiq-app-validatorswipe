#!/bin/sh
# Release guard: the version shown at the bottom of the app, its link, and the newest dated CHANGELOG entry
# must all be the same. Usage: scripts/check-version.sh [expected-tag, e.g. v1.1.1]
cd "$(dirname "$0")/.." || exit 2
text=$(grep -o 'credit-version-link"[^>]*>v[0-9][0-9.]*</a>' index.html | sed 's/.*>\(v[0-9.]*\)<\/a>/\1/')
link=$(grep -o 'credit-version-link" href="[^"]*' index.html | sed 's/.*releases\/tag\///')
log=v$(grep -m1 -o '^## \[[0-9][0-9.]*\] — 20' CHANGELOG.md | sed 's/^## \[\([0-9.]*\)\].*/\1/')
echo "shown: $text   link: $link   changelog: $log   expected: ${1:-none given}"
[ -n "$text" ] && [ "$text" = "$link" ] && [ "$text" = "$log" ] || { echo "MISMATCH"; exit 1; }
[ -z "$1" ] || [ "$1" = "$text" ] || { echo "MISMATCH with the expected tag"; exit 1; }
echo OK
