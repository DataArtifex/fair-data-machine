#!/usr/bin/env bash
# Builds the default base image by composing per-component Dockerfiles.
# QLever is part of the base component chain; add-ons are separate scripts.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
source "$ROOT_DIR/scripts/build/lib.sh"

RELEASE_TAG="${RELEASE_TAG:-dev}"
REGISTRY_PREFIX="${REGISTRY_PREFIX:-}"
TOOLCHAIN_IMAGE_NAME="${TOOLCHAIN_IMAGE_NAME:-kulnor/fair-data-machine}"
RUN_POST_BUILD_TESTS="${RUN_POST_BUILD_TESTS:-true}"

build_base_via_pipeline "$ROOT_DIR" "$RELEASE_TAG" "$REGISTRY_PREFIX" "$TOOLCHAIN_IMAGE_NAME" "$RUN_POST_BUILD_TESTS"
