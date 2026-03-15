#!/usr/bin/env bash
# Thin wrapper kept for Makefile and CI backward compatibility.
# Delegates all build work to scripts/build/base.sh, which assembles the
# base image from per-component Dockerfiles via scripts/build/lib.sh.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$ROOT_DIR/scripts/build/base.sh"