#!/usr/bin/env bash
# Fetch a Claude design archive, unpack it, start a local HTTP server, and
# print server connection details on stdout.
#
# Output on success (3 lines):
#   line 1: URL to the entry HTML (e.g. http://127.0.0.1:51234/index.html)
#   line 2: server PID (pass to stop.sh for cleanup)
#   line 3: unpack directory (pass to stop.sh for cleanup)
#
# Accepts either:
#   - an https://api.anthropic.com/v1/design/h/<id>?open_file=<name> URL
#   - a local path to a .tar.gz archive
#
# A local HTTP server is required because Claude designs commonly use ES
# modules, fetch(), and other web APIs that fail under file:// origins.
#
# Exit codes: 0 success, 1 usage error, 2 archive missing/invalid,
# 3 no HTML inside, 4 server failed to start.

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

relpath="${entry#$tmpdir/}"

port="$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')"

nohup python3 -m http.server "$port" --bind 127.0.0.1 --directory "$tmpdir" \
  >"$tmpdir/.server.log" 2>&1 &
server_pid=$!
disown "$server_pid" 2>/dev/null || true

ready=0
for _ in $(seq 1 50); do
  if curl -sf "http://127.0.0.1:$port/" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 0.1
done

if [ "$ready" -ne 1 ]; then
  kill "$server_pid" 2>/dev/null || true
  echo "server failed to start on port $port (see $tmpdir/.server.log)" >&2
  rm -rf "$tmpdir"
  exit 4
fi

echo "http://127.0.0.1:$port/$relpath"
echo "$server_pid"
echo "$tmpdir"
