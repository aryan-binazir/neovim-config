#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
suite=${1:-}
case "$suite" in source_preparation|pane_delivery) ;; *) echo "Usage: bash tests/run.sh {source_preparation|pane_delivery}" >&2; exit 2 ;; esac
runtime=$(mktemp -d /tmp/nvim-ai-tests.XXXXXX)
trap 'rm -rf -- "$runtime"' EXIT
unset TMUX TMUX_PANE HERDR_ENV NVIM NVIM_LISTEN_ADDRESS
export AI_TEST_TMP="$runtime"
export XDG_CACHE_HOME="$runtime/cache" XDG_DATA_HOME="$runtime/data" XDG_STATE_HOME="$runtime/state"
export XDG_CONFIG_HOME="$runtime/config" XDG_RUNTIME_DIR="$runtime/runtime" NVIM_LOG_FILE="$runtime/nvim.log"
mkdir -p "$XDG_RUNTIME_DIR" "$runtime/.git"
chmod 700 "$XDG_RUNTIME_DIR"
status=0
timeout 40s nvim --headless -u NONE -i NONE -l "tests/$suite.lua" </dev/null >"$runtime/output" 2>&1 || status=$?
cat "$runtime/output"
if ! grep -Eq "^${suite} checks passed"$'\r'"?$" "$runtime/output"; then
  echo "$suite suite did not complete" >&2
  if [[ "$status" == 0 ]]; then status=1; fi
fi
exit "$status"
