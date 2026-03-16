#!/usr/bin/env bash
set -euo pipefail

# Safety check: ensure we are inside a container
if [ ! -f /.dockerenv ]; then
  echo "[error] smoke-test.sh must be run INSIDE the Docker container."
  echo "Please use: ./test-image.sh <image_name>"
  exit 1
fi

echo "[test] Starting smoke tests..."

check_cmd() {
  local name="$1"
  command -v "$name" >/dev/null
  echo "[ok] command available: $name"
}

check_file() {
    if [ -f "$1" ]; then
        echo "[ok] file exists: $1"
    else
        echo "[error] file missing: $1"
        exit 1
    fi
}

# Tests for visidata
vd --version

# Tests for r
R --version
Rscript --version

# Tests for node
su - dartfx -c 'export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"; node --version && pnpm --version'

# Tests for claude
su - dartfx -c 'export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"; claude --version'

# Tests for readstat
readstat --version

# Tests for gemini
su - dartfx -c 'export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"; gemini --version'

# Tests for qlever
qlever --version

# Tests for oxygraph
oxigraph --version

# Tests for python
python3 --version
uv --version

# Tests for postgres
psql --version
pg_config --pkglibdir

# Tests for qsv
qsv --version

# Tests for duckdb
duckdb --version

# Python library imports
/home/dartfx/.venvs/dartfx/bin/python - <<'PY'
import sys, importlib
failed = False
import_map = {"ipython": "IPython", "dartfx-ddi": "dartfx.ddi", "dartfx-rdf": "dartfx.rdf"}
pkg_name = 'duckdb'
import_name = import_map.get(pkg_name, pkg_name.replace('-', '_'))
try:
    importlib.import_module(import_name)
    print(f'[ok] python import: {pkg_name} (as {import_name})')
except ImportError as e:
    print(f'[error] failed to import {pkg_name}: {e}')
    failed = True
pkg_name = 'dartfx-rdf'
import_name = import_map.get(pkg_name, pkg_name.replace('-', '_'))
try:
    importlib.import_module(import_name)
    print(f'[ok] python import: {pkg_name} (as {import_name})')
except ImportError as e:
    print(f'[error] failed to import {pkg_name}: {e}')
    failed = True
pkg_name = 'dartfx-ddi'
import_name = import_map.get(pkg_name, pkg_name.replace('-', '_'))
try:
    importlib.import_module(import_name)
    print(f'[ok] python import: {pkg_name} (as {import_name})')
except ImportError as e:
    print(f'[error] failed to import {pkg_name}: {e}')
    failed = True
pkg_name = 'jupyterlab'
import_name = import_map.get(pkg_name, pkg_name.replace('-', '_'))
try:
    importlib.import_module(import_name)
    print(f'[ok] python import: {pkg_name} (as {import_name})')
except ImportError as e:
    print(f'[error] failed to import {pkg_name}: {e}')
    failed = True
pkg_name = 'pyarrow'
import_name = import_map.get(pkg_name, pkg_name.replace('-', '_'))
try:
    importlib.import_module(import_name)
    print(f'[ok] python import: {pkg_name} (as {import_name})')
except ImportError as e:
    print(f'[error] failed to import {pkg_name}: {e}')
    failed = True
pkg_name = 'psycopg'
import_name = import_map.get(pkg_name, pkg_name.replace('-', '_'))
try:
    importlib.import_module(import_name)
    print(f'[ok] python import: {pkg_name} (as {import_name})')
except ImportError as e:
    print(f'[error] failed to import {pkg_name}: {e}')
    failed = True
pkg_name = 'ipython'
import_name = import_map.get(pkg_name, pkg_name.replace('-', '_'))
try:
    importlib.import_module(import_name)
    print(f'[ok] python import: {pkg_name} (as {import_name})')
except ImportError as e:
    print(f'[error] failed to import {pkg_name}: {e}')
    failed = True
pkg_name = 'pandas'
import_name = import_map.get(pkg_name, pkg_name.replace('-', '_'))
try:
    importlib.import_module(import_name)
    print(f'[ok] python import: {pkg_name} (as {import_name})')
except ImportError as e:
    print(f'[error] failed to import {pkg_name}: {e}')
    failed = True
if failed: sys.exit(1)
PY

# R library installation check
Rscript -e 'pkgs <- c("sdcMicro", "tidyverse", "data.table", "sf", "arrow", "jsonlite", "RPostgres", "rollama", "DBI", "terra", "ellmer", "duckdb"); missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]; if(length(missing) > 0) { stop("Missing R packages: ", paste(missing, collapse=", ")) } else { cat("[ok] all R packages found\n") }'

# Sub-option test: pgvector
pg_config --pkglibdir | xargs -I{} test -f '{}/vector.so'

echo "[ok] All smoke tests passed!"