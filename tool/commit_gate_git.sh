#!/usr/bin/env bash
set -euo pipefail
local_environment="$(git rev-parse --local-env-vars)"
while IFS= read -r variable; do
  unset "$variable"
done <<< "$local_environment"
exec git "$@"
