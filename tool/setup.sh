#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
readonly checkout=.tools/commit_gate
readonly repository=git@github.com:Nikoro/commit_gate.git

checkout_commit_gate() {
  if [[ ! -d "$checkout/.git" ]]; then
    mkdir -p .tools
    if ! GIT_TERMINAL_PROMPT=0 GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=10' \
      git clone --quiet "$repository" "$checkout"; then
      printf >&2 'Notice: %s could not be cloned. It is a private repository; without it the hooks skip the comment check and a maintainer runs it before merging.\n' "$repository"
      return 0
    fi
  fi
  if [[ -n "$(git -C "$checkout" status --porcelain)" ]]; then
    printf >&2 'The commit_gate checkout in %s is modified.\n' "$checkout"
    exit 1
  fi
  git -C "$checkout" fetch --quiet origin main
  git -C "$checkout" checkout --quiet --detach FETCH_HEAD
}

checkout_commit_gate
git config core.hooksPath .githooks
