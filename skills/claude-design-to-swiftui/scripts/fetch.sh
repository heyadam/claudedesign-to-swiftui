#!/usr/bin/env bash
# Fetch a Claude design archive and print the entry HTML path on stdout.
#
# Accepts either:
#   - an https://api.anthropic.com/v1/design/h/<id>?open_file=<name> URL
#   - a local path to a .tar.gz archive
#
# If the URL has an ?open_file=... query param, that filename (URL-decoded) is
# used as the entry HTML hint. Otherwise (or for local paths) the script falls
# back to: first index.html, else first *.html.
#
# Exit codes: 0 success, 1 usage error, 2 archive missing/invalid, 3 no HTML inside.

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "usage: $0 <design-url-or-tarball-path>" >&2
  exit 1
fi

input="$1"
open_file=""
archive=""
tmpdir="$(mktemp -d -t cd2xcode-XXXXXX)"

case "$input" in
  http://*|https://*)
    archive="$tmpdir/design.tar.gz"
    if ! curl -sSfL --max-time 60 -o "$archive" "$input"; then
      echo "failed to download: $input" >&2
      rm -rf "$tmpdir"
      exit 2
    fi
    query="${input#*\?}"
    if [ "$query" != "$input" ]; then
      IFS='&' read -ra parts <<< "$query"
      for p in "${parts[@]}"; do
        if [[ "$p" == open_file=* ]]; then
          raw="${p#open_file=}"
          open_file="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.unquote_plus(sys.argv[1]))' "$raw")"
          break
        fi
      done
    fi
    ;;
  *)
    if [ ! -f "$input" ]; then
      echo "archive not found: $input" >&2
      rm -rf "$tmpdir"
      exit 2
    fi
    archive="$input"
    ;;
esac

if ! tar -xzf "$archive" -C "$tmpdir" 2>/dev/null; then
  echo "failed to extract: $archive" >&2
  rm -rf "$tmpdir"
  exit 2
fi

entry=""
if [ -n "$open_file" ]; then
  entry="$(find "$tmpdir" -type f -name "$open_file" -print -quit)"
fi
if [ -z "$entry" ]; then
  entry="$(find "$tmpdir" -type f -name 'index.html' -print -quit)"
fi
if [ -z "$entry" ]; then
  entry="$(find "$tmpdir" -type f -name '*.html' -print -quit)"
fi

if [ -z "$entry" ]; then
  echo "no HTML file found in archive" >&2
  rm -rf "$tmpdir"
  exit 3
fi

echo "$entry"
