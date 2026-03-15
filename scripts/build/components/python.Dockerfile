# syntax=docker/dockerfile:1
ARG BASE_IMAGE=kulnor/fair-data-machine:dev
FROM ${BASE_IMAGE}

ARG DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Python3 runtime and venv support.
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-venv python3-dev && \
    rm -rf /var/lib/apt/lists/*

# uv: fast Python package manager, installed to a system-wide path.
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Install supplemental packages into a dartfx-owned virtual environment.
COPY pyproject.toml /opt/dartfx/pyproject.toml
RUN <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

MANIFEST_PATH="/opt/dartfx/pyproject.toml"

mapfile -t manifest_lines < <(python3 - "$MANIFEST_PATH" <<'PY'
import sys
import tomllib
from pathlib import Path

manifest_path = Path(sys.argv[1])
data = tomllib.loads(manifest_path.read_text())

python_config = data.get("tool", {}).get("dartfx", {}).get("python", {}) or data.get("python", {})
venv_path = python_config.get("venv_path", "")
package_groups = python_config.get("packages", {})
install_groups = python_config.get("install_groups") or ["core"]

seen = set()
packages = []
for group in install_groups:
  for package in package_groups.get(group, []):
    if package not in seen:
      seen.add(package)
      packages.append(package)

print(f"__VENV__={venv_path}")
for package in packages:
    print(package)
PY
)

manifest_venv_path="${manifest_lines[0]#__VENV__=}"
VENV_PATH="${VENV_PATH:-${manifest_venv_path:-/home/dartfx/.venvs/dartfx}}"
packages=("${manifest_lines[@]:1}")

if (( ${#packages[@]} == 0 )); then
  echo "[python] No supplemental packages listed in ${MANIFEST_PATH}"
  exit 0
fi

mkdir -p "$(dirname "$VENV_PATH")"
uv venv "$VENV_PATH"
uv pip install --python "$VENV_PATH/bin/python" "${packages[@]}"
chown -R dartfx:dartfx "$(dirname "$VENV_PATH")"

echo "[python] Installed ${#packages[@]} supplemental packages into ${VENV_PATH}"
SCRIPT
