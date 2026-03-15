#!/usr/bin/env bash
# Main in-container smoke test suite: always-on base checks plus optional add-on checks.
# Runs INSIDE the container. Do not execute directly on the host.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/smoke-test-addons.sh"

check_cmd() {
  local name="$1"
  command -v "$name" >/dev/null
  echo "[ok] command available: $name"
}

check_file() {
  local path="$1"
  [[ -e "$path" ]]
  echo "[ok] path exists: $path"
}

check_cmd python3
check_cmd uv
check_cmd vd
check_cmd duckdb
check_cmd qsv
check_cmd psql
check_cmd supervisord
run_optional_addon_smoke_checks

id dartfx >/dev/null
id postgres >/dev/null
echo "[ok] users exist: dartfx, postgres"

check_file /etc/supervisor/supervisord.conf
check_file /opt/dartfx/scripts/runtime/start-postgres.sh
check_file /home/dartfx/.venvs/dartfx/bin/python

pg_config --pkglibdir | xargs -I{} test -f '{}/vector.so'
echo "[ok] pgvector library installed"

/home/dartfx/.venvs/dartfx/bin/python - <<'PY'
import duckdb
import pandas
import pyarrow
print("[ok] python supplemental packages import")
PY

if is_command_available R && [[ -f /opt/dartfx/r-packages.txt ]]; then
  mapfile -t r_packages < <(sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' /opt/dartfx/r-packages.txt | awk 'NF')
  if (( ${#r_packages[@]} > 0 )); then
    Rscript - "${r_packages[@]}" <<'RS'
args <- commandArgs(trailingOnly = TRUE)
missing <- args[!vapply(args, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  cat(sprintf("[error] Missing R package(s): %s\n", paste(missing, collapse = ", ")), file = stderr())
  quit(save = "no", status = 1)
}
cat(sprintf("[ok] R supplemental packages installed: %s\n", paste(args, collapse = ", ")))
RS
  else
    echo "[ok] no R supplemental packages listed"
  fi
else
  echo "[ok] R supplemental package checks skipped (R installed: $(is_command_available R && echo true || echo false), manifest present: $( [[ -f /opt/dartfx/r-packages.txt ]] && echo true || echo false ))"
fi

if is_command_available R; then
  Rscript - ellmer rollama tidyllm openai httr2 <<'RS'
args <- commandArgs(trailingOnly = TRUE)
installed <- rownames(installed.packages())
to_check <- intersect(args, installed)

if (length(to_check) == 0) {
  cat("[ok] no R LLM integration packages installed\n")
  quit(save = "no", status = 0)
}

failed <- character()
for (pkg in to_check) {
  ok <- tryCatch({
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
    TRUE
  }, error = function(e) {
    message(sprintf("[error] Failed to load R package '%s': %s", pkg, conditionMessage(e)))
    FALSE
  })
  if (!ok) {
    failed <- c(failed, pkg)
  }
}

if (length(failed) > 0) {
  quit(save = "no", status = 1)
}

cat(sprintf("[ok] R LLM integration packages load: %s\n", paste(to_check, collapse = ", ")))
RS
else
  echo "[ok] R LLM package load checks skipped (R installed: $(is_command_available R && echo true || echo false))"
fi

if is_command_available ollama; then
  su - dartfx -c 'source /home/dartfx/.nvm/nvm.sh && node --version >/dev/null && pnpm --version >/dev/null && ollama-code --help >/dev/null && command -v claude >/dev/null && command -v gemini >/dev/null'
  echo "[ok] node/pnpm/ollama-code/claude/gemini available for dartfx"
else
  su - dartfx -c 'source /home/dartfx/.nvm/nvm.sh && node --version >/dev/null && pnpm --version >/dev/null && command -v claude >/dev/null && command -v gemini >/dev/null'
  echo "[ok] node/pnpm/claude/gemini available for dartfx"
fi

su - dartfx -c 'test -d /home/dartfx/.gemini && test ! -f /home/dartfx/.gemini/projects.json.tmp'
echo "[ok] gemini state directory ready for dartfx"

echo "[ok] image smoke tests passed"
