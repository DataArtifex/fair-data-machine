#!/usr/bin/env bash
# Builds a base+Ollama+R derived image; auto-builds base first if missing.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
source "$ROOT_DIR/scripts/build/lib.sh"

RELEASE_TAG="${RELEASE_TAG:-dev}"
REGISTRY_PREFIX="${REGISTRY_PREFIX:-}"
BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-kulnor/fair-data-machine}"
OUTPUT_IMAGE_NAME="${TOOLCHAIN_IMAGE_NAME:-kulnor/fair-data-machine-ollama-r}"
RUN_POST_BUILD_TESTS="${RUN_POST_BUILD_TESTS:-true}"

BASE_IMAGE="$(qualify_image "$BASE_IMAGE_NAME" "$RELEASE_TAG" "$REGISTRY_PREFIX")"
OUTPUT_IMAGE="$(qualify_image "$OUTPUT_IMAGE_NAME" "$RELEASE_TAG" "$REGISTRY_PREFIX")"

ensure_base_image "$ROOT_DIR" "$BASE_IMAGE" "$RELEASE_TAG" "$REGISTRY_PREFIX" "$BASE_IMAGE_NAME" "$RUN_POST_BUILD_TESTS"

echo "[build:ollama-r] Building derived image: $OUTPUT_IMAGE from $BASE_IMAGE"
build_composed_image "$ROOT_DIR" "$OUTPUT_IMAGE" "$BASE_IMAGE" ollama r

run_post_build_smoke_if_enabled "$ROOT_DIR" "$OUTPUT_IMAGE" "$RUN_POST_BUILD_TESTS" "build:ollama-r"

echo "[build:ollama-r] Done"
echo "[build:ollama-r] TOOLCHAIN_IMAGE=$OUTPUT_IMAGE"
