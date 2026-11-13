#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
GATE="$ROOT/.tools/commit_gate"
cd "$ROOT"
if [[ -e "$GATE" ]] && [[ ! -d "$GATE/.git" ]]; then
  printf >&2 '%s is not a Git clone; move it aside before installing commit_gate.\n' "$GATE"
  exit 2
fi
if [[ -d "$GATE/.git" ]]; then
  if ! checkout_status="$("$ROOT/tool/commit_gate_git.sh" --git-dir="$GATE/.git" --work-tree="$GATE" status --porcelain)"; then
    printf >&2 'commit_gate is not a valid Git checkout at %s; repair the installation.\n' "$GATE"
    exit 2
  fi
  if [[ -n "$checkout_status" ]]; then
    printf >&2 'commit_gate has local changes at %s; keep fixes in a separate clone.\n' "$GATE"
    exit 2
  fi
  GIT_TERMINAL_PROMPT=0 "$ROOT/tool/commit_gate_git.sh" -C "$GATE" fetch origin main
  "$ROOT/tool/commit_gate_git.sh" -C "$GATE" merge --ff-only FETCH_HEAD
else
  mkdir -p "$ROOT/.tools"
  GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o BatchMode=yes -o ConnectTimeout=10}" \
    "$ROOT/tool/commit_gate_git.sh" clone git@github.com:Nikoro/commit_gate.git "$GATE"
fi
"$ROOT/tool/commit_gate.sh" --help >/dev/null
"$ROOT/tool/python.sh" "$ROOT/scripts/quality/check_duplicates.py"

git config core.hooksPath .githooks
printf 'Hooks installed: core.hooksPath -> .githooks\n'
