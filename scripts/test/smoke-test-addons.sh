#!/usr/bin/env bash
# Helper functions for optional add-on smoke checks (R, QLever, Oxygraph, Ollama).

check_optional_addon() {
  local addon_name="$1"
  local command_name="$2"
  local include_flag_value="$3"

  if command -v "$command_name" >/dev/null 2>&1; then
    echo "[ok] command available: $command_name"
    if [[ "$include_flag_value" == "false" ]]; then
      echo "[warn] $addon_name detected by command discovery even though include flag is false"
    fi
    return 0
  fi

  if [[ "$include_flag_value" == "true" ]]; then
    echo "[error] $addon_name expected (include flag true) but command '$command_name' not found" >&2
    return 1
  fi

  echo "[ok] $addon_name checks skipped (not installed)"
  return 0
}

run_optional_addon_smoke_checks() {
  check_optional_addon "R" "R" "${DARTFX_INCLUDE_R:-false}"
  check_optional_addon "Rscript" "Rscript" "${DARTFX_INCLUDE_R:-false}"
  check_optional_addon "QLever" "qlever" "${DARTFX_INCLUDE_QLEVER:-false}"
  check_optional_addon "Oxygraph" "oxigraph" "${DARTFX_INCLUDE_OXYGRAPH:-false}"
  check_optional_addon "Ollama" "ollama" "${DARTFX_INCLUDE_OLLAMA:-false}"
}

is_command_available() {
  command -v "$1" >/dev/null 2>&1
}