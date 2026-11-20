#!/bin/bash
# Checks that this Mac can build the workshop VM.
# A Mac cannot create a macOS VM newer than its own OS.
# Usage: ./check-host.sh 26
set -u
case "${1:-}" in
  26) REQUIRED="26.6.2"; NAME="Tahoe" ;;
  *) echo "Usage: $0 26"; exit 2 ;;
esac
HOST="$(sw_vers -productVersion)"
if [ "$(uname -m)" != "arm64" ]; then
  echo "FAIL: Apple silicon is required (found $(uname -m))."; exit 1
fi
# true if $1 >= $2 (dotted versions)
ver_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)" = "$2" ]; }
if ver_ge "$HOST" "$REQUIRED"; then
  echo "OK: host macOS $HOST can build the macOS $REQUIRED ($NAME) VM."
else
  echo "FAIL: host macOS $HOST is older than $REQUIRED. Update this Mac to macOS $REQUIRED or later (System Settings > General > Software Update), or build a different VM."
  exit 1
fi
command -v tart >/dev/null || echo "WARN: tart not found (brew install cirruslabs/cli/tart)"
command -v packer >/dev/null || echo "WARN: packer not found (brew install hashicorp/tap/packer)"
