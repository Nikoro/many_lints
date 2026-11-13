#!/usr/bin/env bash
set -euo pipefail
for candidate in python3.15 python3.14 python3.13 python3.12 python3.11 /opt/homebrew/bin/python3 python3; do
  if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2>/dev/null; then
    exec "$candidate" "$@"
  fi
done
printf >&2 'commit_gate needs Python 3.11 or newer on PATH.\n'
exit 2
