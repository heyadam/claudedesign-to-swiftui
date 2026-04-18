#!/usr/bin/env bash
# Stop a server started by fetch.sh and clean up its unpack dir.
# Usage: stop.sh <pid> <dir>

set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <pid> <dir>" >&2
  exit 1
fi

pid="$1"
dir="$2"

kill "$pid" 2>/dev/null || true
rm -rf "$dir"
