#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
readonly checkout=.tools/comment_gate
readonly repository=git@github.com:Nikoro/comment_gate.git

repository_reachable() {
  GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=10' \
    git ls-remote --exit-code "$repository" HEAD >/dev/null 2>&1
}

find_python() {
  local candidate
  for candidate in python3.15 python3.14 python3.13 python3.12 python3.11 /opt/homebrew/bin/python3 python3; do
    if command -v "$candidate" >/dev/null 2>&1 &&
      "$candidate" -c 'import sys; sys.exit(sys.version_info < (3, 11))' 2>/dev/null; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

if [[ ! -d "$checkout/.git" ]]; then
  if repository_reachable; then
    printf >&2 'comment_gate is missing from %s; run tool/setup.sh.\n' "$checkout"
    exit 1
  fi
  printf >&2 'Notice: comment_gate is a private repository this machine cannot reach, so the comment check is skipped. A maintainer runs it before merging; see "Comment policy" in CONTRIBUTING.md.\n'
  exit 0
fi

if ! python="$(find_python)"; then
  printf >&2 'comment_gate needs Python >= 3.11 (python3.11 to python3.15 or python3 in PATH, or /opt/homebrew/bin/python3); none was found.\n'
  exit 1
fi
exec "$python" "$checkout" "$@"
